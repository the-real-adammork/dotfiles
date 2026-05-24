---
name: linear-implementation-supervisor
description: Use when implementing Linear-synced implementation plans from SQLite workflow state across one or more ordered plan slices.
---

# Linear Implementation Supervisor

Top-level workflow for implementing Linear-synced implementation plans. The supervisor owns plan order, the active plan task loop, Linear status transitions, worker/reviewer dispatch, human-review waits, commits, task branch merge-backs, plan branch merges, cross-plan consistency, SQLite state, and overall handoff.

## Start

Announce: "I'm using the linear-implementation-supervisor skill to supervise implementation across plans."

Inputs:

- slices document path;
- state DB path, default `.codex/workflows/state.sqlite`;
- `.codex/linear.toml` config;
- optional technical design and requirements paths.

If the slices document or state DB is missing, ask for it. If only legacy Markdown run logs or sync ledgers exist, require `$linear-implementation-state-migration` before resuming. If Linear mappings are missing from SQLite, run or request `$linear-implementation-sync` first.

## Reference Loading

Load only the reference files needed for the current action:

- `references/config.md` before reading or validating `.codex/linear.toml`.
- `references/sqlite-state.md` before creating, resuming, normalizing, or updating SQLite workflow state.
- `references/active-task-loop.md` before starting or resuming any implementation-plan task.
- `references/task-branching-and-prs.md` before creating task branches, dispatching task agents, committing task work, pushing branches, creating PRs/MRs, or accepting human-review readiness.
- `references/dependency-gate.md` before deciding whether a task can proceed without real dependencies.
- `references/human-review.md` before writing review packets, posting Linear review comments, entering human-review wait, or processing approval.
- `references/plan-merge.md` before merging a completed plan branch.
- `references/delegation.md` before spawning task workers, reviewers, fix workers, merge workers, or CLI child agents.
- `references/handoff.md` before writing a supervisor handoff or final output.

## Non-Negotiable Invariants

- SQLite is the source of truth for workflow, plan, task, agent, event, and human-review state.
- Update SQLite after every supervisor-owned transition. Do not wait until the end of a plan.
- The supervisor owns task advancement, commits, Linear transitions, human-review state, and SQLite state.
- Worker, reviewer, fix-worker, and merge-worker agents never commit, merge, advance Linear state, or update SQLite directly unless the supervisor delegates one narrow status/comment update.
- Do not spawn a separate implementation-plan orchestrator by default. Normalize legacy orchestrator state into the supervisor-owned task loop.
- Each implementation task uses a dedicated task branch based on the worktree/branch/commit it starts from.
- Within a plan, dispatch all dependency-unblocked, non-overlapping tasks in parallel by default. Ask for user approval only when task dependencies, file ownership, runtime resources, or merge risk are ambiguous or overlapping.
- A task PR/MR source/head is the task branch, and its target/base is the recorded task base branch. Never target `main`, `master`, or the remote default branch unless that is the recorded task base branch.
- Do not move a Linear issue to human review unless required automated tests are present or an accepted coverage gap is documented, required real dependencies have been satisfied or the task is blocked, the PR/MR targets the recorded task base branch, and the repo human-review packet exists.
- In default `event_driven` human-review mode, pause that task after moving it to human review. Continue other already-active tasks and dispatch other dependency-unblocked, non-overlapping tasks unless no safe work remains.
- Use `/usr/bin/git` for all git commands.

## Workflow

1. Load `references/config.md` and read `.codex/linear.toml`.
2. Load `references/sqlite-state.md`, then create or resume the durable SQLite workflow run.
3. Read the slices document and determine implementation-plan execution order.
4. Verify every plan/task has Linear mappings.
5. Resolve the admin user from `admin_user_email`.
6. For each plan in order, create or resume its worktree/branch and run the supervisor-owned active task loop using `references/active-task-loop.md`.
7. Stop only for a true blocker, event-driven human-review wait, timeout handoff, context handoff, or explicit user stop.
8. After a plan completes, load `references/plan-merge.md` and merge the completed plan branch into the target worktree/branch.
9. Run `$implementation-plans-consistency` against upcoming plans after the plan branch is merged.
10. Commit cross-plan consistency docs separately.
11. Continue to the next plan only after the merge and consistency updates are complete.

Do not run later plans before earlier plan dependencies are complete unless the slices document explicitly says they are independent and the user approves parallelism.

## Resume

If the user asks to resume an implementation run:

1. Load `references/sqlite-state.md`.
2. Read the configured SQLite state DB and locate the active `workflow_runs` row. If no run id is provided, choose the newest non-complete run for the current repo/feature and confirm the selected run.
3. Read the run row, plan rows, task rows, active agent rows, pending human reviews, and recent events.
4. Verify the active worktree, branch, and last commit with `/usr/bin/git`.
5. Verify the active Linear issue status before taking action.
6. Run State Normalization if any active agent or restart action references a legacy orchestrator.
7. Continue from `restart_action` unless live git or Linear state proves it stale.
8. Append a resume event before dispatching any new work.

Never start the workflow from scratch when SQLite shows an in-progress run. If only legacy Markdown state exists, run `$linear-implementation-state-migration` first.

## Active Plan Task Loop

Before starting or resuming any task, load:

1. `references/active-task-loop.md`
2. `references/task-branching-and-prs.md`
3. `references/dependency-gate.md`
4. `references/delegation.md`
5. `references/human-review.md`

The task loop must record the task base worktree, base branch, and base commit before creating the task branch. Task worker, fix-worker, reviewer, commit, push, and PR/MR creation operate on the task branch. Safe parallel tasks each run in their own task worktree. After human approval, merge the task branch back into its recorded base worktree/branch, enqueue task-consistency reconciliation, and run batched consistency before dispatching newly unblocked dependent tasks or completing the plan.

## Final Output

Load `references/handoff.md`, then report:

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
