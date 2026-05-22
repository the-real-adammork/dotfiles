---
name: linear-implementation-supervisor
description: Use when all Linear-synced implementation plans should be executed in slice order from SQLite state, with the supervisor directly owning the active plan task loop and dispatching task workers, task reviewers, fix workers, and merge workers as native sub-agents.
---

# Linear Implementation Supervisor

Top-level workflow for implementing a set of Linear-synced implementation plans. The supervisor owns plan order, the active plan task loop, Linear status transitions, worker/reviewer dispatch, human-review waits, commits, plan branch merges, cross-plan consistency, SQLite state, and overall handoff.

## Start

Announce: "I'm using the linear-implementation-supervisor skill to supervise implementation across plans."

Inputs:

- slices document path;
- state DB path, default `.codex/workflows/state.sqlite`;
- `.codex/linear.toml` config;
- optional technical design and requirements paths.

If the slices document or state DB is missing, ask for it. If only legacy Markdown run logs or sync ledgers exist, require `$linear-implementation-state-migration` before resuming. If Linear mappings are missing from SQLite, run or request `$linear-implementation-sync` first.

## Config

Expected non-secret `.codex/linear.toml` fields include:

```toml
state_backend = "sqlite"
state_db = ".codex/workflows/state.sqlite"
legacy_state_mode = "archived"

team_key = "ENG"
admin_user_email = "adam@example.com"
project_naming_prefix = "My Feature"
default_labels = ["codex", "implementation-plan"]
create_missing_labels = true

handoff_dir = "docs/handoffs"
run_log_dir = "docs/linear/runs"
smoke_test_dir = "docs/linear/smoke-tests"

status_todo = "Todo"
status_in_progress = "In Progress"
status_blocked = "Blocked"
status_agentic_review = "Agentic Review"
status_human_review = "In Review"
status_done = "Completed"

worktree_dir = ".worktrees"
branch_template = "codex/{feature}/{plan_slug}"
merge_completed_plan_branches = true
merge_target_branch = ""
merge_target_worktree = ""

poll_interval_minutes = 5
human_review_timeout_minutes = 60
human_review_mode = "event_driven" # event_driven | polling

assign_blocked_to_admin = true
assign_human_review_to_admin = true
block_on_existing_test_failures = true
context_handoff_threshold_percent = 70

worker_dispatch = "supervisor"
worker_model = ""
reviewer_model = ""
worker_reasoning_effort = "medium"
reviewer_reasoning_effort = "medium"
fix_worker_reasoning_effort = "medium"
merge_worker_reasoning_effort = "low"
```

Never store Linear credentials in this config.

## Durable SQLite State

The supervisor must maintain durable top-level state for every multi-plan run in SQLite so the workflow can be restarted after a Codex session crash with one prompt. SQLite tracks cross-plan sequencing, active agent names, worktree/branch pointers, Linear project pointers, and restart instructions.

The supervisor also owns detailed durable state for the active implementation plan. `$implementation-plan-orchestrator` is a legacy/optional mode only; the default workflow does not spawn a separate orchestrator agent.

Use the configured DB before starting the first plan:

```text
.codex/workflows/state.sqlite
```

If `state_db` is missing from config, default to `.codex/workflows/state.sqlite`. Create the parent directory if needed. If `state_backend` is not `sqlite`, stop and ask the user to migrate or update config.

The supervisor must update these SQLite records after every supervisor-owned transition:

- `workflow_runs`: current status, active plan/task/agent, restart action;
- `plans`: plan status, worktree, branch, Linear project, last commit;
- `tasks`: supervisor-level task status summaries where relevant;
- `agents`: stable agent name to host agent id/nickname mapping;
- `events`: append-only event log;
- `human_reviews`: waiting, timeout, and approval state.

Optional Markdown snapshots may be exported for human reading under `run_log_dir`, but they are generated artifacts. Do not patch Markdown run logs as canonical state.

Generated supervisor snapshots should contain:

