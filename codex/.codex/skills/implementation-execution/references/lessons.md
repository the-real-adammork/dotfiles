# Lessons

Use lessons to prevent future agents from rediscovering the same repo-specific failure mode. The phase owner decides what becomes a lesson.

## Roles

- Workers may return `lesson_candidate` in worker result YAML.
- Reviewers may return `lesson_candidate` when repeated review/fix failures reveal a durable rule.
- Phase owner promotes proven candidates into repo lessons.
- Supervisor verifies promoted lesson paths are recorded in phase state and handoff/acceptance artifacts when relevant.

## Promotion Criteria

Promote only when all are true:

- The problem is likely to recur across tasks, phases, or future agents.
- The fix is proven by implementation, tests, review, or QA artifacts.
- The lesson is repo-specific or workflow-specific enough to change future behavior.
- Existing docs do not already cover it.
- The lesson can be explained without secrets, private tokens, long logs, or chat history.

Do not promote:

- one-off typos;
- obvious coding mistakes;
- speculative preferences;
- product decisions that belong in requirements;
- implementation details that only affect the current task;
- large postmortems.

## Locations

Use the existing lesson convention:

```text
docs/lessons/YYYY-MM-DD-<slug>.md
AGENTS.md
```

Add only a concise pointer to `AGENTS.md`, not the full lesson.

## Lesson Format

```markdown
# <Lesson Title>

## Problem

Describe the recurring failure mode and how it shows up.

## Correct Approach

Describe the durable fix or decision rule.

## When To Apply

- <situation>

## Steps

1. <action>
2. <verification or fallback>

## Example

<minimal command, prompt, config, or code pattern when useful>

## Related Files

- `<path>`
```

## AGENTS.md Pointer

Keep the pointer short:

```markdown
## Lessons

- <Short title>: <one-sentence rule>. See [docs/lessons/YYYY-MM-DD-<slug>.md](docs/lessons/YYYY-MM-DD-<slug>.md).
```

## State Updates

Record promoted lessons in `phase.yaml`:

```yaml
lessons:
  - path: "docs/lessons/YYYY-MM-DD-slug.md"
    source: "Task 4 review loop"
    applied_to_agents_md: true
```

Also mention lesson paths in the phase acceptance packet when the lesson affects later phases.
