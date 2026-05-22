---
name: technical-design
description: Use when the user wants a higher-level technical design, architecture strategy, implementation approach, or responsibility map before detailed task planning.
---

# Technical Design

Write the intermediary design layer between requirements and task-level implementation plans. A technical design explains the implementation goals, architecture, ownership boundaries, integration points, sequencing, risks, and validation strategy without expanding into a full task checklist.

## Start

Announce: "I'm using the technical-design skill to define the implementation strategy."

Inspect enough of the repo to understand current patterns, relevant files, tests, commands, and constraints. Use `/usr/bin/git` when git is needed.

Save designs to:

```text
docs/designs/YYYY-MM-DD-<short-feature-name>.md
```

User instructions about design location override this default.

## When To Use

Use this skill when:

- The desired behavior is known but the implementation shape is not.
- Multiple modules, services, UI surfaces, or data flows need to mesh cleanly.
- The user asks for an architecture, approach, strategy, technical plan, or design doc.
- A detailed task plan would be premature because responsibilities and boundaries are not settled.

If the user asks for exact task checklists, use `$implementation-plans` after this design is approved.

## Design Rules

- Stay above task granularity. Do not write checkbox steps or commit-sized tasks.
- Be concrete about responsibilities, boundaries, data flow, and integration points.
- Follow existing project conventions unless there is a clear reason to change them.
- Name exact files, modules, routes, commands, schemas, or components when known.
- Explicitly call out non-goals and rejected alternatives.
- Surface unresolved questions rather than hiding assumptions.
- Use plain Markdown prose, bullets, and tables by default. Do not require C4, ADRs, Mermaid, UML, or any formal notation unless the user explicitly asks.

## Human Decision Gates

Ask for human input before locking in any design choice that materially affects architecture, product behavior, data shape, migration risk, security/privacy posture, operational complexity, or future extensibility.

Use this process:

1. Identify the decision and why it matters.
2. Present 2-3 viable options with tradeoffs.
3. Recommend one option and explain why.
4. Ask one focused question and wait for the answer.
5. Record the chosen option in the technical design.

Do not ask for approval on obvious local conventions, minor naming choices, or details that can safely be deferred to the implementation plan.

Common decision gates:

- Where the responsibility boundary should live between modules, services, UI, API, persistence, or background workers.
- Whether to introduce a new abstraction, dependency, storage shape, queue, service, command, or protocol.
- Whether to migrate existing data/configuration or preserve backward compatibility.
- How to handle authentication, authorization, secrets, privacy, auditability, or destructive operations.
- Which failure behavior to prefer: strict rejection, graceful degradation, retry, partial success, or manual recovery.
- Which sequencing strategy to use when multiple milestones are possible.
- Which tradeoff to prefer among simplicity, robustness, performance, compatibility, and future flexibility.

## Document Shape

Every technical design should use this structure:

```markdown
# <Feature Name> Technical Design

**Goal:** <one sentence>

**Status:** Draft

---

## Context

<Current behavior, relevant constraints, existing files, and why the change is needed.>

## Non-Goals

- <What this design intentionally does not solve.>

## Proposed Architecture

<2-6 paragraphs describing the approach, the main boundaries, and why this fits the codebase.>

## Human Decisions

| Decision | Options Considered | Chosen Option | Rationale |
| --- | --- | --- | --- |
| <decision> | <option A; option B> | <choice> | <why> |

## Responsibilities

- `<module/file/component>` owns <responsibility>.
- `<module/file/component>` owns <responsibility>.
- Shared contract: <interface, event, schema, state shape, command, or API boundary>.

## Data Flow / Control Flow

1. <High-level flow step>
2. <High-level flow step>
3. <High-level flow step>

## Integration Points

- API/routes:
- Storage/state:
- Configuration:
- UI/CLI:
- External services:

## Sequencing

1. <Milestone-level implementation goal>
2. <Milestone-level implementation goal>
3. <Milestone-level implementation goal>

## Verification Strategy

- Unit:
- Integration:
- UI/manual:
- Regression:

## Risks And Tradeoffs

- <Risk or tradeoff> - <mitigation or decision>

## Open Questions

- <Question, or "None">

## Handoff To Implementation Plan

When this design is approved, use `$implementation-plans` to turn the sequencing into task-level work.
```

Remove empty integration categories that do not apply, except keep `Open Questions`.

## Self-Review

Before presenting the design:

- Check that every major requirement is addressed by architecture, responsibilities, or sequencing.
- Check that ownership boundaries are clear enough to become tasks later.
- Check that major design and architecture decisions were either confirmed with the human or explicitly listed in `Open Questions`.
- Check that the design does not contain task checkboxes or overly detailed implementation steps.
- Check that open questions are real blockers or meaningful uncertainties.
- Check that the verification strategy would catch the main failure modes.

Fix gaps inline before delivering the design.
