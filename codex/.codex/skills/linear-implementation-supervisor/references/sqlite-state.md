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

- `workflow_runs`: current status, active plan/task compatibility pointers, restart action;
- `plans`: plan status, worktree, branch, source/base worktree and branch, Linear project, last commit;
- `tasks`: supervisor-level task status summaries, task branch, task base worktree/branch/commit, PR/MR target branch, merge-back status, and consistency eligibility where relevant;
- `task_dependencies`: explicit same-plan dependency edges and their current satisfaction status;
- `task_dispatches`: every task-worker, reviewer, fix-worker, and related dispatch attempt, including dispatch wave, worktree, branch, base commit, agent mapping, and status;
- `agents`: stable agent name to host agent id/nickname mapping;
- `events`: append-only event log;
- `human_reviews`: waiting, timeout, approval state, PR/MR URL, review packet path, branch, target branch, and reviewed commit.
- `consistency_queue`: pending batched task-consistency items, including plan id, task id, merge-back commit, actual summary, changed files, status, skipped active task notes, and consistency commit when resolved.

`workflow_runs.active_plan_id` and `workflow_runs.active_task_id` are compatibility summary fields only. In parallel task mode, derive active work from `tasks.status`, `task_dispatches.status`, `agents.status`, `human_reviews.status`, and `consistency_queue.status`. Do not assume there is only one active task or one active agent.

When opening an existing SQLite state DB, ensure additive workflow tables and columns such as `task_dependencies`, `task_dispatches`, task branch/worktree columns, human-review PR columns, and `consistency_queue` exist before using the active task loop. Use `create table if not exists` and `alter table add column if missing` style migrations; do not require destructive schema resets.

When multiple active or waiting tasks exist, set `workflow_runs.active_plan_id` and `workflow_runs.active_task_id` to `NULL` when possible, or treat their values as non-authoritative compatibility hints. Future supervisors must begin resume from:

```sql
select * from active_task_frontier where run_id = ?;
```

Do not resume from `workflow_runs.active_task_id` except as a legacy fallback when `active_task_frontier` is unavailable.

## Active Frontier Views

Create or refresh these views during state normalization and before parallel resume. Active status matching is case-insensitive and accepts both Linear display names and internal snake-case values.

Active task statuses include: `In Progress`, `in_progress`, `Agentic Review`, `agentic_review`, `Fixing`, `fixing`, `In Review`, `Human Review`, `human_review`, `Blocked`, `blocked`, `consistency_pending`, and `Consistency Pending`.

Active human-review statuses are `waiting` and `timeout`. `approved` human-review rows are historical evidence and must not appear in the active frontier. Historical `human_reviews.status = 'approved'` rows can make completed tasks look active if included in the frontier query.

Active dispatch and agent statuses are explicit allowlists: `pending`, `running`, `in_progress`, `In Progress`, `agentic_review`, `Agentic Review`, `fixing`, and `reviewing`. Legacy agent statuses such as `requested`, `closed`, `failed_closed`, `blocked_returned`, `completed`, `completed_with_findings`, `superseded`, and `superseded_by_supervisor_task_loop` are historical unless there is an active task or dispatch row requiring follow-up.

```sql
drop view if exists active_task_frontier;
create view active_task_frontier as
with active_tasks as (
  select
    p.run_id,
    t.plan_id,
    t.id as task_id,
    t.task_number,
    t.task_title,
    t.linear_issue,
    t.status as task_status,
    t.task_branch,
    t.task_worktree,
    t.pr_url,
    'task_status' as active_reason
  from tasks t
  join plans p on p.id = t.plan_id
  where lower(coalesce(t.status, '')) in (
    'in progress',
    'in_progress',
    'agentic review',
    'agentic_review',
    'fixing',
    'in review',
    'human review',
    'human_review',
    'blocked',
    'consistency_pending',
    'consistency pending'
  )
),
active_dispatches as (
  select
    td.run_id,
    td.plan_id,
    td.task_id,
    null as task_number,
    null as task_title,
    null as linear_issue,
    td.status as task_status,
    td.branch as task_branch,
    td.worktree as task_worktree,
    null as pr_url,
    'dispatch_status' as active_reason
  from task_dispatches td
  where lower(coalesce(td.status, '')) in (
    'pending',
    'running',
    'in progress',
    'in_progress',
    'agentic review',
    'agentic_review',
    'fixing',
    'reviewing'
  )
),
active_agents as (
  select
    a.run_id,
    a.plan_id,
    a.task_id,
    null as task_number,
    null as task_title,
    null as linear_issue,
    a.status as task_status,
    null as task_branch,
    null as task_worktree,
    null as pr_url,
    'agent_status' as active_reason
  from agents a
  where lower(coalesce(a.status, '')) in (
    'pending',
    'running',
    'in progress',
    'in_progress',
    'agentic review',
    'agentic_review',
    'fixing',
    'reviewing'
  )
),
active_reviews as (
  select
    hr.run_id,
    null as plan_id,
    hr.task_id,
    null as task_number,
    null as task_title,
    hr.linear_issue,
    hr.status as task_status,
    hr.branch as task_branch,
    null as task_worktree,
    hr.pr_url,
    'human_review_status' as active_reason
  from human_reviews hr
  where lower(coalesce(hr.status, '')) in ('waiting', 'timeout')
),
active_consistency as (
  select
    cq.run_id,
    cq.plan_id,
    cq.task_id,
    cq.task_number,
    null as task_title,
    cq.linear_issue,
    cq.status as task_status,
    null as task_branch,
    null as task_worktree,
    null as pr_url,
    'consistency_status' as active_reason
  from consistency_queue cq
  where lower(coalesce(cq.status, '')) in (
    'pending',
    'consistency_pending',
    'consistency pending',
    'deferred',
    'blocked'
  )
)
select * from active_tasks
union all select * from active_dispatches
union all select * from active_agents
union all select * from active_reviews
union all select * from active_consistency;

drop view if exists workflow_active_summary;
create view workflow_active_summary as
select
  run_id,
  count(distinct task_id) as active_task_count,
  group_concat(distinct task_id) as active_task_ids,
  group_concat(distinct linear_issue) as active_linear_issues,
  group_concat(distinct active_reason) as active_reasons
from active_task_frontier
group by run_id;
```

