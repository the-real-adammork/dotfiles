---
name: write-approved-lessons
description: "Use when session lesson candidates have already been approved by the human and need to be written or updated in a repo's docs/lessons directory and summarized under AGENTS.md Lessons."
---

# Write Approved Lessons

Write only human-approved lesson candidates. This skill turns approved lesson decisions into durable repo guidance without re-litigating rejected candidates.

## Preconditions

Before editing files, confirm each lesson has explicit human approval and includes:

- title;
- problem summary;
- solution or playbook summary;
- destination path or existing lesson path;
- whether it is a new lesson or an update.

If approval is missing or ambiguous, stop and ask for approval. Do not write provisional lessons.

## New Lesson Files

Create each approved new lesson at:

```text
docs/lessons/<lesson-slug>.md
```

Use a stable, descriptive slug. Include a date prefix only if the repo's existing lesson files use date prefixes.

Use this structure:

```markdown
# <Lesson Title>

## Problem
<2-3 sentences describing the failed path, unexpected condition, and why future agents may repeat it.>

## Solution
<2-3 sentences describing the working approach and the key decision that avoided the detour.>

## Playbook
- <Concrete step future agents should take first.>
- <Concrete verification or command, if applicable.>
- <Fallback or escalation rule, if applicable.>

## Evidence
- `<path or session artifact>` - <brief reason this lesson exists>
```

Keep lessons short and operational. Avoid narratives, blame, broad philosophy, and transcript dumps.

## Updating Existing Lessons

For approved updates, edit the existing `docs/lessons/*.md` file instead of creating a duplicate.

Prefer precise changes that would have prevented the repeated problem:

- clarify the triggering condition;
- add the missing command, check, or fallback;
- strengthen the playbook step that was skipped or misunderstood;
- add evidence that explains why the update is needed.

## AGENTS.md Entry

After writing or updating each lesson, update the nearest root `AGENTS.md` `## Lessons` section.

Use this shape for each lesson:

```markdown
### <Lesson Title>

<2-3 sentences describing the problem in terms an agent can recognize before repeating it.>

See [<Lesson Title>](docs/lessons/<lesson-slug>.md) for the solution/playbook.
```

If `## Lessons` already uses a different local convention, preserve nearby content but add the approved lesson in this heading-based format unless the human explicitly requested otherwise.

For an existing lesson update, update its `AGENTS.md` entry so the short problem description matches the improved lesson.

## Safety

- Do not edit files outside `docs/lessons/` and the nearest `AGENTS.md` unless the human explicitly approved that scope.
- Do not include secrets, tokens, private paths with credentials, or pasted logs.
- Do not create a lesson for rejected candidates.
- Do not overwrite unrelated lesson content.

## Verification

After editing:

1. Re-read each changed lesson file.
2. Re-read the `AGENTS.md` `## Lessons` section.
3. Confirm every approved lesson has exactly one doc and one `AGENTS.md` pointer.
4. Run the repo's relevant markdown or skill validation if available.
5. Report changed paths and any validation command results.
