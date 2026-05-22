---
name: implementation-plan-orchestrator
description: Legacy/optional mode for executing one implementation-plan document in its own git worktree and Linear project through a separate plan orchestrator agent. Do not use by default; the linear-implementation-supervisor normally owns the active plan task loop directly.
---

# Implementation Plan Orchestrator

Legacy/optional mode for executing one implementation-plan document in a dedicated worktree and branch through a separate plan orchestrator agent.

Default workflow note: `$linear-implementation-supervisor` now owns the active plan task loop directly. Use this skill only when the user explicitly requests a separate orchestrator agent, or when recovering an older run that intentionally remains in legacy three-layer mode.

## Start

Announce: "I'm using the legacy implementation-plan-orchestrator skill to execute one implementation plan."

Inputs:

- implementation-plan path;
- state DB path, default `.codex/workflows/state.sqlite`;
- Linear project or issue mappings from SQLite;
- `.codex/linear.toml` config;
- feature slug and plan slug;
- source branch or main worktree path.

If required config is missing, ask before creating a worktree. If only a legacy sync ledger or plan progress log is available, require `$linear-implementation-state-migration` before resuming.

## Worktree

Create one worktree per plan:

```text
.worktrees/<plan-slug>
```

Branch:

```text
codex/<feature>/<plan-slug>
```

Use `/usr/bin/git`. Never overwrite unrelated user changes. The orchestrator commits after agentic task review passes; worker agents do not commit.

## Plan SQLite State

The orchestrator owns durable state for its implementation plan in SQLite. It must update the configured state DB so a replacement orchestrator can resume after a session crash:

```text
.codex/workflows/state.sqlite
```

If `state_db` is missing from config, default to `.codex/workflows/state.sqlite`. If `state_backend` is not `sqlite`, stop and ask the user to migrate or update config.

The supervisor owns only top-level multi-plan sequencing state. Do not rely on the supervisor to write task-level plan state. Before returning any dispatch request, blocker, handoff, human-review timeout, or completion result to the supervisor, update SQLite and include `state_db`, `run_id`, and `plan_id` in the return.

The orchestrator updates these SQLite records:

- `plans`: plan status, worktree, branch, active task, last commit, restart action;
- `tasks`: task status, Linear issue, active worker/reviewer, last commit, source hash;
- `agents`: requested worker/reviewer stable names and returned host ids;
- `human_reviews`: issue, smoke-test file, waiting state, timeout, approval;
- `events`: append-only task events, Linear changes, dispatch requests/results, verification evidence, commits, handoffs;
- `artifacts`: smoke-test files, review artifacts, handoffs, optional generated Markdown snapshots.

Optional Markdown run-log snapshots may be exported under `run_log_dir`, but they are generated artifacts. Do not patch Markdown progress logs as canonical state.

Append an `events` row and update relevant current-state rows after every durable workflow transition:

- orchestrator start or resume;
- worktree or branch verification;
- task started, blocked, completed, deferred, or resumed;
- Linear issue status, assignee, or comment change;
- worker/reviewer dispatch request;
- worker/reviewer result received;
- verification evidence recorded or reused;
- review findings and fix loop decisions;
- smoke-test file written;
- task moved to `status_human_review`;
- human-review wait, poll, approval, or feedback, including `next_poll_at` only when polling mode is enabled;
- human feedback detected;
- implementation commit, docs commit, or consistency commit;
- handoff written;
- plan completion.

Do not rely on chat history as the source of truth. Before returning a dispatch request or any other result to the supervisor, update SQLite so the request or result can be replayed after a crash.

## Worker Dispatch

Do not assume this orchestrator can recursively call native `spawn_agent`. When running as a sub-agent, request task workers, fix workers, reviewers, and replacement orchestrators from the supervisor by returning a structured dispatch request.

Use supervisor-mediated dispatch by default. It keeps worker lifecycle, cancellation, visibility, and result handoff inside the active Codex host session.

When a worker or reviewer is needed, return this request and stop normal execution until the supervisor resumes you with the result:

```markdown
Dispatch request:
- kind: task-worker | fix-worker | task-reviewer | replacement-orchestrator
- agent_name: `<role>: <plan-slug> / <task id> - <short task title>`
- plan: <implementation-plan path>
- task: <task number and title>
- worktree: <path>
- branch: <branch>
- linear_issue: <issue id or url>
- state_db: <SQLite state DB path>
- run_id: <workflow run id>
- plan_id: <SQLite plan id>
- dispatch_mode: supervisor
- prompt: <bounded instructions for the requested agent>
- expected_return: <files changed, review path, findings, verification, blocker, or handoff>
```

