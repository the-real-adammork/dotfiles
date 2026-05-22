---
name: implementation-plan-task-consistency
description: Use after a task in an implementation plan is completed to update later tasks in that same plan based on what was actually implemented.
---

# Implementation Plan Task Consistency

Review one completed task against the remaining tasks in the same implementation-plan document. Update only future task instructions that are now inaccurate, redundant, blocked, or missing required follow-up because the completed task differed from the original plan.

## Start

Announce: "I'm using the implementation-plan-task-consistency skill to reconcile future tasks in this implementation plan."

Inputs:

- implementation-plan path;
- completed task heading or task number;
- summary of actual implementation;
- commit hash or diff reference when available;
- optional Linear issue key and sync ledger path.

## Rules

- Do not rewrite completed task history except to add a short completion note if requested.
- Preserve the plan's task structure and human-in-the-loop sections.
- Update only future tasks in the same plan.
- If the completed task introduced a production/dev mock, ensure a later real-service conversion task exists or add one.
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

## Output

Report:

```markdown
Plan task consistency complete.

Plan updated:
- `<path>` - yes|no

Changes:
- <task number> - <change>

Escalate to cross-plan consistency:
- <item or "None">
```
