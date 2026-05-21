---
name: technical-design-cycle
description: Use when the user wants an orchestrated requirements-to-technical-design workflow with drafting, review, issue walkthrough, and optional handoff to implementation planning.
---

# Technical Design Cycle

Orchestrate a complete design loop from requirements to reviewed technical design. The parent agent owns the workflow state and user interaction. Subagents do bounded work only: one drafts the technical design, one reviews it against requirements.

## Start

Announce: "I'm using the technical-design-cycle skill to coordinate the design draft, review, and issue walkthrough."

Inputs:

- Requirements document path, issue, PRD, spec, or approved brief.
- Optional target design path. Default:

```text
docs/designs/YYYY-MM-DD-<short-feature-name>.md
```

If the requirements source is missing and cannot be inferred, ask for it before proceeding.

## Parent-Owned Responsibilities

The parent agent must:

- Read the requirements source and inspect the repo enough to understand relevant existing patterns.
- Identify major design decisions that need human input before drafting.
- Ask those human decision questions one at a time.
- Save or patch the technical design in the real workspace.
- Dispatch subagents only for bounded draft/review work.
- Review subagent output before presenting it to the user.
- Walk the user through every review finding and record the disposition.

Subagents must not own the overall workflow, continue into implementation planning, commit changes, or decide human-facing design tradeoffs without parent review.

## Phase 1: Requirements And Decision Gates

1. Read the requirements source.
2. Identify likely architecture/design decision gates using `$technical-design` rules.
3. For each major decision that cannot be safely inferred:
   - Present 2-3 options.
   - Recommend one.
   - Ask one focused question.
   - Wait for the user's answer.
4. Keep a short `Human Decisions` list to pass into the drafting subagent.

Skip questions for obvious local conventions or choices that can safely be deferred to `$implementation-plans`.

## Phase 2: Draft Technical Design Subagent

Spawn exactly one drafting subagent after the decision gates are resolved.

Use a prompt with this structure:

```text
Use $technical-design to draft a technical design.

Requirements source:
<path or pasted requirements>

Human decisions already made:
<decision list>

Repository context:
<relevant files, commands, constraints, and patterns discovered by parent>

Output only the complete Markdown technical design. Do not commit. Do not create an implementation plan. Do not ask the user questions; put unresolved blockers in Open Questions.
```

The parent agent reviews the draft, fixes obvious formatting or instruction violations, then saves it to the target design path.

## Phase 3: Review Subagent

Spawn exactly one review subagent after the design draft is saved.

Use a prompt with this structure:

```text
Use $technical-design-review to review the technical design against the requirements.

Requirements document:
<path>

Technical design document:
<path>

Return the required Findings, Traceability Review, Summary, and Recommended Design Changes sections. Do not modify files. Do not continue into implementation planning.
```

The parent agent reviews the review output for completeness before presenting findings to the user.

## Phase 4: Human Walkthrough Of Findings

Walk through every `High`, `Medium`, and `Low` finding with the user. For each finding, present:

```text
Finding N: <severity> - <short issue>
Requirement: <requirement summary>
Design gap: <gap or inconsistency>
Recommended design edit: <edit>

Decision needed: accept, revise, reject as non-issue, defer, or clarify requirement?
```

Record each disposition:

- `Accepted` - patch the technical design accordingly.
- `Revised` - patch the technical design using the user's requested direction.
- `Rejected` - do not patch; record why if useful.
- `Deferred` - add or update an `Open Questions` item.
- `Clarify Requirement` - ask the needed question before deciding.

Patch the design only for accepted or revised findings.

## Phase 5: Optional Review Loop

After patching accepted/revised findings, ask whether to rerun `$technical-design-review`.

Rerun when:

- Any `High` or `Medium` finding was patched.
- Requirements were clarified.
- The user asks for another pass.

If rerun produces new findings, repeat Phase 4.

## Phase 6: Handoff

When the design is accepted, offer:

```text
Technical design accepted at `<path>`.

Next options:
1. Use $implementation-plans to create the detailed task plan.
2. Stop here and keep the design as the handoff artifact.
```

Do not automatically start `$implementation-plans` unless the user chooses that option.

## Self-Review

Before declaring the cycle complete:

- Confirm the design file exists at the stated path.
- Confirm every review finding has a recorded disposition.
- Confirm accepted/revised findings were applied to the design.
- Confirm unresolved issues are listed under `Open Questions`.
- Confirm no implementation task checklist was created unless the user explicitly chose implementation planning.
