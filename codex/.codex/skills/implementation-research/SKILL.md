---
name: implementation-research
description: "Use when Codex needs repo-defined expert researcher agents to investigate a high-level product or engineering idea, critique the concept, and produce a detailed high-level implementation research plan before technical design or implementation planning."
---

# Implementation Research

Use repo-specific researcher agents to turn a high-level idea into a researched implementation direction. Researchers may critique and push back on the spec, but their job is to make the concept buildable, not to reject it casually.

## Inputs

Parse the user's request for:

- idea, concept, feature, requirement, PRD, issue, or design sketch;
- optional anchor document path;
- requested researcher agents by name, count, or domain;
- specific questions, risks, constraints, stack, users, integrations, deadlines, or non-goals.

If an anchor document is provided, read it first. Then read relevant repo context such as `AGENTS.md`, `docs/agents/researchers/*.md`, architecture docs, PRDs, route maps, API docs, existing plans, and nearby code only as needed.

## Researcher Selection

Use researcher profiles from:

```text
docs/agents/researchers/*.md
```

Select the smallest useful set of relevant researchers unless the user names agents or asks for a count. If no repo researcher profiles exist, stop and recommend creating them with `$expert-researcher` or `$expert-agent`; do not invent persistent researcher profiles inside this skill.

If multi-agent dispatch is available, delegate focused research prompts to selected researchers and ask each for findings, pushback, implementation implications, and open questions. If dispatch is unavailable, simulate the selected researcher lenses from their saved profiles and state that no separate agents were spawned.

## Research Standard

Researchers should:

- critique weak assumptions, missing requirements, risky scope, unclear users, unrealistic integrations, and hidden operational costs;
- still produce a viable high-level implementation direction when the idea is plausible;
- distinguish blockers from risks and preferences;
- use primary sources for current technical claims when external facts matter;
- cite repo paths, docs, code, or external sources used;
- avoid task-level implementation plans unless the user explicitly asks to continue into `$implementation-plans`.

## Output Artifact

Write the research report to:

```text
docs/research/implementation-research/YYYY-MM-DD-<idea-slug>.md
```

Create directories if needed.

Use this shape:

```markdown
# Implementation Research: <Idea>

## Summary

- <highest leverage finding>
- <main implementation direction>
- <largest unresolved risk>

## Inputs Reviewed

- `<path or source>` - <why it mattered>

## Researchers Used

| Researcher | Lens | Dispatch |
| --- | --- | --- |
| <name> | <domain/lens> | spawned/simulated |

## Pushback And Spec Critique

- **Issue:** <concern>
  **Why it matters:** <impact>
  **Adjustment:** <how to make the idea buildable>

## High-Level Implementation Direction

1. <major workstream or architecture move>
2. <major workstream or architecture move>
3. <major workstream or architecture move>

## Key Design Decisions

| Decision | Recommendation | Rationale | Open Question |
| --- | --- | --- | --- |
| <decision> | <recommendation> | <why> | <question or "None"> |

## Risks And Unknowns

- <risk, validation needed, or unresolved dependency>

## Suggested Next Step

<Proceed to PRD, technical design, implementation planning, prototype, spike, or stop.>
```

## Rules

- Use repo-defined researcher agents; do not create new researcher profiles unless the user invokes `$expert-researcher` or `$expert-agent`.
- Preserve researcher disagreement where it affects implementation choices.
- Pushback must include a constructive adjustment when possible.
- Keep the result high-level and research-backed. Do not write phase plans, worker task lists, or code.
- If the concept is too vague, produce a short clarification section and the best provisional implementation direction rather than blocking immediately.
- In chat, return the artifact path, the researchers used, the strongest pushback, and the suggested next step.
