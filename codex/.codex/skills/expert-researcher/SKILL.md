---
name: expert-researcher
description: "Use when the user wants to create repo-specific expert researcher profiles from a prompt or document, including recommending top-field research agents and requiring user approval before writing researcher files."
---

# Expert Researcher

Create repo-specific expert researcher profiles for future use. This is the research-focused companion to `$expert-agent`.

## Inputs

Parse the user's request for:

- Researcher count: phrases like `3 researchers`, `two experts`, or `recommend 5 researchers`. Return exactly the requested count. If no count is provided, choose the smallest useful count and clearly state it.
- Prompt: the user's description of the research need.
- Anchor document: an optional file path, PRD, plan, design, issue, or notes file. Read it before proposing researchers.
- Requested constraints: domain, seniority, exclusions, source standards, risk areas, names, or output format.

Default every proposed researcher to be at the top of their field with 10-15 years of relevant experience unless the user asks for a different seniority.

## Storage

Write only after approval:

```text
docs/agents/researchers/<researcher-slug>.md
```

Do not store researcher profiles under `docs/agents/workers/`.

## Build The Proposed Researchers

Each researcher must be specific to the current repo and requested research surface. Prefer narrow, high-leverage expertise over generic seniority.

For each proposed researcher define:

- Name and title.
- Storage path.
- Core expertise: the field where this researcher is top-tier.
- Experience model: what 10-15 years of elite experience means for this domain.
- Best used for: concrete research questions this researcher should answer.
- Should not own: boundaries that keep them out of implementation routing.
- Evidence standards: acceptable sources, verification expectations, and uncertainty handling.
- Expected outputs: decision brief, source map, options analysis, risk register, recommendation memo, or other concrete artifact.

## Approval Gate

Before writing files, propose the exact roster and wait for user approval.

Use this shape:

```markdown
## Proposed Expert Researchers

**Anchor Document:** `<path or "None">`
**Requested Count:** `<number or "Not specified; chosen count: N">`
**Prompt:** <one-sentence summary>

| Researcher | Storage Path | Core Expertise | Best Used For |
| --- | --- | --- | --- |
| <Name> - <Title> | `<path>` | <expertise> | <questions/tasks> |

Approve this researcher roster, or tell me which researchers to add, remove, rename, split, merge, or revise.
```

Do not write `docs/agents/researchers/...` files until the user approves the roster. If the user asks for changes, revise the proposal and ask for approval again when the requested changes are ambiguous. If the changes are explicit, apply them and proceed after approval.

## Researcher File Template

After approval, write each researcher profile using this Markdown shape:

```markdown
# <Name> - <Title>

**Kind:** researcher
**Agent ID:** researchers/<researcher-slug>
**Use When:** <one sentence>
**Do Not Use When:** <one sentence>

## Expertise

<What makes this researcher top-tier, including the default 10-15 years of relevant experience.>

## Best Used For

- <research question>
- <research question>
- <research question>

## Evidence Standards

- <source standard>
- <verification standard>
- <uncertainty standard>

## Inputs To Provide

- <input>
- <input>

## Outputs

- <artifact or result>
- <artifact or result>

## Boundaries

- <boundary>
- <boundary>
```

## Rules

- Always return exactly the number of researchers requested, unless the user changes the count.
- If no count is provided, choose a count and say that it was inferred.
- Always require approval before adding profiles to the project.
- Read the anchor document before recommending researchers from a document.
- Keep researchers out of `docs/agents/workers/`.
- Make researchers repo-specific; avoid generic analyst profiles.
- Do not overwrite existing researcher profiles without explicitly saying which files would be replaced and getting approval.
- If an existing profile is close, recommend updating it instead of creating a duplicate.
- Do not start the research work; this skill only creates reusable researcher profiles.
