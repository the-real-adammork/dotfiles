---
name: technical-design-cycle
description: Use when the user wants an orchestrated requirements-to-technical-design workflow with drafting, review, issue walkthrough, and optional handoff to implementation planning.
---

# Technical Design Cycle

Orchestrate a complete design loop from requirements to reviewed technical design. The parent agent owns the workflow state and user interaction. Subagents do bounded work only: one drafts the technical design, one reviews it against requirements.

## Start

Announce: "I'm using the technical-design-cycle skill to coordinate the design draft, review, and issue walkthrough."

## Bundled References

Load these files from this skill as needed:

- `references/drafting.md` before identifying design decision gates, drafting a technical design, or dispatching a design-drafting subagent.
- `references/review.md` before reviewing a technical design or dispatching a design-review subagent.
- Use `$secrets` before making design decisions about generated secrets, credentials, env files, deployment keys, database passwords, API tokens, or secret storage.

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
- Load `$secrets` and classify project posture before secret, environment, deployment, or credential decisions.
- Identify major design decisions that need human input before drafting.
- Ask those human decision questions one at a time.
- Save or patch the technical design in the real workspace.
- Dispatch subagents only for bounded draft/review work.
- Review subagent output before presenting it to the user.
- Walk the user through every review finding and record the disposition.

Subagents must not own the overall workflow, continue into implementation planning, commit changes, or decide human-facing design tradeoffs without parent review.

## Stable Subagent Names

Every dispatched subagent must have a stable, human-readable `agent_name` that maps to the bounded work it is performing. The native host may return its own agent id or nickname instead of displaying the requested `agent_name`. Put `agent_name` at the top of the spawned prompt, and immediately record the mapping from stable name to returned host agent id/nickname in a parent-owned Agent Directory.

Use this parent-owned Agent Directory format in notes or the cycle handoff:

```markdown
## Agent Directory

| Stable Agent Name | Host Agent ID/Nickname | Role | Status | Notes |
| --- | --- | --- | --- | --- |
```

If the user may need to attach follow-up input to a subagent, tell them the mapping immediately after spawn. The host agent id/nickname is the attachment target; `agent_name` is the stable human label.

Use this naming pattern:

```text
design-drafter: <feature-slug> / <requirements id>
design-reviewer: <feature-slug> / <requirements id>
replacement-design-drafter: <feature-slug> / resume
replacement-design-reviewer: <feature-slug> / resume
```

Keep names short enough to scan in logs, but specific enough that the user can identify which host agent id/nickname maps to the intended subagent.

## Context Budget And Handoff Rules

Keep files as the source of truth. Pass document paths to subagents by default; do not paste full requirements, designs, or reviews into parent context unless the user asks.

- Parent passes concise repo context: relevant file paths, commands, constraints, and decisions.
- Drafting subagent returns the design artifact path plus a short summary, open questions, and blockers.
- Review subagent writes large reviews to a file and returns only the review path, top findings, counts, and blocking status.
- Parent reads targeted file sections only when patching, resolving a finding, or answering a user question.
- If a subagent estimates it is at or above roughly 70% context usage, it must save a handoff under `docs/handoffs/` and return only the handoff path plus current artifact paths. Parent must dispatch a replacement from that handoff, not from chat history, using `replacement-design-drafter: <feature-slug> / resume` or `replacement-design-reviewer: <feature-slug> / resume` as appropriate.

## Phase 1: Requirements And Decision Gates

1. Read the requirements source.
2. Load `references/drafting.md`.
3. Classify the project posture using the drafting reference. If the user has said the work is a side project, demo, prototype, or greenfield app without existing users, default to `side-project/greenfield`.
4. Identify likely architecture/design decision gates using the drafting reference.
5. For each major decision that cannot be safely inferred:
   - Present 2-3 options.
   - Recommend one.
   - Ask one focused question.
   - Wait for the user's answer.
6. Keep a short `Human Decisions` list to pass into the drafting subagent.

Skip questions for obvious local conventions or choices that can safely be deferred to `$implementation-plans`.

## Phase 2: Draft Technical Design Subagent

Spawn exactly one drafting subagent after the decision gates are resolved. Use `agent_name` in the format `design-drafter: <feature-slug> / <requirements id>`.

Use a prompt with this structure:

```text
agent_name: design-drafter: <feature-slug> / <requirements id>

Use $technical-design-cycle and load `references/drafting.md` to draft a technical design.

Requirements source:
<path>

Human decisions already made:
<decision list>

Project posture and secret policy:
<side-project/greenfield | internal/demo | production/customer, plus which secrets agents may generate vs must escalate>

Repository context:
<relevant files, commands, constraints, and patterns discovered by parent>

Save the complete Markdown technical design to:
<target design path>

Return only: design path, 3-5 bullet summary, Open Questions, blockers, and whether any design decision needs human input. Do not commit. Do not create an implementation plan. Do not ask the user questions; put unresolved blockers in Open Questions.

If context pressure reaches roughly 70%, save a handoff under `docs/handoffs/` and return only the handoff path plus current artifact paths.
```

The parent agent reviews the draft and fixes obvious formatting or instruction violations.

If the draft contains `Open Questions` that affect architecture, product behavior, data shape, migration risk, security/privacy posture, operational complexity, future extensibility, or requirement completeness, stop before review. Ask the human to resolve those questions, patch or rerun the design draft, and only then continue to review using `references/review.md`.

## Phase 3: Review Subagent

Spawn exactly one review subagent after the design draft is saved. Use `agent_name` in the format `design-reviewer: <feature-slug> / <requirements id>`.

Use a prompt with this structure:

```text
agent_name: design-reviewer: <feature-slug> / <requirements id>

Use $technical-design-cycle and load `references/review.md` to review the technical design against the requirements.

Requirements document:
<path>

Technical design document:
<path>

If the review has more than about 20 requirement units or is otherwise large, write the full review to `docs/reviews/YYYY-MM-DD-<feature>-technical-design-review.md` and return only the review path, top findings, counts, and blocking status.

Otherwise return the required Findings, Traceability Review, Summary, and Recommended Design Changes sections. Do not modify files. Do not continue into implementation planning.

If context pressure reaches roughly 70%, save a handoff under `docs/handoffs/` and return only the handoff path plus current artifact paths.
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

After patching accepted/revised findings, ask whether to rerun the review using `references/review.md`.

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