The worker/reviewer prompt must include:

- the implementation-plan path and exact task section;
- Linear issue id or URL;
- the stable agent name from `agent_name`, placed at the top of the prompt;
- expected files or ownership boundary;
- required verification and test-mode disclosure;
- instruction not to commit, merge, reset, clean, push, or revert unrelated changes;
- return contract.

Task-worker and fix-worker prompts must explicitly start with `Use $implementation-task-worker to implement this assigned task.` Reviewers still use `$task-implementation-review`.

Use stable, human-readable agent names that map directly to the work being performed:

```text
orchestrator: <plan-slug> / <plan id>
task-worker: <plan-slug> / <linear issue> - <short task title>
task-reviewer: <plan-slug> / <linear issue> - <short task title>
fix-worker: <plan-slug> / <linear issue> - <short task title>
replacement-orchestrator: <plan-slug> / resume
```

Keep names short enough to scan in supervisor state, but specific enough that a user can identify the correct sub-agent from the supervisor's agent directory. The supervisor is responsible for mapping this stable name to the host-generated agent id or nickname that the user attaches input to. After the supervisor resumes the orchestrator with a worker/reviewer result, update the `agents` row with any returned host agent id/nickname if it is available.

Task and fix workers use `$implementation-task-worker` and return changed files, verification, stdout-rich test evidence, smoke-test commands for human review, blockers, and how the change satisfies the task. Reviewers use `$task-implementation-review` and return findings by severity, verification run, and whether High/Medium findings remain.

After the supervisor returns the worker or reviewer result, continue from the same task state. The orchestrator remains responsible for deciding whether to request fixes, commit, move to human review, update docs, or advance to the next task.

Every dispatch request must include a `restart_action` in SQLite that explains whether a replacement supervisor should re-dispatch the same worker/reviewer or wait for an already-returned result.

Keep Linear issue comments small. SQLite plus local artifacts are the source of truth for worker results, reviewer findings, fix loops, verification evidence, and command output. Worker, fix-worker, and reviewer Linear comments should be short status pointers only:

- no full diffs, logs, command output, or long findings;
- include status, blocking count, commit or branch when available, and the local review-artifact path or state DB run id;
- put detailed findings and verification excerpts in SQLite events or local artifacts.

For speed, keep dispatch prompts bounded and evidence-based:

- pass file paths, exact task anchors, ownership boundaries, and required return fields instead of pasting full implementation plans or logs;
- include prior verification commands and key output from SQLite events or artifacts so reviewers can reuse credible evidence;
- ask reviewers to rerun only targeted checks unless the worker evidence is missing, stale, suspicious, or the task touched shared behavior;
- do not spawn a separate commit-message agent. Inspect the staged diff and write task/docs commit messages inline.

### CLI Child Dispatch

Use `codex exec` child runs only when `.codex/linear.toml` explicitly sets `worker_dispatch = "codex_cli"` or the user explicitly opts into autonomous CLI child agents. Treat this as an advanced fallback/workaround, not the preferred flow.

Before the first child run, verify:

- `codex` is on `PATH`;
- auth and config are available to the child process;
- the worktree path exists;
- the result directory exists, usually `docs/agent-runs/<plan-slug>/`.

Use this command shape, adding `-m <model>` only when the config explicitly provides `worker_model` or `reviewer_model`:

```bash
codex exec \
  -C "<worktree>" \
  -s danger-full-access \
  -a never \
  -o "<absolute-result-file>" \
  "<bounded worker or reviewer prompt>"
```

Child prompts must include:

- `Use $implementation-task-worker to implement this assigned task.` for task and fix workers;
- the implementation-plan path and exact task section;
- Linear issue id or URL;
- expected files or ownership boundary;
- required verification and test-mode disclosure;
- instruction not to commit, merge, reset, clean, push, or revert unrelated changes;
- result-file contract.

If `codex exec` is unavailable, unauthenticated, blocked, or repeatedly fails, return to supervisor-mediated dispatch.

## Task Loop

Run tasks sequentially in the implementation plan.

Before each task:

1. Read the task, plan-level human TODOs, SQLite task row, and Linear issue.
2. If a required human dependency is missing, assign the issue to the configured admin user, set status to `Blocked`, comment with the exact need, update SQLite, and move to the next unblocked task only if dependencies allow it.
3. Set status to `In Progress`.
4. Request a task worker from the supervisor for this task only, in the plan worktree, with an `agent_name` in the format `task-worker: <plan-slug> / <linear issue> - <short task title>`. The worker is not alone in the codebase and must not revert unrelated changes.

