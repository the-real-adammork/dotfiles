---
name: implementation-plans-consistency
description: Use after an implementation plan is completed to update upcoming implementation-plan documents based on what was actually implemented.
---

# Implementation Plans Consistency

Review a completed implementation-plan against upcoming implementation-plan documents. Patch future plans when the completed work changed APIs, schemas, behavior, ownership boundaries, verification commands, or sequencing assumptions.

## Start

Announce: "I'm using the implementation-plans-consistency skill to reconcile upcoming implementation plans."

Inputs:

- completed implementation-plan path;
- summary of actual implementation;
- slices document path;
- upcoming implementation-plan paths;
- optional technical design, requirements, sync ledger, and commit range.

## Rules

- Do not modify the completed plan except to link its completion summary when requested.
- Update only not-yet-started or not-yet-completed implementation-plan docs.
- Preserve each plan's task format, human-in-the-loop tests, and test mode disclosures.
- Ask before changing slice boundaries or design intent.
- Use a separate docs commit when this skill is run inside a supervisor workflow.

## Checks

For upcoming plans, verify:

- dependencies on the completed plan match what was actually shipped;
- file paths, APIs, schema names, data contracts, flags, and commands are current;
- future tasks do not repeat completed work;
- future tasks include new integration or migration work made necessary by the completed plan;
- mock-to-real conversion tasks still exist where required;
- execution order in the slices document still makes sense.

## Output

Report:

```markdown
Cross-plan consistency complete.

Plans updated:
- `<path>` - <summary or "no changes">

Slices document updated:
- yes|no

Human decisions needed:
- <decision or "None">
```
