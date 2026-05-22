---
name: linear-implementation-sync
description: Use when local implementation-plan documents need to be mapped into Linear projects and issues, with idempotent sync from Markdown plans to Linear execution tracking.
---

# Linear Implementation Sync

Map local implementation planning artifacts into Linear without making Linear the source of truth. Local Markdown documents remain canonical for architecture, task details, human-in-the-loop tests, and verification. Linear becomes the execution tracker for assignment, status, discussion, and later implementation workflow updates.

SQLite is the canonical mutable workflow state. Legacy Markdown sync ledgers are migration inputs or optional generated snapshots only; do not patch them as the live state store.

## Start

Announce: "I'm using the linear-implementation-sync skill to map local implementation plans into Linear."

Inputs:

- slices document path, preferred;
- one or more implementation-plan paths, if no slices document is available;
- optional requirements or technical-design path for back-reference context;
- optional config path, default `.codex/linear.toml`;
- optional state DB path, default `.codex/workflows/state.sqlite`;
- optional Linear team, initiative, project naming prefix, labels, assignee, and dry-run preference.

If neither a slices document nor plan paths are provided and they cannot be inferred from `docs/plans/`, ask for the missing path.

## Project Config

Before asking for Linear defaults, check for a repo-local config file:

```text
.codex/linear.toml
```

If the user provides a config path, use that instead. Prompt-provided values override config values. Config values override skill defaults.

The config is for non-secret workflow defaults only. It may include:

```toml
state_backend = "sqlite"
state_db = ".codex/workflows/state.sqlite"
legacy_state_mode = "archived"

team_key = "ENG"
admin_user_email = "adam@example.com"
project_naming_prefix = "Billing Revamp"

default_labels = [
  "codex",
  "implementation-plan"
]
create_missing_labels = false

handoff_dir = "docs/handoffs"
run_log_dir = "docs/linear/runs"
smoke_test_dir = "docs/linear/smoke-tests"
project_name_template = "{prefix} - {slice_name}"
issue_title_template = "{task_number}: {task_title}"
task_heading_levels = [2, 3]

preserve_existing_status = true
dry_run_by_default = true

status_todo = "Todo"
status_in_progress = "In Progress"
status_blocked = "Blocked"
status_agentic_review = "Agentic Review"
status_human_review = "In Review"
status_done = "Completed"

worktree_dir = ".worktrees"
branch_template = "codex/{feature}/{plan_slug}"
poll_interval_minutes = 5
human_review_timeout_minutes = 60
assign_blocked_to_admin = true
assign_human_review_to_admin = true
block_on_existing_test_failures = true
context_handoff_threshold_percent = 70
```

Allowed keys:

- `team_key` or `team_name`;
- `admin_user_email`;
- `state_backend`;
- `state_db`;
- `legacy_state_mode`;
- `project_naming_prefix`;
- `default_labels`;
- `create_missing_labels`;
- `handoff_dir`;
- `run_log_dir`;
- `smoke_test_dir`;
- `project_name_template`;
- `issue_title_template`;
- `task_heading_levels`;
- `preserve_existing_status`;
- `dry_run_by_default`;
- `assignee`;
- `initiative`;
- status mapping keys: `status_todo`, `status_in_progress`, `status_blocked`, `status_agentic_review`, `status_human_review`, `status_done`;
- execution keys: `worktree_dir`, `branch_template`, `poll_interval_minutes`, `human_review_timeout_minutes`, `assign_blocked_to_admin`, `assign_human_review_to_admin`, `block_on_existing_test_failures`, `context_handoff_threshold_percent`, `worker_dispatch`, `worker_model`, `reviewer_model`.

Sync uses only the setup fields directly, but it should tolerate execution fields because the supervisor and orchestrator workflows use the same repo config.

`state_backend` must be `sqlite` for new sync runs. If config says `markdown` or only a legacy ledger exists, stop and ask the user to run `$linear-implementation-state-migration` first unless this is a brand-new project with no legacy state.

Do not store OAuth tokens, API keys, bearer tokens, personal access tokens, cookies, or credentials in this config. If a config file contains likely secrets, stop reading it, add a narrow `.gitignore` rule for that exact path if it is untracked, and tell the user to move secrets out before continuing.

If no team is provided by prompt or config, use Linear MCP to list available teams when possible, then ask the user which team should own the created issues and projects.

## Required Linear Access

Use the Linear MCP tools exposed to Codex. If Linear tools are unavailable, tell the user to restart Codex after configuring Linear MCP, then stop before attempting sync.

Do not ask the user for Linear API keys unless the MCP OAuth flow is unavailable. Never store Linear credentials in the repo.

## Source Mapping

Default mapping:

- technical design or requirements doc -> back-reference only, unless the user requests an Initiative;
- slices document -> sync index and source of approved plan paths;
- each implementation-plan doc -> one Linear Project;
- each `### Task N: <title>` section -> one Linear Issue;
- also accept `## Task N: <title>` when present, because some generated plans use task headings one level higher;
- task checklist steps -> Markdown checklist in the issue body, not separate issues.

Do not create Linear issues for every task step unless the user explicitly asks.

## Plan-at-a-Time Sync

When a slices document contains multiple implementation plans, process one plan at a time by default.

1. Build a local desired-state manifest for all plans first:
   - plan path, plan title, slice order, project sync key, source hash;
   - task anchors, issue titles, issue sync keys, source hashes;
   - create/update/skip prediction from SQLite state and Linear sync-key lookup.
2. Present a compact overall summary and the first pending plan's dry-run details.
3. Ask for approval to sync only that one plan.
4. After approval, create or update that plan's Linear Project and its issues, then update SQLite.
5. Repeat with the next pending plan until all plans are synced or the user stops.

