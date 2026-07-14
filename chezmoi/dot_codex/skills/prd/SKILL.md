---
name: prd
description: Use when the user invokes $prd or asks to create a new product requirements document from raw requirements, notes, a brief, an issue, pasted context, or an early feature idea. Guides a question-led PRD creation workflow that defines product goals, users, workflows, frontend/backend touchpoints, system responsibilities, interactions, policies, data/state concepts, edge cases, and success metrics without choosing technologies or implementation details.
---

# PRD

## Overview

Create a new product requirements document from incomplete product input. This skill defines what is being built, who it serves, how the product behaves, which app surfaces exist, and how product areas interact; it does not decide how the system is technically implemented.

Save the PRD to:

```text
docs/architecture/PRD.md
```

## Inputs

Parse the user's request for a requirements source:

- File path to raw notes, requirements, a brief, a spec, or an issue export.
- Issue identifier or external artifact reference available through local tools.
- Pasted requirements in the conversation.
- A loose feature or product idea.

If no source is provided, ask for the source before proceeding. If the source path exists, read it before asking product questions. If the source links to other load-bearing local docs, read only the linked docs needed to understand product scope, users, workflows, and constraints.

## Workflow

### 1. Frame The Product

After reading the source, summarize the apparent product framing in 3-7 bullets:

- Product goal.
- Target users and roles.
- User problem or opportunity.
- Likely scope.
- Likely non-goals.
- Success signal.
- Assumptions that may be wrong.

Ask the user to confirm, correct, or add missing product context before drafting.

### 2. Identify Product Decision Gaps

Identify missing decisions that affect the PRD. Group them under the smallest useful set of headings:

- Users and roles.
- Primary workflows and lifecycle states.
- Frontend touchpoints, views, pages, modals, settings, forms, dashboards, or admin surfaces.
- Backend or system responsibilities, such as validation, matching, notification, ingestion, export, reporting, billing, permissions, audit, or orchestration.
- Cross-area interactions and handoffs.
- Permissions, policies, approvals, and operational rules.
- Data and state concepts, without schema, database, or API design.
- Edge cases, empty states, errors, and failure behavior.
- Rollout, migration, support, or operational considerations.
- Success metrics and acceptance signals.

Prioritize questions that block the PRD. Do not ask technology, framework, database, hosting, code architecture, vendor, or implementation-stack questions.

### 3. Ask One Product Question At A Time

Ask one concise product question at a time. Prefer multiple-choice options when they would help the user decide, but use open-ended questions when the answer space is genuinely unknown.

For each answer:

- Update the working product model.
- Mark resolved decisions.
- Ask the next highest-impact question.
- Stop questioning once the major product decisions are resolved or can be safely recorded as explicit assumptions.

If the product is too broad for one PRD, help split it into coherent product areas. Ask the user which area to PRD first, while recording the broader product context and dependencies.

### 4. Draft The PRD

Write `docs/architecture/PRD.md` using this structure, omitting only sections that are truly irrelevant:

```markdown
# Product Requirements Document

## Source Material

- `<source path, issue, pasted context, or "Conversation only">`

## Product Summary

<What is being built and why.>

## Goals

- <Product outcomes.>

## Non-Goals

- <Explicitly out-of-scope product behavior.>

## Users And Roles

- <Role>: <needs, permissions, responsibilities, and constraints.>

## Key User Journeys

### <Journey Name>

- Trigger:
- Main path:
- Completion state:
- Important variants:

## Product Surface Areas

### <Surface Area>

- Purpose:
- User-facing behavior:
- Included capabilities:
- Out-of-scope capabilities:
- Depends on:
- Feeds into:

## Frontend Touchpoints

- <View/page/modal/settings/admin area>: <what the user can see or do there.>

## Backend And System Responsibilities

- <System responsibility>: <product-level behavior and rules, not implementation design.>

## Cross-Area Interactions

- <Area A> -> <Area B>: <user action, system response, state change, handoff, or dependency.>

## Permissions And Policy Rules

- <Role/policy>: <allowed actions, denied actions, approval rules, visibility, retention, or governance behavior.>

## Data And State Concepts

- <Concept>: <meaning, lifecycle, ownership, and product-visible state.>

## Edge Cases And Failure States

- <Situation>: <expected product behavior, messaging, fallback, or escalation.>

## Rollout And Operations

- <Launch, migration, support, moderation, or operational expectation.>

## Success Metrics

- <Metric>: <what it proves.>

## Open Product Questions

- <Question, owner if known, and whether it blocks technical design.>

## Explicit Assumptions

- <Assumption recorded because it was safe enough to proceed.>

## Technical Design Boundary

This PRD intentionally avoids technology choices, implementation architecture, framework selection, database schema, API design, hosting, and code organization. Those decisions belong in the technical design.
```

## Self-Review

Before returning, review the PRD and fix issues inline:

1. Placeholder scan: remove unresolved TODOs except intentional open product questions.
2. Scope check: ensure the PRD says what is built and what is not built.
3. Actor check: every workflow has a user, role, or system actor.
4. Surface check: frontend touchpoints and backend/system responsibilities are both represented when relevant.
5. Interaction check: cross-area dependencies are explicit rather than implied.
6. Technical-boundary check: remove technology choices, schemas, APIs, framework decisions, and implementation architecture.
7. Consistency check: goals, journeys, surfaces, permissions, data concepts, and edge cases do not contradict each other.

## Return Shape

In chat, return:

- PRD path.
- Any blocking open product questions.
- Recommended next action: `$poe` for PRD critique, `$tdc` for technical design, or more PRD clarification if material product decisions remain.

## Companion Skills

- Use `$poe` after the PRD exists and the user wants a product/requirements critique.
- Use `$tdc` only after the PRD is accepted enough to begin technical design.
- Use `$implementation-plans` only after a technical design is accepted.
