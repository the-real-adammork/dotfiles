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
- Use `$poe` after reading a PRD, product brief, requirements document, or feature spec and before locking design decision gates.
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
- Run `$poe` for substantial PRDs or requirements artifacts and convert material critique into PRD clarifications or design decision gates.
- Load `$secrets` and classify project posture before secret, environment, deployment, or credential decisions.
- Identify major design decisions that need human input before drafting.
- Ask those human decision questions one at a time.
- Save or patch the technical design in the real workspace.
- Dispatch subagents only for bounded draft/review work.
- Review subagent output before presenting it to the user.
- Walk the user through every review finding and record the disposition.
- After design acceptance, ask whether to define a small approved specialist implementation-agent roster before implementation planning.

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

## Phase 1: Requirements, PRD Panel, And Decision Gates

1. Read the requirements source.
2. Inspect enough of the repo and linked docs to understand relevant constraints, patterns, and product context.
3. If the source is an existing PRD, product brief, requirements document, or feature spec, use `$poe` to generate a PRD-specific panel of experts and critique the artifact before identifying final design gates. Skip `$poe` only when the artifact does not exist, the request is a single factual question, or the domain is clearly wrong for product/requirements critique.
4. Record a short `POE Findings` list:
   - convergent concerns;
   - divergent concerns;
   - recommended next action;
   - any concrete PRD clarifications or requirement edits needed before design.
5. If `$poe` recommends clarifying or amending the PRD before design, ask the human those questions before drafting. Treat material unresolved items as blockers or `Open Questions`.
6. Load `references/drafting.md`.
7. Classify the project posture using the drafting reference. If the user has said the work is a side project, demo, prototype, or greenfield app without existing users, default to `side-project/greenfield`.
8. Identify likely architecture/design decision gates using the drafting reference and the `POE Findings`.
9. For each major decision that cannot be safely inferred:
   - Present 2-3 options.
   - Recommend one.
   - Ask one focused question.
   - Wait for the user's answer.
10. Keep a short `Human Decisions` list and `POE Findings` list to pass into the drafting subagent.

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

Panel of experts critique:
<POE Findings list, or "Not run: <reason>">

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

## Phase 6: Specialist Implementation-Agent Gate

After the technical design is accepted and before offering `$implementation-plans`, ask whether the user wants to define specialist implementation agents for the upcoming work.

General-purpose implementation workers are always available and require no approval. Specialist implementation agents are optional routing hints for worker dispatch, not required capacity.

If suggesting specialists:

- suggest at most 3;
- make them reusable across multiple tasks or phases, not one-off task personas;
- define each as an implementation worker role, not a skill;
- include name/title, best-fit work, scope boundaries, and when to fall back to a general-purpose worker;
- ask the user to approve, reject, or revise each suggestion.

Record the approved roster in the design handoff as:

```markdown
## Approved Specialist Implementation Agents

General-purpose implementation workers are always available.

| Agent | Best-Fit Work | Not Allowed To Own | Fallback Rule |
| --- | --- | --- | --- |
| <name/title> | <task/lane types> | <boundaries> | Use a general-purpose worker when <condition>. |
```

If no specialists are approved, record:

```markdown
## Approved Specialist Implementation Agents

General-purpose implementation workers are always available. No specialist implementation agents approved for this design.
```

Do not create local skill documents for these agents. Do not allow later planning or execution steps to invent additional specialists for the same run.

## Phase 7: Handoff

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
- Confirm `$poe` was run for substantial PRDs/requirements artifacts, or record why it was skipped.
- Confirm every review finding has a recorded disposition.
- Confirm accepted/revised findings were applied to the design.
- Confirm unresolved issues are listed under `Open Questions`.
- Confirm the approved specialist implementation-agent roster is recorded, even if it says no specialists were approved.
- Confirm no implementation task checklist was created unless the user explicitly chose implementation planning.
