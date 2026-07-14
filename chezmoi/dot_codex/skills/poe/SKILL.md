---
name: poe
description: Use when a PRD, product brief, requirements document, or feature spec needs critique from a dynamic named panel of a requested size before technical design, implementation planning, or major product decisions.
---

# Poe

## Intro

When invoked, convene an N-person panel of experts tailored to the specific PRD or requirements artifact being reviewed. This is a standalone critique workflow; do not assume it is part of `$technical-design-cycle` unless the user explicitly invokes it. Read the anchor document path first, then read any linked or load-bearing docs needed to understand the product surface, users, constraints, metrics, compliance needs, technical context, and existing behavior. The panel critiques the PRD or requirements artifact, not an implementation plan.

Save the panel artifact to:

```text
docs/architecture/PANEL_OF_EXPERTS.md
```

## Invocation Inputs

Parse the user's invocation for:

- Anchor document: the PRD, requirements document, product brief, feature spec, or issue reference to critique.
- Expert count: phrases like `$poe 3 experts`, `use $poe with 4 panelists`, or `2 experts`. If provided, propose exactly that many experts after applying the cap below.
- Expert requirements: requested lenses, roles, exclusions, names, seniority, domain backgrounds, or risk areas, such as `include a privacy reviewer`, `one teacher and one growth PM`, or `no generic product manager`.

If no expert count is provided, choose the smallest useful panel size from 3-5 based on artifact breadth and risk. Use 3 for narrow or early PRDs, 4 for moderate cross-functional PRDs, and 5 only for broad or high-risk PRDs. Never silently default to 5.

If the user requests more than 5 experts, cap the proposed panel at 5 and say which requested lenses were combined or omitted. If the requested count conflicts with the requested expert requirements, propose the best fit and call out the tradeoff in the approval request.

## How The Panel Works

Follow these fixed rules:

1. Frame the question in one sentence.
2. Each panelist speaks in 1-3 bullets, in their own voice, with concrete asks. Write `Pass` if that panelist has nothing useful to add.
3. Each panelist asks 0-2 human-facing questions when their critique depends on a product, requirement, risk, or design decision that cannot be safely inferred.
4. End with synthesis: convergent concerns, divergent concerns, and recommended next action.

## Build The Panel

Create a project-specific panel from the document's domain, risk profile, requested expert count, and requested expert requirements. Every panelist must be named and have a fixed lens that creates productive tension. Prefer roles that expose missing requirements, invalid assumptions, user harm, data risks, operability gaps, adoption problems, or design constraints.

The panel must match the requested count when one is provided, up to the 5-expert cap. If no count is provided, choose 3-5 experts using the sizing rule above. If more lenses seem useful than the selected panel size allows, combine adjacent lenses or choose the highest-risk lenses for this PRD.

For each panelist, define:

### <Name> - <Title>

- Owns: <what they are the authority on>
- Reflexively pushes back on: <their automatic red flags>
- Reference frame: <one litmus-test question they always ask>

Good panelist types include:

- Product strategist for goal, scope, non-goals, metrics, and sequencing.
- Domain operator or end user for real workflow fit and edge cases.
- Senior engineer or architect for feasibility, integration boundaries, and hidden complexity.
- Security, privacy, compliance, or abuse reviewer for risk and policy exposure.
- Data, analytics, or experimentation lead for instrumentation and success criteria.
- Design, accessibility, or content reviewer for interaction clarity and inclusive usability.
- Support, operations, or reliability lead for failure modes, rollout, and maintainability.

Avoid generic balanced committees. The panel should be opinionated and relevant to this PRD.

Do not collapse panelists into one combined summary. The artifact must preserve distinct named voices and questions.

## Panel Approval Gate

Before writing critiques, questions, synthesis, or the final artifact, propose the panel to the human and wait for approval.

Use this shape:

```markdown
## Proposed Panel Of Experts

**Anchor Document:** `<requirements path>`
**Panel Question:** <one sentence framing the critique>
**Requested Expert Count:** <number or "Not specified; chosen count: N">
**Requested Expert Requirements:** <requirements or "None">

| Panelist | Owns | Reflexively Pushes Back On | Reference Frame |
| --- | --- | --- | --- |
| <Name> - <Title> | <authority> | <red flags> | <litmus question> |

Approve this panel, or tell me which panelists to add, remove, rename, or revise.
```

After approval, use the approved panel exactly unless the human explicitly allows changes. If the human revises the panel, incorporate the revisions and confirm the final panel before critique when the changes are ambiguous.

## Output Format

Use this Markdown shape:

```markdown
# Panel Of Experts

**Anchor Document:** `<requirements path>`
**Load-Bearing Context Read:** `<paths or "None">`
**Artifact:** `docs/architecture/PANEL_OF_EXPERTS.md`
**Expert Count:** <N>
**Requested Expert Requirements:** <requirements or "None">

## Panel Question

<One sentence framing the critique.>

## Panel

### <Name> - <Title>

- Owns: <authority>
- Reflexively pushes back on: <red flags>
- Reference frame: <litmus question>

## Critique

### <Name> - <Title>

- <Concrete critique or ask with source reference>
- <Concrete critique or ask with source reference>

Questions:
- <Question for the human, or "None">

### <Name> - <Title>

- Pass

Questions:
- None

## Questions For Human

| Panelist | Question | Why It Matters | Blocks Drafting? |
| --- | --- | --- | --- |
| <Name> | <question> | <decision/gap it resolves> | Yes/No |

## Synthesis

**Convergent:** <Where multiple panelists agree.>

**Divergent:** <Where panelists disagree or optimize for different outcomes.>

**Recommended Next Action:** <Clarify PRD, ask human decision question, amend requirements, proceed to design, or stop.>
```

## Rules

- Read the anchor document and relevant linked docs before speaking.
- Propose the panel first and wait for human approval before writing critiques, questions, synthesis, or `docs/architecture/PANEL_OF_EXPERTS.md`.
- Honor the requested expert count when provided, subject to the 5-expert cap.
- Do not hardcode the panel to 5 experts.
- Do not propose more than 5 experts.
- Surface any conflict between requested expert count and requested expert requirements before critique.
- Do not dilute voices into generic consensus. Each panelist keeps their bias.
- Be specific. Cite file paths, headings, bullets, issue IDs, or line numbers when available.
- Concrete asks beat abstract concerns.
- Write the full panel artifact to `docs/architecture/PANEL_OF_EXPERTS.md` before returning.
- In chat, return only the artifact path, blocking questions, and recommended next action.
- Questions must be phrased for the human to answer, not as rhetorical critique.
- Partial panels are fine when only some lenses are relevant.
- No panelist is the boss. The synthesis chooses the next action, not a winner.
- Do not invent external facts. If current market, legal, pricing, or policy facts matter, verify them before using them.
- No emojis.

## When Not To Run

Do not run this skill when:

- The user asks a single factual question.
- The user explicitly wants one reviewer voice only.
- The artifact to critique does not exist yet.
- The request is to critique code, a technical design, or an implementation plan rather than a PRD or requirements artifact.
- The domain is wrong for product/requirements critique.

## Companion Skills

- Use `$technical-design-cycle` after the panel has surfaced PRD gaps and the user has resolved material questions.
- Use `$implementation-plans` only after the technical design is accepted.
- Use `$secrets` if the PRD involves credentials, auth, deployment keys, private data, tokens, or secret storage.
