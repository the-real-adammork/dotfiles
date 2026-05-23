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
human_review_dir = "docs/linear/reviews"

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
remote_name = "origin"
pr_provider = "gitlab"
pr_create_command = ""
pr_link_required_for_human_review = true

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
- task branch pushed, pull/merge request created or updated, and PR/MR URL;
- task moved to `status_human_review`, including the human-review packet path, PR/MR URL, and Linear human-review comment link;
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
2. Identify required real dependencies for the task: credentials, accounts, services, databases, queues, external APIs, seed data, devices, browser access, paid services, and real network/data paths.
3. Direct the worker to provision or start any dependency it can safely create locally or through available authenticated tooling, such as containers, local services, seeded databases, emulators, test tenants, or existing dev/staging resources.
4. If a required dependency cannot be provisioned by the agent because it needs credentials, account access, paid setup, policy approval, or product steering, assign the issue to the configured admin user, set status to `Blocked`, comment with the exact dependency and unblock instructions, update SQLite, and continue only if dependencies allow another unblocked task.
5. Create or verify the plan worktree and branch.
6. Set the Linear issue to `status_in_progress` and update SQLite.
7. Dispatch one `task-worker` sub-agent for this task only.
8. When the worker returns, record changed files, verification, stdout-rich evidence, dependency provisioning attempts, and task-satisfaction notes in SQLite or local artifacts. Keep any Linear worker comment compact.
9. Set the Linear issue to `status_agentic_review`.
10. Dispatch one `task-reviewer` sub-agent using `$task-implementation-review`.
11. For High/Medium findings, dispatch one `fix-worker`, then rerun review. Repeat until blocking findings are fixed or the task is blocked.
12. Commit implementation changes for the task from the supervisor after review passes.
13. Push the task branch and create or update a GitLab merge request or configured repository pull request.
14. Write the repo human-review packet under `human_review_dir`, then post a compact Linear human-review request comment pointing to the packet and PR/MR.
15. Set the Linear issue to `status_human_review`, assign it to the admin user, update SQLite, and enter Human Review Wait.
16. If Linear status becomes `status_done`, update the implementation plan with actual-vs-planned notes, commit docs separately, run `$implementation-plan-task-consistency`, commit consistency docs separately, update SQLite, and continue.

Worker and reviewer agents never commit, merge, advance Linear state, or update SQLite directly unless the supervisor explicitly delegates a narrow status/comment update. They return evidence to the supervisor.

## Automated Tests And Human Review Packets

Before moving any Linear issue to `status_human_review`, the supervisor must verify that the implementation includes automated tests appropriate to the task:

- unit tests for isolated logic, validation, transformations, and edge cases;
- integration tests for database, filesystem, service wiring, queues, CLIs, or internal API boundaries;
- end-to-end tests when the task changes a user-visible workflow, cross-service behavior, or real-data path.

The supervisor must not substitute manual smoke testing for missing automated tests. If a task truly cannot add automated coverage, the worker/reviewer must explain why, identify the closest executable check, and the reviewer must decide whether that gap is acceptable or blocking.

## Real Dependency Gate

Real dependencies required by the implementation plan, task wording, requirements, technical design, or production/dev behavior are mandatory for task verification. Do not downgrade them to optional smoke-test notes, optional review-packet commands, or "nice to have" follow-ups.

The agent team must try to satisfy required real dependencies before blocking:

- start local services, emulators, databases, queues, or test containers when available;
- run existing setup, seed, migration, or fixture-loading scripts;
- use already-authenticated CLIs or environment variables without printing secrets;
- create temporary test tenants, resources, topics, buckets, schemas, or records when the repo's tooling supports it;
- document cleanup for any created resources.

Block the task instead of moving it to human review when a required real dependency cannot be satisfied because:

- credentials, account access, private keys, paid services, allowlists, or approvals are missing;
- the correct service/environment is ambiguous and product or engineering steering is needed;
- provisioning would mutate production data or create cost/risk without explicit approval;
- the required real service is unavailable and no approved local/test substitute exists.

When blocking, assign the Linear issue to the configured admin user, set it to `status_blocked`, update SQLite, and leave one compact Linear comment with:

- the exact dependency or decision needed;
- what the agent already tried;
- the command or setup step the human should run, if known;
- where the workflow should resume after the dependency is available.

Mocks, fixtures, recordings, and fakes are allowed only for task requirements that explicitly call for isolated/unit coverage, hard-to-trigger error paths, or as an additional fast test beside mandatory real-service verification. They do not satisfy a task that requires real service, real network, real database, or real-data proof unless the implementation plan explicitly places that real proof in a later task and the current task does not claim completion of the real integration.

