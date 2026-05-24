# Durable SQLite State

The supervisor must maintain durable top-level state for every multi-plan run in SQLite so the workflow can be restarted after a Codex session crash with one prompt. SQLite tracks cross-plan sequencing, active agent names, worktree/branch pointers, Linear project pointers, and restart instructions.

The supervisor also owns detailed durable state for the active implementation plan. `$implementation-plan-orchestrator` is a legacy/optional mode only; the default workflow does not spawn a separate orchestrator agent.

Use the configured DB before starting the first plan:

```text
.codex/workflows/state.sqlite
```

Create the parent directory if needed.

## Records To Update

Update these SQLite records after every supervisor-owned transition:

- `workflow_runs`: current status, active plan/task/agent, restart action;
- `plans`: plan status, worktree, branch, source/base worktree and branch, Linear project, last commit;
- `tasks`: supervisor-level task status summaries, task branch, task base worktree/branch/commit, PR/MR target branch, and merge-back status where relevant;
- `agents`: stable agent name to host agent id/nickname mapping;
- `events`: append-only event log;
- `human_reviews`: waiting, timeout, and approval state.

Append an `events` row and update current-state rows after:

- run start or resume;
- plan started, completed, deferred, or blocked;
- worktree or branch created;
- legacy orchestrator normalized, retired, dispatched, resumed, replaced, or returned when using legacy mode;
- worker/reviewer/fix-worker/merge-worker dispatch requested, started, returned, or failed;
- Linear project or issue status/assignee/comment changes;
- task base worktree/branch/commit recorded, task branch pushed, PR/MR created or updated with target/base branch, and PR/MR URL;
- task moved to `status_human_review`;
- every human-review state transition;
- human feedback detected;
- implementation commit, task branch merge-back, docs commit, plan merge commit, or consistency commit;
- handoff written;
- workflow completion.

Do not wait until the end of a plan to update SQLite. The DB must always be current enough that a replacement supervisor can resume without chat history and continue the active plan task loop.

## Snapshot Format

Optional Markdown snapshots may be exported under `run_log_dir`, but they are generated artifacts. Do not patch Markdown run logs as canonical state.

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
- active_task_worktree: `<path or none>`
- active_task_branch: `<branch or none>`
- active_task_base_branch: `<branch or none>`
- active_task_base_commit: `<sha or none>`
- active_plan_id: `<SQLite plan id or none>`
- pending_dispatch: `<kind or none>`
- waiting_since: `<ISO timestamp or none>`
- next_poll_at: `<ISO timestamp or none>`
- last_commit: `<sha or none>`
- last_event_at: `<ISO timestamp>`
- restart_action: `<exact next action for a replacement supervisor>`
```

Also include plan status, agent directory, task status summary, pending human inputs, and an event log.

## State Normalization

When resuming a DB created before the two-layer workflow, normalize legacy orchestrator state in place before continuing.

If any active `agents` row has role/name matching `orchestrator:*`, or `workflow_runs.restart_action` says to resume an orchestrator:

1. Read `workflow_runs.active_plan_id`, `workflow_runs.active_task_id`, active `plans`, active `tasks`, pending `agents`, and pending `human_reviews`.
2. Verify Linear status for the active task issue and git status for the active worktree/branch.
3. Mark active orchestrator agents as `legacy_retired` or `superseded_by_supervisor_task_loop`.
4. Preserve active worker/reviewer/fix-worker agents if they are still running; the supervisor remains their attachment and resume owner.
5. Rewrite `workflow_runs.restart_action` to the equivalent supervisor-owned action, such as continuing after worker result, dispatching reviewer, requesting fix-worker, committing reviewed task changes, waiting for human review, processing approval, or merging completed plan branch.
6. Append an event: `normalized from legacy 3-layer orchestrator flow to 2-layer supervisor flow`.

Do not perform a separate DB migration for this normalization. It is a resume-time compatibility step.