```markdown
# Linear Implementation Run: <feature>

## Restart Command

Use $linear-implementation-supervisor to resume the Linear implementation run from `<this file>`.

## Inputs

- slices_document: `<path>`
- state_db: `<path>`
- config: `.codex/linear.toml`
- technical_design: `<path or none>`
- requirements: `<path or none>`

## Current State

- status: running | blocked | waiting_on_human_review | context_handoff | complete
- active_plan: `<path or none>`
- active_task: `<task id/title or none>`
- active_linear_issue: `<issue id/url or none>`
- active_agent_name: `<stable agent name or none>`
- active_host_agent: `<host-generated agent id or nickname or none>`
- active_worktree: `<path or none>`
- active_branch: `<branch or none>`
- active_plan_id: `<SQLite plan id or none>`
- pending_dispatch: `<kind or none>`
- waiting_since: `<ISO timestamp or none>`
- next_poll_at: `<ISO timestamp or none>`
- last_commit: `<sha or none>`
- last_event_at: `<ISO timestamp>`
- restart_action: `<exact next action for a replacement supervisor>`

## Plan Status

| Order | Plan | Linear Project | Worktree | Branch | Status | Last Commit | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Agent Directory

| Stable Agent Name | Host Agent ID/Nickname | Role | Plan | Task/Issue | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- |

## Task Status Summary

| Plan | Task | Linear Issue | Status | Owner | Last Event | Notes |
| --- | --- | --- | --- | --- | --- | --- |

This table is a generated summary only. SQLite plan/task/event records are the source of truth for task-level event history, worker/reviewer loops, review findings, and human-review wait or polling detail.

## Pending Human Inputs

| Issue | Need | Assigned To | Since | Timeout At | Notes |
| --- | --- | --- | --- | --- | --- |

## Event Log

- `<ISO timestamp>` - <event>
```

Append an `events` row and update the relevant current-state rows after every supervisor-owned workflow transition:

- run start or resume;
- plan started, completed, deferred, or blocked;
- worktree or branch created;
- legacy orchestrator normalized, retired, dispatched, resumed, replaced, or returned when using legacy mode, including the stable agent name and host agent id/nickname;
- worker/reviewer/fix-worker/merge-worker dispatch requested, started, returned, or failed, including the stable agent name, host agent id/nickname, and relevant plan id;
- Linear project or issue status/assignee/comment changes;
- task moved to `status_human_review`, including the smoke-test file path and Linear human-review comment link;
- every human-review state transition, including `next_poll_at` only when polling mode is enabled;
- human feedback detected;
- implementation commit, docs commit, plan merge commit, or consistency commit;
- handoff written;
- workflow completion.

Do not wait until the end of a plan to update SQLite. The DB must always be current enough that a replacement supervisor can resume without chat history and continue the active plan task loop.

When legacy SQLite state shows an active orchestrator agent, normalize it before continuing in the supervisor-owned task loop. Do not spawn a new orchestrator unless the user explicitly opts into legacy orchestrator mode.

## Resume

If the user asks to resume an implementation run, read the configured SQLite state DB and locate the active `workflow_runs` row. If no run id is provided, choose the newest non-complete run for the current repo/feature and confirm the selected run.

```text
.codex/workflows/state.sqlite
```

Then:

1. Read the run row, plan rows, task rows, active agent rows, pending human reviews, and recent events.
2. Verify the active worktree, branch, and last commit with `/usr/bin/git`.
3. Verify the active Linear issue status before taking action.
4. Run State Normalization if any active agent or restart action references a legacy orchestrator.
5. Continue from `restart_action` unless live git or Linear state proves it stale.
6. Append a resume event before dispatching any new work.

Never start the workflow from scratch when SQLite shows an in-progress run. If only legacy Markdown state exists, run `$linear-implementation-state-migration` first.

## State Normalization

When resuming a DB that was created before the two-layer workflow, normalize legacy orchestrator state in place before continuing.

If any active `agents` row has role/name matching `orchestrator:*`, or `workflow_runs.restart_action` says to resume an orchestrator:

1. Read `workflow_runs.active_plan_id`, `workflow_runs.active_task_id`, active `plans`, active `tasks`, pending `agents`, and pending `human_reviews`.
2. Verify Linear status for the active task issue and git status for the active worktree/branch.
3. Mark active orchestrator agents as `legacy_retired` or `superseded_by_supervisor_task_loop`.
4. Preserve active worker/reviewer/fix-worker agents if they are still running; the supervisor remains their attachment and resume owner.
5. Rewrite `workflow_runs.restart_action` to the equivalent supervisor-owned action, such as:
   - continue active task after returned worker result;
   - dispatch task reviewer;
   - request fix worker;
   - commit reviewed task changes;
   - wait for human review;
   - process `status_done` human approval;
   - merge completed plan branch.
6. Append an event: `normalized from legacy 3-layer orchestrator flow to 2-layer supervisor flow`.