Workers and reviewers must explicitly disclose every test boundary mode:

- `real-service`, `local-service`, `test-container`, `real-network`, or `real-data`;
- `fixture`, `recording`, `mock`, or `fake`.

When fixtures, recordings, mocks, or fakes are used, the supervisor must record why they are acceptable now and point to the later implementation-plan task that converts the boundary to a real service/data path or adds a larger real end-to-end test. If no later task exists and real coverage is required, block the task or update upcoming plans through the consistency workflow before proceeding. Future conversion is not enough when the current task is the integration task; the current task must verify the real dependency or block.

After review passes and the supervisor commits the task, the supervisor must push the branch and create or update a remote pull/merge request:

1. Use `remote_name` from config, default `origin`.
2. Use `pr_provider`, default `gitlab`.
3. If `pr_create_command` is configured, run it from the plan worktree after substituting known branch/title/body values when needed.
4. Otherwise infer the repository host from `/usr/bin/git remote get-url <remote_name>` and use an available project CLI such as `glab` for GitLab when installed.
5. If no PR/MR can be created because authentication, remote access, or tooling is missing, set the Linear issue to `Blocked` when `pr_link_required_for_human_review = true`; otherwise write the blocker and exact manual create command in the review packet.

Before moving any Linear issue to `status_human_review`, the supervisor must write a human-review packet to a repo file. Default path:

```text
docs/linear/reviews/<plan-slug>/<issue-id>-<task-slug>.md
```

If `.codex/linear.toml` sets `human_review_dir`, use that directory instead. If only legacy `smoke_test_dir` is configured, use it as a compatibility fallback.

The human-review packet must include:

- task summary and exact branch/worktree/commit under review;
- PR/MR URL and Linear issue URL;
- implementation-plan path, task anchor, state DB path, run id, and plan id;
- automated tests added or updated, grouped as unit, integration, and end-to-end;
- exact verification commands the agent ran, with concise stdout-rich evidence and pass/fail/skipped status;
- required real dependencies, how they were provisioned or why the task was blocked before review;
- why those tests prove the task is complete, mapped back to the task requirements;
- fixture/mock/fake disclosure, including which tests use them, what real boundary they stand in for, and the future task or plan that replaces them with real service/data coverage;
- CI/PR checks expected to run on the PR/MR, if known;
- human review checklist focused on what to inspect in the PR: production code paths, test assertions, boundary-mode disclosures, missing real-service gaps, and whether the PR solves the real problem;
- known limitations, residual risk, or tests that cannot be run by the agent, with the reason.

The packet may include optional copy-pasteable commands for a human who wants to rerun checks locally, but local command execution is no longer the primary human-review mechanism. The primary review surface is the PR/MR plus the packet's test-proof explanation.

After writing the file, post only a compact Linear comment:

```markdown
Ready for human review.

PR/MR: <url>
Review packet: `<human-review-packet-path>`
Branch: `<branch>`
Commit: `<sha>`

When the PR and review packet look correct, move this issue to `<status_done>`.
```

Do not put full test evidence, command output, PR body, or manual checklist in Linear.

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
- Keep worker, fix-worker, reviewer, and human-review Linear comments compact. Detailed findings, fix notes, verification output, PR/MR review notes, command logs, and human-review checklists belong in SQLite events or repo artifacts such as local review artifacts and human-review packets. Linear should get status pointers, blocking counts, PR/MR URLs, and local file paths.

## Human Review Wait

The default human-review mode is event-driven. When the supervisor has moved a task to `status_human_review`, it records the waiting state, tells the user the exact Linear issue, PR/MR URL, and human-review packet, and stops active waiting until the user resumes or sends `human review approved <issue id>`.

Only use active polling when `.codex/linear.toml` explicitly sets `human_review_mode = "polling"`. In polling mode, treat normal human-review polling as active supervisor work until `human_review_timeout_minutes` elapses.

Before accepting `status_human_review` as a valid waiting state, the supervisor must verify that it created a repo human-review packet, created or updated the PR/MR when required, and posted a compact human-review request comment on the Linear issue that links to both:

- exact branch, worktree, and commit under review;
- PR/MR URL when `pr_link_required_for_human_review = true`;
- human-review packet path under `human_review_dir` or legacy `smoke_test_dir`;
- enough status text to tell the user to review the PR/MR and packet, then mark the issue `status_done` when approved.

If the issue is in `status_human_review` but the packet is missing, required PR/MR URL is missing, or the Linear comment does not point to both, treat it as a workflow error. Create the missing artifact/link and post the compact pointer comment before continuing.

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
