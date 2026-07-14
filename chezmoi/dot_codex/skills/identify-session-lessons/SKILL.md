---
name: identify-session-lessons
description: "Use when asked to capture, harvest, or review lessons from the current Codex session, especially after unexpected friction, failed attempts, missing dependencies, long detours, repeated existing lesson problems, or solved workflow issues."
---

# Identify Session Lessons

Review the current session for reusable lessons before writing any repo instructions. This skill is the approval gate: it identifies and scores candidates, then waits for the human to approve or reject each one.

## Workflow

1. Reconstruct the session path from conversation context, terminal output, tool errors, retries, and final working approaches.
2. Find at most 3 lesson candidates where the agent tried a reasonable first path, hit unexpected friction, then took a longer path before reaching a workable solution.
3. Check existing lesson docs and `AGENTS.md` `## Lessons` entries before proposing a new lesson.
4. Score each candidate from 0-10 for future time/token savings.
5. Present candidates to the human and wait for approval or rejection for each one.
6. After approvals are resolved, use `write-approved-lessons` for only the approved lessons or approved updates.

Do not create or edit `docs/lessons` or `AGENTS.md` while using this skill. Writing belongs to `write-approved-lessons`.

## What Qualifies

Good candidates have an initial attempt, an unexpected obstacle, and a later solution or better path:

- missing dependencies, binaries, services, credentials, permissions, ports, or generated files;
- an attempted command, test, route, tool, or implementation that failed for a non-obvious reason;
- a local repo convention that was discovered only after wasting work;
- an existing lesson that did not prevent the same problem, suggesting the lesson or `AGENTS.md` pointer needs a fix.

Do not propose lessons for ordinary implementation steps, one-off typos, obvious syntax errors, personal preference, or anything without a plausible future recurrence.

## Existing Lessons

Always inspect the repo's lesson surface before proposing candidates:

- `AGENTS.md`, especially `## Lessons`;
- `docs/lessons/*.md`;
- nearby agent-instruction files if this is not the repo root.

If the session repeated a problem that already has a lesson, prefer an update candidate over a new lesson. Explain what the existing lesson failed to make clear, then propose the specific change needed in both the lesson doc and its `AGENTS.md` summary.

## Scoring

Score expected savings for future agents:

| Score | Meaning |
| --- | --- |
| 0-2 | Too local or low-value; usually reject. |
| 3-5 | Some recurring value, but only for rare cases or small detours. |
| 6-8 | Likely to save meaningful debugging, setup, or context time. |
| 9-10 | Prevents a common or expensive failure mode with a clear playbook. |

Bias against writing low-score lessons. A score below 6 needs a strong reason to present.

## Candidate Format

Present no more than 3 candidates. For each candidate include:

```markdown
### <Lesson Title> - Score: <0-10>
Type: new lesson | update existing lesson

Problem:
<2-3 sentences summarizing the failed or longer path and why it was non-obvious.>

Solution:
<2-3 sentences summarizing the discovered solution or improved playbook.>

Suggested destination:
<docs/lessons/<slug>.md or existing lesson path>
```

Then ask the human to approve or reject each candidate. Do not proceed until the response clearly resolves every candidate.

## Handoff

When approvals are complete, invoke or load `write-approved-lessons` and pass only:

- approved new lessons;
- approved updates to existing lessons;
- rejected candidates only as "do not write" context, if needed to avoid confusion.

If nothing is approved, stop and report that no lesson files were changed.