Do not perform a separate DB migration for this normalization. It is a resume-time compatibility step.

## Workflow

1. Read the slices document and determine implementation-plan execution order.
2. Read SQLite and verify every plan/task has Linear mappings.
3. Resolve the admin user from `admin_user_email`.
4. Create or resume the durable SQLite workflow run.
5. For each plan in order, create or resume its worktree/branch and run the supervisor-owned Active Plan Task Loop.
6. Stop only for a true blocker, event-driven human-review wait, timeout handoff, context handoff, or explicit user stop.
7. After a plan completes, merge the completed plan branch into the target worktree/branch using the supervisor-owned merge procedure.
8. Run `$implementation-plans-consistency` against upcoming plans after the plan branch is merged.
9. Commit cross-plan consistency docs separately.
10. Continue to the next plan only after the merge and consistency updates are complete.

Do not run later plans before earlier plan dependencies are complete unless the slices document explicitly says they are independent and the user approves parallelism.

## Active Plan Task Loop

The supervisor owns the task loop for the active implementation plan. Do not spawn an orchestrator by default.

For each task in the active plan:

1. Read the implementation-plan task section, plan-level human TODOs, SQLite task row, and Linear issue.
2. If a required human dependency is missing, assign the issue to the configured admin user, set status to `Blocked`, comment with the exact need, update SQLite, and continue only if dependencies allow another unblocked task.
3. Create or verify the plan worktree and branch.
4. Set the Linear issue to `status_in_progress` and update SQLite.
5. Dispatch one `task-worker` sub-agent for this task only.
6. When the worker returns, record changed files, verification, stdout-rich evidence, and task-satisfaction notes in SQLite or local artifacts. Keep any Linear worker comment compact.
7. Set the Linear issue to `status_agentic_review`.
8. Dispatch one `task-reviewer` sub-agent using `$task-implementation-review`.
9. For High/Medium findings, dispatch one `fix-worker`, then rerun review. Repeat until blocking findings are fixed or the task is blocked.
10. Commit implementation changes for the task from the supervisor after review passes.
11. Write the repo smoke-test file under `smoke_test_dir`, then post a compact Linear human-review request comment pointing to that file.
12. Set the Linear issue to `status_human_review`, assign it to the admin user, update SQLite, and enter Human Review Wait.
13. If Linear status becomes `status_done`, update the implementation plan with actual-vs-planned notes, commit docs separately, run `$implementation-plan-task-consistency`, commit consistency docs separately, update SQLite, and continue.

Worker and reviewer agents never commit, merge, advance Linear state, or update SQLite directly unless the supervisor explicitly delegates a narrow status/comment update. They return evidence to the supervisor.

## Smoke Test Files

Before moving any Linear issue to `status_human_review`, the supervisor must write concrete smoke-test instructions to a repo file. Default path:

```text
docs/linear/smoke-tests/<plan-slug>/<issue-id>-<task-slug>.md
```

If `.codex/linear.toml` sets `smoke_test_dir`, use that directory instead.

The smoke-test file must include:

- task summary and exact branch/worktree/commit under review;
- implementation-plan path, task anchor, state DB path, run id, and plan id;
- prerequisites, including required services, environment variables, credentials, seed data, browser/device, or accounts;
- exact copy-pasteable shell commands in fenced `bash` blocks for all relevant automated checks;
- expected successful output or observable behavior for each command;
- manual smoke-test checklist for behavior that cannot be fully verified by commands;
- cleanup/reset commands when the smoke test creates data, starts services, or changes local state;
- known limitations or tests that cannot be run by the agent, with the reason.

After writing the file, post only a compact Linear comment:

```markdown
Ready for human smoke testing.

Smoke test instructions: `<smoke-test-file-path>`
Branch: `<branch>`
Commit: `<sha>`

When it passes, move this issue to `<status_done>`.
```

Do not put full smoke-test commands, expected output, or manual checklist in Linear.

## Plan Branch Merge

The supervisor owns merging completed implementation-plan branches, but delegates the mechanical merge to a dedicated native sub-agent. Task workers, reviewers, and fix workers must not merge plan branches.

After each plan completes:

1. Verify SQLite marks the plan `complete` and records the plan worktree path, branch name, commit list, `state_db`, `run_id`, and `plan_id`.
2. Verify the plan worktree is clean with `/usr/bin/git -C <plan worktree> status --short`.
3. Resolve the merge target:
   - use `merge_target_worktree` when configured;
   - otherwise use the original source or main worktree for the run;
   - use `merge_target_branch` when configured;
   - otherwise use the source branch recorded for the run.
