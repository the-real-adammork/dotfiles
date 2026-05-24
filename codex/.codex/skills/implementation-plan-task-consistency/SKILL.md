---
name: implementation-plan-task-consistency
description: Use after one or more tasks in an implementation plan are completed to update later inactive tasks in that same plan based on what was actually implemented.
---

# Implementation Plan Task Consistency

Review one or more completed tasks against the remaining tasks in the same implementation-plan document. Update only future inactive task instructions that are now inaccurate, redundant, blocked, or missing required follow-up because completed work differed from the original plan.

## Start

Announce: "I'm using the implementation-plan-task-consistency skill to reconcile future tasks in this implementation plan."

Inputs:

- implementation-plan path;
- completed task heading or task number, or a batch of completed task headings/numbers;
- summary of actual implementation for each completed task;
- commit hash or diff reference for each completed task when available;
- optional list of task numbers that are active, under review, waiting for human review, or otherwise excluded from edits;
- optional Linear issue key and sync ledger path.

## Rules

- Do not rewrite completed task history except to add a short completion note if requested.
- Preserve the plan's task structure and human-in-the-loop sections.
- Update only future inactive tasks in the same plan.
- Do not patch tasks listed as active, under review, waiting for human review, or excluded by the supervisor. If a completed task invalidates an excluded task, report a coordination finding instead of editing that task section.
- When given a batch of completed tasks, reconcile the batch in one pass and produce one coherent set of downstream edits. Do not make separate repetitive edits for each completed task.
- If any completed task introduced a production/dev mock, ensure a later inactive real-service conversion task exists or add one. If the only suitable follow-up task is active or under review, report a coordination finding.
- If the change affects another implementation-plan document, report it for `$implementation-plans-consistency` instead of editing other plans.
- Use a separate docs commit when this skill is run inside an orchestrated implementation workflow.

## Checks

For future tasks, check:

- file paths, names, APIs, schemas, and commands still match reality;
- dependencies and sequencing remain correct;
- tests still target the right behavior;
- human-in-the-loop TODOs are still accurate;
- tasks do not duplicate work already completed;
- new follow-up work is represented as a concrete future task.
- active or human-review tasks are not edited underneath an in-flight worker or reviewer.

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
