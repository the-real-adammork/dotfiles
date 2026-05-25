---
name: linear-implementation-state-migration
description: Use when a legacy Linear implementation workflow run that used Markdown run logs and sync ledgers must be migrated into the SQLite workflow state database before resuming with SQL-backed workflows.
---

# Linear Implementation State Migration

Migrate one legacy Linear implementation workflow run from Markdown state files into SQLite. This is a one-way workflow-state migration: after validation, legacy run logs and ledgers are archived and SQLite becomes the only mutable workflow state.

## Start

Announce: "I'm using the linear-implementation-state-migration skill to migrate legacy Linear workflow state into SQLite."

Inputs:

- slices document path;
- legacy Linear sync ledger path;
- legacy supervisor run log path, if implementation has started;
- legacy orchestrator run log paths, if known;
- `.codex/linear.toml` config path, default `.codex/linear.toml`;
- optional state DB path, default `.codex/workflows/state.sqlite`;
- optional archive directory, default `docs/linear/legacy-state/<run-id>/`;
- optional migration report path, default `docs/linear/migrations/YYYY-MM-DD-<feature>-state-migration.md`.

If the slices document or legacy sync ledger is missing, ask for the path. If a SQLite row for the same run already exists, inspect it and ask before overwriting or importing duplicate state.

## Migration Contract

The migration must preserve restartability before archiving legacy state:

- every implementation plan in the slices document has a `plans` row;
- every task found in each plan has a `tasks` row;
- every Linear project/issue mapping found in the ledger is represented;
- active supervisor/orchestrator state is represented in `workflow_runs`, `plans`, `tasks`, `agents`, and `human_reviews` where possible;
- source paths, anchors, source hashes, worktrees, branches, commits, and restart actions are preserved when present;
- all imported rows include legacy source file references;
- the migration report records warnings for anything inferred or missing.

Do not delete legacy files outright. Archive mutable legacy state files, such as sync ledgers and run logs, under `docs/linear/legacy-state/<run-id>/` after validation. Do not archive source artifacts such as the slices document or implementation plans. The archive is read-only audit material; future workflow runs must not patch those files.

## SQLite State

Default DB path:

```text
.codex/workflows/state.sqlite
```

The migration script creates the schema if needed, including additive workflow tables such as `task_dependencies`, `task_dispatches`, and `consistency_queue`. The SQLite DB is the canonical mutable workflow state after migration. Markdown requirements, technical designs, implementation plans, reviews, smoke-test files, and handoffs remain normal repo artifacts. Store paths, anchors, hashes, and status in SQLite rather than copying large document bodies into SQL.

## Workflow

1. Read `.codex/linear.toml` and confirm `state_backend = "sqlite"` or prepare to set it after migration.
2. Run a dry-run import with the bundled script:

   ```bash
   python3 /Users/adam/.codex/skills/linear-implementation-state-migration/scripts/migrate_legacy_state.py \
     --db .codex/workflows/state.sqlite \
     --slices <slices-document> \
     --ledger <legacy-sync-ledger> \
     --supervisor-run-log <legacy-supervisor-run-log> \
     --config .codex/linear.toml \
     --dry-run
   ```

   Add repeated `--orchestrator-run-log <path>` arguments for known plan logs.
3. Review the dry-run summary:
   - run id;
   - plans and tasks discovered;
   - Linear projects/issues imported;
   - active state recovered;
   - warnings and missing fields;
   - legacy files that would be archived.
4. If the dry run shows missing active state, inspect the relevant legacy run log or Linear issue and rerun with corrected inputs.
5. Run the migration for real:

   ```bash
   python3 /Users/adam/.codex/skills/linear-implementation-state-migration/scripts/migrate_legacy_state.py \
     --db .codex/workflows/state.sqlite \
     --slices <slices-document> \
     --ledger <legacy-sync-ledger> \
     --supervisor-run-log <legacy-supervisor-run-log> \
     --config .codex/linear.toml \
     --archive
   ```

6. Update `.codex/linear.toml`:

   ```toml
   state_backend = "sqlite"
   state_db = ".codex/workflows/state.sqlite"
   legacy_state_mode = "archived"
   ```

7. Verify the DB and migration report exist.
8. Restart the implementation with `$linear-implementation-supervisor`, passing the state DB path instead of the legacy sync ledger/run log.

## Validation

Before declaring migration complete:

- run the migration script without `--dry-run`;
- confirm it exits successfully;
- confirm the report was written under `docs/linear/migrations/`;
- query the DB for row counts:

  ```bash
  sqlite3 .codex/workflows/state.sqlite \
    "select 'plans', count(*) from plans union all select 'tasks', count(*) from tasks union all select 'task_dependencies', count(*) from task_dependencies union all select 'task_dispatches', count(*) from task_dispatches union all select 'events', count(*) from events union all select 'consistency_queue', count(*) from consistency_queue;"
  ```

- confirm the parallel resume views exist:

  ```bash
  sqlite3 .codex/workflows/state.sqlite \
    "select name from sqlite_master where type = 'view' and name in ('active_task_frontier', 'workflow_active_summary');"
  ```

- confirm legacy run logs and ledgers were archived if `--archive` was used;
- confirm `.codex/linear.toml` points to SQLite state.

## Handoff

Report:

```markdown
Linear workflow state migration complete.

State DB:
- `<path>`

Migration report:
- `<path>`

Archived legacy state:
- `<path or "not archived">`

Imported:
- Plans: <count>
- Tasks: <count>
- Linear projects: <count>
- Linear issues: <count>

Warnings:
- <warning or "None">

Restart:
- Use `$linear-implementation-supervisor` with state DB `<path>`.
```