4. Dispatch one `merge-worker` sub-agent with `agent_name` in the format `merge-worker: <plan-slug> -> <target branch>`.
5. Record the stable name and returned host agent id/nickname in `Agent Directory`.
6. Wait for the merge-worker result before running consistency updates or starting the next plan.
7. If the merge succeeds, record the merge commit SHA in SQLite and update the plan row before running cross-plan consistency.
8. If the merge conflicts or the target worktree is dirty, stop before starting the next plan. Update SQLite with `status: blocked`, the conflicting files or dirty paths, and a `restart_action` that resumes merge resolution. Do not ask task workers to perform the merge or conflict resolution unless the user explicitly delegates that work.

Use this merge-worker prompt shape:

```text
agent_name: merge-worker: <plan-slug> -> <target branch>

You are not alone in the codebase. Do not revert unrelated changes.

Merge one completed implementation-plan branch into the target worktree/branch.

Plan:
<implementation-plan path>

Plan worktree:
<plan worktree path>

Plan branch:
<plan branch>

Target worktree:
<target worktree path>

Target branch:
<target branch>

Required checks:
1. Verify the plan worktree is clean.
2. Verify the target worktree exists, is on the target branch, and is clean.
3. Merge the completed plan branch into the target worktree with `/usr/bin/git`, preserving the plan branch commits. Prefer a normal merge commit when the repository allows it; do not squash unless explicitly instructed.
4. If the merge conflicts, stop immediately after recording conflicted files. Do not resolve conflicts unless explicitly instructed.

Return only: merge status, merge commit SHA if successful, target worktree status, conflicted files or dirty paths if blocked, commands run, and blockers. Do not continue into consistency updates. Do not push.
```

When `merge_completed_plan_branches = false`, skip the merge step only if the user or repo config explicitly disables it, and record that skipped merge in SQLite and final output.

## Delegation Model

Codex's native multi-agent dispatch is a capability of the active host session. The supervisor is the dispatcher and sequencing owner for all task workers, fix workers, task reviewers, merge workers, and replacement supervisors.

The default pattern is:

1. Supervisor owns the active plan task loop directly.
2. Supervisor decides when worker or reviewer help is needed.
3. Supervisor spawns the requested native sub-agent in the plan worktree, putting `agent_name` at the top of the prompt.
4. Supervisor waits for the result, records it in SQLite, closes or retires the child agent when the host supports it, and continues the task loop.
5. Supervisor updates Linear, commits, handles human review according to `human_review_mode`, updates docs, and continues sequencing.

Use `codex exec` child runs only when `worker_dispatch = "codex_cli"` is explicitly configured or the user explicitly asks for autonomous CLI child agents. Treat CLI child runs as a workaround/advanced mode, not the default.

Use this prompt/return contract for worker and reviewer dispatch:

```markdown
Dispatch:
- kind: task-worker | fix-worker | task-reviewer | merge-worker
- agent_name: <role>: <plan-slug> / <task id> - <short task title>
- plan: <implementation-plan path>
- task: <task number and title>
- worktree: <path>
- branch: <branch>
- linear_issue: <issue id or url>
- state_db: <SQLite state DB path>
- run_id: <workflow run id>
- plan_id: <SQLite plan id>
- prompt: <bounded instructions for the requested agent>
- expected_return: <files changed, review path, findings, verification, blocker, or handoff>
```

The supervisor must preserve `agent_name` in SQLite and any handoff. The native host may return its own agent id or nickname instead of displaying the requested `agent_name`. Immediately after every spawn, record an `agents` row that maps `agent_name` to the returned host agent id/nickname, and tell the user that mapping if they may need to attach follow-up input. The host agent id/nickname is the attachment target; `agent_name` is the stable human label.

Use this naming pattern:

```text
task-worker: <plan-slug> / <linear issue> - <short task title>
task-reviewer: <plan-slug> / <linear issue> - <short task title>
fix-worker: <plan-slug> / <linear issue> - <short task title>
merge-worker: <plan-slug> -> <target branch>
replacement-supervisor: <feature-slug> / resume
```

Worker and reviewer results go back to the supervisor. The supervisor is the only default owner of task advancement, Linear transitions, commits, human-review wait state, and SQLite state.

If CLI child dispatch is explicitly enabled, require child runs to write bounded result files in the plan worktree and return only result paths plus status to the supervisor. The supervisor should record that CLI mode was used in the final handoff.

