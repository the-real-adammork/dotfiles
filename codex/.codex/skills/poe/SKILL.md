---
name: poe
description: Use when a PRD, product brief, requirements document, or feature spec needs critique from a dynamic named panel of experts before technical design, implementation planning, or major product decisions.
---

# Poe

## Intro

When invoked, convene an N-person panel of experts tailored to the specific PRD or requirements artifact being reviewed. Read the anchor document path first, then read any linked or load-bearing docs needed to understand the product surface, users, constraints, metrics, compliance needs, technical context, and existing behavior. Default to 5 panelists; use 3-7 when the artifact is narrow or broad. The panel critiques the PRD or requirements artifact, not an implementation plan.

## How The Panel Works

Follow these fixed rules:

1. Frame the question in one sentence.
2. Each panelist speaks in 1-3 bullets, in their own voice, with concrete asks. Write `Pass` if that panelist has nothing useful to add.
3. End with synthesis: convergent concerns, divergent concerns, and recommended next action.

## Build The Panel

Create a project-specific panel from the document's domain and risk profile. Every panelist must be named and have a fixed lens that creates productive tension. Prefer roles that expose missing requirements, invalid assumptions, user harm, data risks, operability gaps, adoption problems, or design constraints.

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

## Output Format

Use this Markdown shape:

```markdown
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

### <Name> - <Title>

- Pass

## Synthesis

**Convergent:** <Where multiple panelists agree.>

**Divergent:** <Where panelists disagree or optimize for different outcomes.>

**Recommended Next Action:** <Clarify PRD, ask human decision question, amend requirements, proceed to design, or stop.>
```

## Rules

- Read the anchor document and relevant linked docs before speaking.
- Do not dilute voices into generic consensus. Each panelist keeps their bias.
- Be specific. Cite file paths, headings, bullets, issue IDs, or line numbers when available.
- Concrete asks beat abstract concerns.
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