After the worker returns:

1. Set status to `Agentic Review`.
2. Record the worker result, changed files, verification, and task-satisfaction notes in SQLite. If a Linear worker comment is useful, keep it to one short status pointer with the state DB run id or local artifact path.
3. Request a task reviewer from the supervisor using `$task-implementation-review`, with an `agent_name` in the format `task-reviewer: <plan-slug> / <linear issue> - <short task title>`.
4. For High/Medium findings, request a fix worker from the supervisor with an `agent_name` in the format `fix-worker: <plan-slug> / <linear issue> - <short task title>`, then rerun review.
5. Repeat until blocking findings are fixed or the task is blocked.
6. Commit implementation changes for the task.
7. Write a smoke-test file using the Smoke Test Instructions below, then post a compact human-review request comment that points to that file.
8. Set status to `status_human_review` and assign to admin for human smoke testing.
9. Enter the Human Review Wait.
10. If status becomes `status_done`, update the implementation plan with actual-vs-planned notes, commit docs separately, run `$implementation-plan-task-consistency`, and commit consistency docs separately.
11. Continue to the next task.

## Smoke Test Instructions

Before moving any Linear issue to `status_human_review`, the orchestrator must write concrete smoke-test instructions to a repo file. The file must be specific enough that the configured admin user can open it from a terminal/editor, copy and paste commands into a shell, and know what result to expect.

Default path:

```text
docs/linear/smoke-tests/<plan-slug>/<issue-id>-<task-slug>.md
```

If `.codex/linear.toml` sets `smoke_test_dir`, use that directory instead of `docs/linear/smoke-tests`.

The smoke-test file must include:

- task summary and exact branch/worktree/commit under review;
- implementation-plan path, task anchor, state DB path, run id, and plan id;
- prerequisites, including required services, environment variables, credentials, seed data, browser/device, or accounts;
- exact copy-pasteable shell commands in fenced `bash` blocks for all relevant automated checks;
- expected successful output or observable behavior for each command;
- manual smoke-test checklist for behavior that cannot be fully verified by commands;
- cleanup/reset commands when the smoke test creates data, starts services, or changes local state;
- known limitations or tests that cannot be run by the agent, with the reason.

Prefer existing repo commands such as package scripts, test runners, build commands, migrations, CLI invocations, or local server commands. If the verification requires a long command sequence, either:

- add a small task-specific smoke-test script to the plan branch when it is useful beyond this review, commit it with the task or docs, and include the command to run it; or
- include a copy-pasteable shell block in the smoke-test file when a checked-in script would be unnecessary clutter.

Use this smoke-test file shape:

````markdown
# Smoke Test: <issue id> - <task title>

Plan: `<implementation-plan path>`
Task: `<task anchor or heading>`
State DB: `<state-db path>`
Run ID: `<run-id>`
Plan ID: `<plan-id>`
Branch: `<branch>`
Worktree: `<worktree>`
Commit: `<sha>`

## What Changed

<short implementation summary>

## Prerequisites

- <service/env/account/data requirement or "None">

## Automated Checks

```bash
<copy-pasteable command>
```

## Expected Output

- <what success looks like>

## Manual Checks

- [ ] <observable behavior to verify>
- [ ] <edge case or regression to verify>

## Cleanup

```bash
<cleanup command or "# None">
```

## If Something Fails

Comment on the Linear issue with the failing command/output and leave the issue in review.

## If This Passes

1. Move this Linear issue to `<status_done>`.
2. If the supervisor is active in chat and you want it to resume immediately, tell it:
```text
human review approved <issue id>
```
````

After writing the file, post only a compact Linear comment:

```markdown
Ready for human smoke testing.

Smoke test instructions: `<smoke-test-file-path>`
Branch: `<branch>`
Commit: `<sha>`

When it passes, move this issue to `<status_done>`.
```

Do not put the full smoke-test commands, expected output, or manual checklist in Linear. Do not move an issue to `status_human_review` unless the smoke-test file has at least one runnable command block, except when local verification is impossible; when impossible, explain the blocker in the smoke-test file and provide the closest available command, log query, or inspection step.

## Human Review Wait

After moving a task to `status_human_review`, the orchestrator must check Linear once immediately, then follow the configured human-review mode.

