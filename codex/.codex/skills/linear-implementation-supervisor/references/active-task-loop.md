# Active Plan Task Loop

The supervisor owns the task loop for the active implementation plan. Do not spawn an orchestrator by default.

## Parallel Task Dispatch

For each active plan, the supervisor should maintain a dispatch wave of all tasks that are safe to run now:

1. Read the plan task dependency declarations, Linear issue blockers, SQLite task rows, active task rows, and pending consistency queue.
2. Treat a task as unblocked when all same-plan `Depends On` tasks and Linear blockers are complete, required source sections are current, and any pending consistency edits that could affect it have been applied or explicitly deferred.
3. Compare the planned file map, task section ownership, required real dependencies, and runtime resources for every unblocked task against currently active tasks.
4. Dispatch dependency-unblocked tasks in parallel by default when their planned file ownership and runtime resources do not overlap active work.
5. Ask the user before parallel dispatch only when file ownership overlaps, dependency data is missing, a task touches a shared migration/schema/API boundary, runtime resources cannot be isolated, or the supervisor cannot determine merge risk from the plan.
6. Record the parallel-dispatch decision, overlap check, active task set, task worktree, task branch, and agent mapping in SQLite before spawning workers.
7. If no safe parallel work remains and at least one task is in human review, enter event-driven human-review wait for the blocked frontier only.

Do not serialize tasks merely because they appear later in the plan. Plan order is secondary to explicit task dependencies and safe file/resource ownership.

For each task selected for the current dispatch wave:

1. Read the implementation-plan task section, plan-level human TODOs, SQLite task row, and Linear issue.
2. Identify required real dependencies for the task: credentials, accounts, services, databases, queues, external APIs, seed data, devices, browser access, paid services, and real network/data paths. Apply `dependency-gate.md`.
3. Direct the worker to provision or start any dependency it can safely create locally or through available authenticated tooling.
4. If a required dependency cannot be provisioned by the agent, assign the issue to the configured admin user, set status to `Blocked`, comment with exact unblock instructions, update SQLite, and continue only if another task is unblocked.
5. Create or verify the plan worktree and branch.
6. Apply `task-branching-and-prs.md`: record the task base worktree, base branch, and base commit before creating the task branch.
7. Create or verify the task branch from that recorded base commit using `task_branch_template`.
8. Set the Linear issue to `status_in_progress` and update SQLite.
9. Dispatch one `task-worker` sub-agent for this task only using `delegation.md`.
10. When the worker returns, record changed files, verification, stdout-rich evidence, dependency provisioning attempts, and task-satisfaction notes in SQLite or local artifacts. Keep Linear worker comments compact.
11. Set the Linear issue to `status_agentic_review`.
12. Dispatch one `task-reviewer` sub-agent using `$task-implementation-review`.
13. For High/Medium findings, dispatch one `fix-worker`, then rerun review. Repeat until blocking findings are fixed or the task is blocked.
14. Commit implementation changes for the task from the supervisor after review passes.
15. Push the task branch and create or update a GitLab merge request or configured repository pull request targeting the recorded task base branch.
16. Write the repo human-review packet, post the compact Linear review comment, set the Linear issue to `status_human_review`, assign it to the admin user, update SQLite, and pause that task for human review. Continue other active tasks and dispatch other safe unblocked tasks. Enter Human Review Wait only when no other safe active-plan work can continue.
17. If Linear status becomes `status_done`, merge the approved task branch back into its recorded base worktree/branch, update the implementation plan with a compact actual-vs-planned note for the completed task, commit that note separately, enqueue a task-consistency reconciliation item in SQLite, and continue according to the consistency batching rules below.

Worker and reviewer agents never commit, merge, advance Linear state, or update SQLite directly unless the supervisor explicitly delegates a narrow status/comment update. They return evidence to the supervisor.

## Consistency Batching

Task branch merge-back is per task, but implementation-plan consistency is batched to reduce plan-doc churn when multiple tasks are active or approved close together.

After a task branch is merged back:

1. Record the merge-back SHA, completed task number, Linear issue, actual implementation summary, changed files, and any known follow-up impact in SQLite `consistency_queue` with status `pending`.
2. Do not immediately run `$implementation-plan-task-consistency` when other tasks in the same plan are active, under agentic review, in fix, or waiting for human review, unless the completed task introduced a blocker that invalidates their active work.
3. Before dispatching any new task, before dispatching a task whose dependency just became satisfied, before declaring the plan complete, or when no active task work remains in the plan, coalesce all pending consistency items for that plan into one consistency pass.
4. Run `$implementation-plan-task-consistency` with the full batch of completed task summaries and commit references.
5. Limit consistency edits to tasks that are not active, not under review, not waiting for human review, and not already completed.
6. If the consistency pass identifies changes that would affect an active or human-review task, do not silently patch that task section. Record a coordination finding in SQLite and either let the active task finish, restart it from the refreshed plan section, or dispatch a fix-worker after human/supervisor decision.
7. Commit consistency-doc updates separately from implementation merge-back notes and update SQLite with the consistency commit SHA, affected task numbers, skipped active tasks, and any coordination findings.

When multiple completed tasks are pending, the consistency pass should treat their merge-back commits as one batch and update downstream inactive tasks once. Do not run one consistency commit per completed task unless only one pending item exists and no other task in the plan is active.

## Automated Tests

Before moving any Linear issue to `status_human_review`, verify that the implementation includes automated tests appropriate to the task:

- unit tests for isolated logic, validation, transformations, and edge cases;
- integration tests for database, filesystem, service wiring, queues, CLIs, or internal API boundaries;
- end-to-end tests when the task changes a user-visible workflow, cross-service behavior, or real-data path.

Do not substitute manual smoke testing for missing automated tests. If a task truly cannot add automated coverage, the worker/reviewer must explain why, identify the closest executable check, and the reviewer must decide whether that gap is acceptable or blocking.
