---
name: workflow-auditor
description: "Use when Codex needs to audit supervisor, orchestrator, reviewer, fixer, or worker session logs and workflow artifacts after an implementation run or phase transition, looking for recurring problems, wasted context, slow handoffs, unclear instructions, missed parallelism, process complexity, code-quality risks, and concrete improvements classified as repo-specific lesson files, global skill updates, agent-role changes, or workflow design changes."
---

# Workflow Auditor

Audit the agent workflow after the fact. The goal is to reduce complexity, increase speed, and improve code quality.

## Inputs

Prefer explicit paths from the user or run state:

- run directory: `docs/implementation-runs/<run-id>/`;
- `run.yaml`, phase YAML, transition YAML, worker result YAML;
- supervisor, orchestrator, reviewer, fixer, and worker session log paths recorded in state;
- compact event JSONL;
- acceptance packets and QA artifacts.

Do not modify product code or workflow state. The auditor may write only:

- the global audit report;
- repo-specific lesson docs and the repo's lessons table for proven `repo-lesson` findings;
- global workflow task docs for `global-skill` findings.

## Report Location

Write one Markdown report to:

```text
~/.codex/workflow-audits/YYYY-MM-DD-HHMM-<repo-or-run>-workflow-audit.md
```

Create the directory if missing. Keep the report at most three readable pages. Prefer short sections and sparse bullets over dense paragraphs.

Write global workflow task docs to:

```text
~/.codex/workflow-audits/tasks/YYYY-MM-DD-HHMM-<topic>.md
```

Create the directory if missing. Keep each task doc to one readable page.

## What To Look For

Review logs and artifacts for:

- recurring mistakes that should become repo-specific lesson files or global skill updates;
- unclear, contradictory, or wasteful instructions;
- context churn, repeated full-plan reads, repeated log dumping, or oversized prompts;
- slow handoffs, missed automation, or unnecessary waiting;
- missed parallelism or work that should have been split differently;
- too many roles, too few roles, or wrong role boundaries;
- reviewer/fixer loops that could be prevented earlier;
- tests that were too isolated and missed integrated behavior;
- smoke/E2E gaps, missing durable accounts, or fake data treated as real proof;
- code-quality risks caused by workflow pressure;
- places where a new skill, global lesson, or workflow simplification would pay off.

## Classify Improvements

For each recommendation, classify the right home for the fix:

- `repo-lesson`: recurring issue depends on the target repo's stack, scripts, architecture, product domain, test data, ports, local services, generated artifacts, or repo-specific conventions. Recommend a lesson file under that repo, such as `docs/lessons/YYYY-MM-DD-<topic>.md`, and an `AGENTS.md` pointer only when the issue is proven likely to recur.
- `global-skill`: recurring issue comes from the agent workflow itself, role boundaries, supervisor/orchestrator/worker instructions, TDD/review policy, smoke-testing standards, account seeding, secrets handling, control-plane behavior, or cross-repo execution patterns. Recommend the specific global skill file to update.
- `one-off`: issue is local to this run and does not justify durable instructions yet. Recommend no lesson or skill change unless it recurs.

Keep repo lessons and global skill changes separate. Do not turn repo-specific setup friction into a global rule unless the same pattern applies across repos. Do not bury global workflow defects in a repo lesson where other agents will miss them.

## Repo Lesson Actions

For each proven `repo-lesson` finding, automatically create a small lesson in the audited repo:

```text
docs/lessons/YYYY-MM-DD-<short-topic>.md
```

Lesson shape:

```markdown
# <Specific Problem Agents May Hit>

## When This Applies
One short paragraph naming the repo-specific condition or symptom.

## What To Do
3-6 concrete steps future agents should take to avoid or fix it.

## Evidence
- `<path>` - brief reason this lesson exists.
```

Then update the repo's root `AGENTS.md` or nearest existing agent-instructions file with a `## Lessons` table. If the section does not exist, create it. If it exists as bullets, preserve existing entries and add a table only if that is the local convention. Use this default table:

```markdown
## Lessons

| Situation | Lesson |
| --- | --- |
| Short symptom-oriented description for future agents | [Lesson title](docs/lessons/YYYY-MM-DD-<short-topic>.md) |
```

Keep the table description short and written for an agent who is about to hit the issue. Do not add repo lessons for one-off incidents, global workflow problems, or issues without clear path-based evidence.

## Global Task Docs

For each `global-skill` finding that should change skills or workflow, automatically write a one-page task document, but do not modify the global skill or workflow files as part of the audit.

Task doc shape:

```markdown
# Task: <Skill Or Workflow Improvement>

## Problem
What recurring workflow issue this solves.

## Evidence
- `<path>` - brief evidence pointer.

## Target Files
- `<global skill/workflow path or skill name>`

## Proposed Change
Concrete instructions another agent can implement.

## Acceptance
- How to verify the skill/workflow update worked.
```

Link these task docs from the audit report under `Global skill updates`.

## Output Shape

Use this structure:

```markdown
# Workflow Audit: <repo/run/phase>

## Summary
2-5 bullets with the highest-impact findings.

## Findings
- **Severity:** high|medium|low
  **Area:** supervisor|orchestrator|worker|review|testing|handoff|skills
  **Fix home:** repo-lesson|global-skill|one-off
  **Evidence:** short pointer to log/artifact path, not pasted logs
  **Problem:** concise explanation
  **Recommendation:** concrete change

## Opportunities
- Parallelism:
- New or changed agent roles:
- Repo lesson candidates:
- Global skill updates:
- Simplifications:

## Generated Artifacts
- Repo lessons:
- Global workflow task docs:

## Suggested Next Changes
1. Highest leverage change.
2. Next change.
3. Optional follow-up.
```

Keep evidence path-based. Do not paste long logs, raw session transcripts, full prompts, or diffs.

## Triggering

Good trigger points:

- automatically after a phase transition completes;
- after a failed or slow phase;
- before changing implementation-execution workflow rules;
- on demand when the user asks for an audit.

For asynchronous use, the supervisor may launch the auditor after the next phase has already started. The auditor should only write the global report and should not block the run unless it discovers an active safety issue such as plaintext secrets, destructive actions, or real customer-data exposure.