In default `event_driven` mode, if the immediate check finds no terminal condition, the orchestrator writes a waiting state to SQLite and returns to the supervisor with:

```markdown
Orchestrator return:
- status: waiting_on_human_review
- plan: <implementation-plan path>
- active_task: <task id/title>
- linear_issue: <issue id/url>
- branch: <branch>
- worktree: <worktree>
- state_db: <SQLite state DB path>
- run_id: <workflow run id>
- plan_id: <SQLite plan id>
- waiting_since: <ISO timestamp>
- restart_action: "When Linear issue <issue id> is status_done, resume this orchestrator with `human review approved <issue id>`."
```

The supervisor is responsible for waiting for the user to mark the Linear issue done or for a direct `human review approved <issue id>` message. The orchestrator must not keep an idle agent alive solely to poll Linear in default mode.

When `.codex/linear.toml` explicitly sets `human_review_mode = "polling"`, the orchestrator may keep polling Linear every configured `poll_interval_minutes` until one of these terminal conditions occurs:

- issue status becomes `status_done`;
- a direct supervisor resume signal says `human review approved <issue id>` and Linear confirms the issue is `status_done`;
- a new human feedback comment appears after the human-review request comment while the issue is not `status_done`;
- configured `human_review_timeout_minutes` elapses;
- a true blocker appears, such as missing credentials, external dependency failure, or context handoff threshold;
- the user explicitly stops the workflow.

In polling mode, the orchestrator must not return to the supervisor merely because the issue remains in `status_human_review` after one poll. Normal human-review waiting is part of the orchestrator's active task loop only when polling mode is explicitly enabled.

When a poll finds no terminal condition:

1. Keep the task in `status_human_review`.
2. Leave the issue assigned to the configured admin user.
3. Update SQLite with the poll result, `waiting_since`, and `next_poll_at`.
4. Wait for the next `poll_interval_minutes` interval.
5. Continue until the full timeout or another terminal condition occurs.

If status becomes `status_done`, verify the completed issue and commit match the task under review, then continue the task-completion workflow and advance to the next task.

If human feedback appears, request a fix worker from the supervisor, rerun agentic review, commit fixes after review passes, return the task to `status_human_review`, and restart the polling window for that review round.

If the supervisor resumes the orchestrator with an explicit `human review approved <issue id>` signal, immediately verify the Linear issue status is `status_done` and continue from the task-completion workflow when valid. Do not wait for the next polling interval.

Only in polling mode, after `human_review_timeout_minutes` elapses, should the orchestrator write a handoff for "waiting on human review." Leave the issue in `status_human_review`, keep it assigned to admin, record the timeout in SQLite, and return the handoff path to the supervisor.

## Blocking Rules

- Existing unrelated failing tests block the task.
- Missing private keys, service config, accounts, credentials, or external resources block the task.
- Blocked tasks are assigned to the admin user and receive a Linear comment.
- Context pressure at roughly 70% writes a handoff and requests a replacement agent from the supervisor when possible.
- A task sitting in `status_human_review` is not blocked. In default event-driven mode it is an expected waiting return to the supervisor; in polling mode it remains active until timeout.

## Resume

If asked to resume from SQLite:

1. Read the plan row, task rows, pending dispatch/agent rows, human-review rows, and recent events for the plan id.
2. Verify the worktree, branch, and last commit with `/usr/bin/git`.
3. Verify the active Linear issue status before taking action.
4. Continue from `restart_action` unless live git or Linear state proves it stale.
5. Append a resume event before changing Linear, dispatching work, waiting/polling on human review, or committing.

If SQLite shows a pending supervisor-mediated dispatch, return the same dispatch request unless the supervisor has already supplied a result or Linear/git state proves the task advanced. If only a legacy plan progress log exists, require `$linear-implementation-state-migration` before resuming.

## Completion

When all tasks in the plan are `Completed` or explicitly deferred:

- ensure all implementation and docs commits are on the plan branch;
- update SQLite and the Linear project summary;
- return to the supervisor with the plan worktree path, branch name, changed files, commits, completed issues, blocked/deferred issues, differences from the original plan, `state_db`, `run_id`, and `plan_id`.

Return to the supervisor only for plan completion, true blocker, event-driven human-review wait, human-review timeout handoff, context handoff, or explicit user stop. Do not return to the supervisor for ordinary human-review polling when polling mode is explicitly enabled.

Do not merge the plan branch. The `$linear-implementation-supervisor` owns merging completed plan branches into the target worktree/branch after the orchestrator returns completion.
