---
name: lesson
description: Use when the user wants to save, capture, document, or codify a recurring problem and its proven solution so future agents can avoid repeating the same mistake. Updates repo lesson docs under docs/lessons and keeps AGENTS.md lesson pointers concise.
---

# Lesson

Capture a persistent problem, the solution that worked, and the rule future agents should follow.

## When To Use

Use this skill when the user says a problem keeps recurring, asks to save a lesson, wants a durable workaround documented, or asks to update `AGENTS.md` with a lesson pointer.

## Output Locations

- Full lesson: `docs/lessons/YYYY-MM-DD-<slug>.md`
- Short pointer: root `AGENTS.md` under `## Lessons`

If the repo uses a different agent instruction file, update the most relevant root-level file and mention the path.

## Workflow

1. Identify the recurring problem and the proven solution from the current work, user notes, logs, or diffs.
2. Choose a short slug in lowercase hyphen-case.
3. Create or update one full lesson file in `docs/lessons/`.
4. Add or update one concise bullet in `AGENTS.md`.
5. Keep the `AGENTS.md` pointer to one or two sentences plus a relative link to the lesson.
6. Validate that links and paths are correct.

## Full Lesson Format

```markdown
# <Lesson Title>

## Problem

Describe the recurring failure mode and how it shows up.

## Correct Approach

Describe the durable fix or decision rule.

## When To Apply

List the situations where agents should remember this lesson.

## Steps

1. Concrete action.
2. Concrete action.
3. Verification or fallback.

## Example

Show a minimal command, prompt, config, or code pattern when useful.

## Related Files

- `<path>`
```

Keep lessons practical and specific. Do not write a general essay.

## AGENTS.md Pointer Format

Use this compact form:

```markdown
## Lessons

- <Short title>: <one-sentence rule>. See [docs/lessons/YYYY-MM-DD-<slug>.md](docs/lessons/YYYY-MM-DD-<slug>.md).
```

If `## Lessons` already exists, append or update the matching bullet. Do not paste the full lesson into `AGENTS.md`.

## Quality Bar

- The lesson must name the exact trap future agents should avoid.
- The solution must be actionable without reading chat history.
- The pointer must stay short enough that `AGENTS.md` remains lightweight.
- Do not include secrets, tokens, private URLs, or long logs.
- If the lesson involves config or scripts, link to the relevant files instead of duplicating them.