## Speed Defaults

Prefer bounded, resumable work over long-lived idle agents.

- Use medium reasoning for the supervisor's active plan loop, task workers, fix workers, and reviewers by default. Use high reasoning only for broad refactors, hard production-debugging tasks, or replacement agents recovering ambiguous state.
- Use low reasoning for merge workers because their job is mechanical branch verification and merge reporting.
- Do not spawn separate commit-message agents inside this workflow. The supervisor should inspect the staged diff and write the commit message inline.
- Do not spawn a state-update sub-agent for routine per-event SQLite updates. The supervisor already has the current state and should update its own SQLite rows inline.
- After any task worker, fix worker, reviewer, merge worker, or commit helper returns, record its result in SQLite and close or retire the host agent when available. Do not keep completed child agents open as implicit memory.
- Keep spawned prompts bounded to file paths, exact task anchors, ownership boundaries, and return contracts. Do not paste full plans, run logs, or reviews into child prompts unless the child cannot read the files directly.
- Reuse verification evidence across worker, fix-worker, and reviewer loops. Reviewers should not rerun a slow full-suite command when the same command already passed for the same uncommitted diff and targeted inspection is enough.
- Keep worker, fix-worker, reviewer, and human-review Linear comments compact. Detailed findings, fix notes, smoke-test commands, verification output, and command logs belong in SQLite events or repo artifacts such as local review artifacts and smoke-test files. Linear should get status pointers, blocking counts, and local file paths.

## Human Review Wait

The default human-review mode is event-driven. When the supervisor has moved a task to `status_human_review`, it records the waiting state, tells the user the exact Linear issue and smoke-test file, and stops active waiting until the user resumes or sends `human review approved <issue id>`.

Only use active polling when `.codex/linear.toml` explicitly sets `human_review_mode = "polling"`. In polling mode, treat normal human-review polling as active supervisor work until `human_review_timeout_minutes` elapses.

Before accepting `status_human_review` as a valid waiting state, the supervisor must verify that it created a repo smoke-test file and posted a compact human-review request comment on the Linear issue that links to it:

- exact branch, worktree, and commit under review;
- smoke-test file path under `smoke_test_dir`;
- enough status text to tell the user to open the file and mark the issue `status_done` when it passes.

If the issue is in `status_human_review` but the smoke-test file is missing or the Linear comment does not point to it, treat it as a workflow error. Create the smoke-test file and post the compact pointer comment before continuing.

Human approval is communicated by moving the Linear issue to `status_done`. A separate approval comment is not required.

The user may also notify the supervisor directly in chat:

```text
human review approved <issue id>
```

When this happens, the supervisor must:

1. Verify the issue id matches the active task or a task currently in `status_human_review`.
2. Fetch the Linear issue and confirm its status is `status_done`.
3. Read the active plan/task state from SQLite.
4. Continue the supervisor-owned task-completion workflow immediately.
5. Update SQLite with the direct human-approval signal and the verified Linear status.

If the direct signal is received but Linear is not `status_done`, tell the user the issue is not marked done yet and keep the task in its current human-review wait. In polling mode, continue the polling loop.

When resuming from an event-driven wait and Linear already shows `status_done`, continue the task-completion workflow immediately. Do not wait for a polling interval.

The supervisor should stop active work only for:

- full plan completion;
- true blocker, such as missing credentials, unavailable external dependency, or existing unrelated failing tests;
- event-driven human-review wait or human-review timeout after the full configured `human_review_timeout_minutes`;
- context handoff;
- explicit user stop.

In the default `event_driven` mode, the human-review wait is the expected resume point.

## Handoff

If the supervisor cannot continue, write:

```text
docs/handoffs/YYYY-MM-DD-<feature>-linear-supervisor-handoff.md
```

Include completed plans, active plan, worktree paths, branches, Linear project/issue state, commits, blocked tasks, pending human reviews, and exact restart instructions.

Also update SQLite first, set `status` and `restart_action`, append an event with the handoff path, and link the handoff from the run row. The handoff is a detailed snapshot; SQLite remains the entry point for restart.

## Final Output

Report:

```markdown
Linear implementation supervision complete.

Completed plans:
- `<plan>` - <branch> - <commits> - merged: <merge sha or "not merged">

Updated upcoming plans:
- `<plan>` - <summary or "none">

Blocked or waiting:
- <issue/task or "None">

Handoffs:
- <path or "None">
```
