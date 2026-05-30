# Plan Task Consistency Reference

Review one or more completed tasks against the remaining tasks in the same implementation-plan document. Update only future inactive task instructions that are now inaccurate, redundant, blocked, or missing required follow-up because completed work differed from the original plan.

## Inputs

- implementation-plan path;
- completed task heading or task number, or a batch of completed task headings/numbers;
- summary of actual implementation for each completed task;
- commit hash or diff reference for each completed task when available;
- optional list of task numbers that are active, under review, or otherwise excluded from edits;
- optional Linear issue key and sync ledger path.

## Rules

- Do not rewrite completed task history except to add a short completion note if requested.
- Preserve the plan's task structure, compact task `Execution` lines, `Service Wiring Rows Covered`, `Agent-Run Acceptance`, `Test Mode Disclosure`, `Phase Execution Contract`, `Autonomy And Escalation`, `Service Wiring Matrix`, and `Phase Acceptance Gate`.
- Update only future inactive tasks in the same plan.
- Do not patch tasks listed as active, under review, or excluded by the supervisor. If a completed task invalidates an excluded task, report a coordination finding instead of editing that task section.
- When given a batch of completed tasks, reconcile the batch in one pass and produce one coherent set of downstream edits. Do not make separate repetitive edits for each completed task.
- If any completed task introduced a production/dev mock, ensure a later inactive real-service conversion task exists or add one. If the only suitable follow-up task is active or under review, report a coordination finding.
- If implementation changed service wiring, update the plan's `Service Wiring Matrix`, task-level `Service Wiring Rows Covered`, and `Phase Acceptance Gate`.
- If implementation created, moved, or changed the E2E harness, update future task commands and acceptance-packet evidence expectations.
- If implementation changed task boundaries, shared resources, safe parallelism, or delegation efficiency, update task `Execution` lines and the `Phase Execution Contract`.
- If the change affects another implementation-plan document, report it for `references/cross-plan-consistency.md` instead of editing other plans.
- Use a separate docs commit when this reference is run inside an orchestrated implementation workflow.

## Checks

For future tasks, check:

- file paths, names, APIs, schemas, and commands still match reality;
- dependencies and sequencing remain correct;
- task execution lines, delegation lanes, safe parallelism, shared-resource risks, and integration checkpoints still match reality;
- delegation remains efficient by grouping related small work into bounded worker lanes rather than assigning tasks to the orchestrator; runtime, service/API, persistence, schema/migration, parser, frontend, E2E/integration-test, shared-contract, docs/config, setup, remediation, and acceptance work must stay in worker lanes even when serial;
- no future task uses ambiguous ownership such as `orchestrator`, `orchestrator or worker`, `orchestrator or one worker`, or `orchestrator unless delegated`, and no future task is orchestrator-owned;
- tests still target the right behavior;
- agent-run acceptance commands, expected results, and evidence fields are still accurate;
- escalation entries are still allowed, necessary, and not routine agent-owned setup;
- task-level `Service Wiring Rows Covered` entries still match the actual implementation;
- service wiring matrix rows still match the actual implementation;
- the phase acceptance gate still covers every applicable service-wiring row;
- acceptance packet path and required contents still match the phase's actual evidence;
- tasks do not duplicate work already completed;
- new follow-up work is represented as a concrete future task;
- active or reviewed tasks are not edited underneath an in-flight worker or reviewer.

## Output

Report:

```markdown
Plan task consistency complete.

Plan updated:
- `<path>` - yes|no

Changes:
- <task number> - <change>

Skipped active or reviewed tasks:
- <task number> - <reason, or "None">

Coordination findings:
- <finding or "None">

Escalate to cross-plan consistency:
- <item or "None">
```