## Parallel State Migration Checklist

When normalizing an existing SQLite DB for parallel task resume:

1. Create missing tables with `CREATE TABLE IF NOT EXISTS`.
2. Add missing task and human-review columns additively.
3. Add indexes for active lookup, especially on `tasks(plan_id, status)`, `task_dispatches(run_id, task_id, status)`, `agents(run_id, task_id, status)`, `human_reviews(run_id, task_id, status)`, and `consistency_queue(run_id, task_id, status)`.
4. Create or update `active_task_frontier`.
5. Create or update `workflow_active_summary`.
6. Record a `schema_migrations` row for the parallel-resume schema version.
7. Append a `state_normalized` event with the migration/version details.
8. Never destructively reset existing workflow state.

Append an `events` row and update current-state rows after:

- run start or resume;
- plan started, completed, deferred, or blocked;
- worktree or branch created;
- legacy orchestrator normalized, retired, dispatched, resumed, replaced, or returned when using legacy mode;
- worker/reviewer/fix-worker/merge-worker dispatch requested, started, returned, or failed;
- dispatch wave selected, skipped for overlap, or blocked for ambiguous dependencies;
- Linear project or issue status/assignee/comment changes;
- task base worktree/branch/commit recorded, task branch pushed, PR/MR created or updated with target/base branch, and PR/MR URL;
- task dependency edge created, satisfied, blocked, or found unresolved;
- task moved to `status_human_review`;
- every human-review state transition;
- human feedback detected;
- implementation commit, task branch merge-back, docs commit, plan merge commit, or consistency commit;
- task-consistency item enqueued, batched, skipped because downstream tasks are active, applied, or deferred with coordination findings;
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

- phases_document: `<path>`
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
- active_tasks: `<task ids/titles or none>`
- active_agents: `<stable agent names or none>`
- pending_consistency: `<task ids/merge commits waiting for batched reconciliation or none>`
- pending_dispatch: `<kind or none>`
- waiting_since: `<ISO timestamp or none>`
- next_poll_at: `<ISO timestamp or none>`
- last_commit: `<sha or none>`
- last_event_at: `<ISO timestamp>`
- restart_action: `<exact next action for a replacement supervisor>`
```

Also include plan status, agent directory, task status summary, pending human inputs, and an event log.

## Parallel State Model

For parallel task execution:

- store one `tasks` row per implementation-plan task;
- store one `task_dependencies` row per explicit same-plan blocker relation;
- store one `task_dispatches` row for every task-worker, task-reviewer, fix-worker, or replacement dispatch;
- store one `agents` row per stable agent name to host id mapping;
- store one `human_reviews` row per task waiting for human approval;
- store pending reconciliation in `consistency_queue`.

Task status values should distinguish at least: `todo`, `blocked`, `in_progress`, `agentic_review`, `fixing`, `human_review`, `done`, `merged_back`, and `consistency_pending` when those states are known. Active tasks are rows whose status is in active/review/waiting states, not the singular `workflow_runs.active_task_id`.

Task execution fields live on `tasks`: `task_branch`, `task_worktree`, `task_base_worktree`, `task_base_branch`, `task_base_commit`, `pr_target_branch`, `pr_url`, `implementation_commit`, `merge_back_commit`, `merge_back_status`, `consistency_status`, `blocked_reason`, and `dependency_notes`.

Human review fields live on `human_reviews`: `pr_url`, `review_packet_path`, `branch`, `target_branch`, and `commit_sha`.

## State Normalization

When resuming a DB created before the two-layer workflow, normalize legacy orchestrator state in place before continuing.

If any active `agents` row has role/name matching `orchestrator:*`, or `workflow_runs.restart_action` says to resume an orchestrator:

1. Read `workflow_runs.active_plan_id`, `workflow_runs.active_task_id`, active `plans`, active `tasks`, pending `task_dispatches`, pending `agents`, pending `human_reviews`, and pending `consistency_queue` items.
2. Verify Linear status for active task issues and git status for active task worktrees/branches.
3. Mark active orchestrator agents as `legacy_retired` or `superseded_by_supervisor_task_loop`.
4. Preserve active worker/reviewer/fix-worker agents if they are still running; the supervisor remains their attachment and resume owner.
5. Rewrite `workflow_runs.restart_action` to the equivalent supervisor-owned action, such as continuing after worker result, dispatching reviewer, requesting fix-worker, committing reviewed task changes, waiting for human review, processing approval, or merging completed plan branch.
6. Append an event: `normalized from legacy 3-layer orchestrator flow to 2-layer supervisor flow`.

Do not perform a separate DB migration for this normalization. It is a resume-time compatibility step.
