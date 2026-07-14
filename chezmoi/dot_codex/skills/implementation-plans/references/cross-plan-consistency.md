# Cross-Plan Consistency Reference

Review a completed implementation plan against upcoming implementation plan documents. Patch future plans when the completed work changed APIs, schemas, behavior, ownership boundaries, delegation assumptions, verification commands, E2E harnesses, service wiring, phase acceptance evidence, or sequencing assumptions.

## Inputs

- completed implementation-plan path;
- summary of actual implementation;
- SLICES document path, default `docs/plans/SLICES.md`;
- upcoming implementation-plan paths;
- optional technical design, requirements, sync ledger, and commit range.

## Rules

- Do not modify the completed plan except to link its completion summary or phase acceptance packet when requested.
- Update only not-yet-started or not-yet-completed implementation-plan docs.
- Preserve each plan's task format, compact task `Execution` lines, `Service Wiring Rows Covered`, `Agent-Run Acceptance`, `Test Mode Disclosure`, `Phase Execution Contract`, `Autonomy And Escalation`, `Service Wiring Matrix`, and `Phase Acceptance Gate`.
- Update downstream phase boundaries when implementation reality requires it, provided the change preserves the technical design intent and makes later execution more accurate.
- Escalate only credentials/secrets, paid/vendor setup, unresolved product/legal/security decisions, destructive production actions, real customer data access, or unavailable devices/services after an agent-owned attempt.
- Record rationale when changing phase boundaries, downstream assumptions, service wiring, E2E commands, or acceptance-packet expectations.
- Use a separate docs commit when this reference is run inside a supervisor workflow.

## Checks

For upcoming plans, verify:

- dependencies on the completed plan match what was actually shipped;
- file paths, APIs, schema names, data contracts, flags, and commands are current;
- future tasks do not repeat completed work;
- worker lanes, task execution lines, shared-resource risks, integration checkpoints, and delegation efficiency reflect the actual completed implementation;
- future tasks include new integration or migration work made necessary by the completed plan;
- mock-to-real conversion tasks still exist where required;
- service wiring matrix rows reflect actual completed behavior and planned downstream integrations;
- task-level `Service Wiring Rows Covered` entries reflect actual completed behavior and planned downstream integrations;
- E2E harness setup and commands reflect the current repo;
- phase acceptance gates cover all applicable wiring rows for each future phase;
- acceptance packet expectations include evidence later phases need;
- execution order in the phases document still makes sense.

## Output

Report:

```markdown
Cross-plan consistency complete.

Plans updated:
- `<path>` - <summary or "no changes">

Phases document updated:
- yes|no

Escalations:
- <allowed escalation or "None">
```
