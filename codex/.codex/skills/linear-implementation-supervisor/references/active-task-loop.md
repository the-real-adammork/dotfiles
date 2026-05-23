# Active Plan Task Loop

The supervisor owns the task loop for the active implementation plan. Do not spawn an orchestrator by default.

For each task in the active plan:

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
16. Write the repo human-review packet, post the compact Linear review comment, set the Linear issue to `status_human_review`, assign it to the admin user, update SQLite, and enter Human Review Wait.
17. If Linear status becomes `status_done`, merge the approved task branch back into its recorded base worktree/branch, update the implementation plan with actual-vs-planned notes, commit docs separately, run `$implementation-plan-task-consistency`, commit consistency docs separately, update SQLite, and continue.

Worker and reviewer agents never commit, merge, advance Linear state, or update SQLite directly unless the supervisor explicitly delegates a narrow status/comment update. They return evidence to the supervisor.

## Automated Tests

Before moving any Linear issue to `status_human_review`, verify that the implementation includes automated tests appropriate to the task:

- unit tests for isolated logic, validation, transformations, and edge cases;
- integration tests for database, filesystem, service wiring, queues, CLIs, or internal API boundaries;
- end-to-end tests when the task changes a user-visible workflow, cross-service behavior, or real-data path.

Do not substitute manual smoke testing for missing automated tests. If a task truly cannot add automated coverage, the worker/reviewer must explain why, identify the closest executable check, and the reviewer must decide whether that gap is acceptable or blocking.