Do not ask the user to approve a large all-plans mutation unless they explicitly request a batch sync. If the user requests batch sync, still apply mutations plan-by-plan internally and update SQLite after each plan so retries can resume safely.

If a run is interrupted, resume from SQLite and regenerate the manifest. Skip plans whose project and all task issues are already represented with matching source hashes.

## SQLite State

Create or update the configured state DB:

```text
.codex/workflows/state.sqlite
```

If `state_db` is missing from config, default to `.codex/workflows/state.sqlite`. Create the parent directory if needed.

The state DB is the local idempotency and handoff record. It must include or update these logical records:

- `workflow_runs`: feature, input paths, config path, active state, restart action;
- `plans`: plan path, order, title, slug, source hash, Linear project mapping, branch/worktree placeholders;
- `tasks`: task source refs, task titles, source hashes, Linear issue mappings, status, assignee;
- `source_hashes`: normalized source hashes for plans and task sections;
- `events`: append-only sync decisions, warnings, creates, updates, skips;
- `artifacts`: optional generated snapshots, reports, and legacy import references.

Markdown sync ledgers may be generated as human snapshots, but they are not the canonical mutable state.

## Stable Sync Keys

Every Linear Project and Issue must include stable source markers in its description/body:

```text
Codex-Source: <relative-path>#<anchor>
Codex-Sync-Key: <stable-key>
Codex-Source-Hash: <hash>
```

Use deterministic keys:

- project key: hash or slug from implementation-plan relative path plus plan title;
- issue key: project key plus task number and task title;
- source hash: hash of the normalized source section content.

Before creating anything, search Linear and SQLite for the sync key. If found, update the existing object instead of creating a duplicate.

## Issue Body

Each Linear issue body should preserve the execution-critical parts of the local task:

- source plan path and task anchor;
- task goal/title;
- files list;
- human-in-the-loop test;
- test mode disclosure;
- task steps/checklist;
- verification commands and expected results;
- suggested commit message;
- link or reference back to the state DB run id or generated sync snapshot.

If a task section is missing human-in-the-loop test or test mode disclosure, flag it in the dry run. Do not silently omit the gap.

## Dry Run First

Always produce a dry-run summary before mutating Linear unless the user explicitly says to skip dry run.

The first dry run must include an overall manifest summary:

- total plans discovered;
- plans already in sync;
- plans needing create/update work;
- plans blocked by invalid task sections or missing decisions;
- next plan selected for sync.

The per-plan dry run must list only the currently selected plan:

- project to create or update;
- issues to create;
- issues to update;
- source tasks skipped, with reasons;
- effective config values used, excluding absent/defaulted values that do not affect the run;
- missing team decisions;
- missing label decisions, including whether configured labels should be created or skipped;
- assignee state. No assignee is acceptable; report it as unassigned rather than blocking;
- warnings about invalid or incomplete implementation-plan task sections.

Ask the user to approve before creating or updating Linear objects for that plan. After each plan completes, present the next plan's dry run and ask again unless the user explicitly approved batch mode.

## Mutation Rules

After approval:

1. Create or update the Linear Project for the currently selected implementation plan.
2. Create or update Linear issues for each task in that plan.
3. Apply labels such as `codex`, `implementation-plan`, feature slug, and slice slug when available.
4. If configured labels do not exist, create them only when `create_missing_labels = true` or the user approved label creation after the dry run. Otherwise skip missing labels and record the decision in SQLite.
5. Leave issues unassigned when no assignee is configured or approved.
6. Preserve current Linear status unless the issue is newly created or the user explicitly requests status changes.
7. Update SQLite with Linear URLs, IDs, sync keys, source hashes, branch/worktree placeholders, and warnings.

Update SQLite immediately after each plan, not only at the end of the whole slices document. SQLite is the resume point for later plans.

Never delete Linear projects or issues during sync. If a local task disappears, mark it in SQLite as missing from source and ask the user before any archival action.

## Future Execution Workflow Boundary

This skill only performs planning-to-Linear setup. It must not implement tasks.

Prepare for later implementation workflows by ensuring:

- every issue has a stable `Codex-Sync-Key`;
- every issue points back to the exact local task section;
- SQLite records source hashes so later workflows can detect drift;
- Linear status is not treated as proof that local code changed;
- local plans remain the source of implementation detail.

A future execution workflow can then:

- pick a Linear issue by sync key or issue identifier;
- read the referenced local task section;
- implement and verify the task;
- update Linear status and comments with evidence;
- update SQLite if source or status changed.

## Final Checks

Before handoff:

- every generated Linear project has a source marker;
- every generated Linear issue has a source marker and source hash;
- every local task is represented in SQLite as created, updated, skipped, or blocked;
- no duplicate Linear objects were created for existing sync keys;
- SQLite records source docs and Linear URLs;
- sync warnings and required human decisions are explicit.

## Handoff

Report:

```markdown
Linear sync status: <complete|partially complete|stopped after current plan>.

State DB:
- `<path>`

Current plan:
- `<Linear project>` - <created|updated> - <URL>

Current plan issues:
- Created: <count>
- Updated: <count>
- Skipped/blocked: <count>

Overall progress:
- Plans synced: <count>/<total>
- Next pending plan: `<path or none>`

Warnings:
- <warning or "None">
```

Then offer the next step:

```text
Next options:
1. Review the Linear project/issue structure.
2. Build the follow-on workflow for implementing Linear-backed tasks.
3. Stop here and keep Linear as a tracking mirror of the local plans.
```
