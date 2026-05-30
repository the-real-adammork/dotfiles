---
name: expert-agent
description: "Use when the user wants to create repo-specific expert researcher or implementation-worker agent profiles from a prompt or document, including recommending specialist agents, separating research agents from worker agents, and requiring user approval before writing agent files."
---

# Expert Agent

Create repo-specific expert agent profiles for future use. This skill proposes agents first, waits for user approval, then writes the approved profiles into the target repo.

## Inputs

Parse the user's request for:

- Agent kind: `researcher`, `worker`, `implementation agent`, or mixed. If unspecified, infer from the task; use `researcher` for discovery, analysis, market, domain, security, policy, architecture, or product-research work, and `worker` for implementation, fixer, reviewer, testing, migration, infra, or build work.
- Agent count: phrases like `3 researchers`, `two implementation agents`, or `recommend 5 agents`. Return exactly the requested count. If no count is provided, choose the smallest useful count and clearly state it.
- Prompt: the user's description of the agent need.
- Anchor document: an optional file path, PRD, plan, design, issue, or notes file. Read it before proposing agents.
- Requested constraints: seniority, domain, exclusions, tools, stack, risk areas, role names, output format, or storage preference.

Default every proposed agent to be at the top of their field with 10-15 years of relevant experience unless the user asks for a different seniority.

## Storage

Write only after approval.

- Research agents go under `docs/agents/researchers/<agent-slug>.md`.
- Implementation, fixer, reviewer, testing, migration, infra, or build agents go under `docs/agents/workers/<agent-slug>.md`.
- Mixed requests may create files in both directories, but keep the two categories separate.

Do not store research agents in the workers directory. `implementation-plans` may later reference worker agents for implementation routing, so worker profiles must be implementation-ready.

## Build The Proposed Agents

Each agent must be specific to the current repo and requested work. Prefer narrow, high-leverage expertise over generic seniority.

For each proposed agent define:

- Name and title.
- Kind: `researcher` or `worker`.
- Storage path.
- Core expertise: the field where this agent is top-tier.
- Experience model: what 10-15 years of elite experience means for this domain.
- Best used for: concrete tasks this agent should own.
- Should not own: boundaries that keep routing clean.
- Operating standards: how the agent decides, investigates, implements, verifies, or reports.
- Expected outputs: what artifact or result the agent should produce.

For worker agents, also include:

- Implementation responsibilities.
- Test and verification responsibilities.
- Handoff contract for implementation plans and phase orchestrators.

For research agents, also include:

- Research questions they are best suited to answer.
- Evidence standards and source-quality expectations.
- Decision support output shape.

## Approval Gate

Before writing files, propose the exact roster and wait for user approval.

Use this shape:

```markdown
## Proposed Expert Agents

**Anchor Document:** `<path or "None">`
**Requested Count:** `<number or "Not specified; chosen count: N">`
**Requested Kind:** `<researcher|worker|mixed|inferred>`
**Prompt:** <one-sentence summary>

| Agent | Kind | Storage Path | Core Expertise | Best Used For |
| --- | --- | --- | --- | --- |
| <Name> - <Title> | <researcher|worker> | `<path>` | <expertise> | <tasks> |

Approve this roster, or tell me which agents to add, remove, rename, split, merge, or revise.
```

Do not write `docs/agents/...` files until the user approves the roster. If the user asks for changes, revise the proposal and ask for approval again when the requested changes are ambiguous. If the changes are explicit, apply them and proceed after approval.

## Agent File Template

After approval, write each agent profile using this Markdown shape:

```markdown
# <Name> - <Title>

**Kind:** <researcher|worker>
**Agent ID:** <researchers|workers>/<agent-slug>
**Use When:** <one sentence>
**Do Not Use When:** <one sentence>

## Expertise

<What makes this agent top-tier, including the default 10-15 years of relevant experience.>

## Best Used For

- <task>
- <task>
- <task>

## Operating Standards

- <standard>
- <standard>
- <standard>

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

Add worker-only sections when applicable:

```markdown
## Implementation Contract

- <responsibility>
- <test or verification expectation>
- <handoff expectation>
```

Add researcher-only sections when applicable:

```markdown
## Research Contract

- <research question type>
- <evidence standard>
- <decision-support output>
```

## Rules

- Always return exactly the number of agents or researchers requested, unless the user changes the count.
- If no count is provided, choose a count and say that it was inferred.
- Always require approval before adding profiles to the project.
- Read the anchor document before recommending agents from a document.
- Keep research and worker agents in separate directories.
- Make agents repo-specific; avoid generic "senior engineer" profiles.
- Do not overwrite existing agent profiles without explicitly saying which files would be replaced and getting approval.
- If an existing profile is close, recommend updating it instead of creating a duplicate.
- Do not start research or implementation work; this skill only creates reusable agent profiles.
