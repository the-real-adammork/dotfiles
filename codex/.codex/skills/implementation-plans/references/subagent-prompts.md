# Subagent Prompts

Use this reference when dispatching phase plan-writing or consolidated-review subagents.

## Context Handoff Protocol

Every subagent must self-monitor context pressure. If it estimates it is at or above roughly 70% context usage, or cannot confidently finish within remaining context, it must:

1. Stop normal work at a coherent boundary.
2. Save a handoff document under:

   ```text
   docs/handoffs/YYYY-MM-DD-<feature>-<phase-or-review>-handoff.md
   ```

3. Return only the handoff path and current artifact paths to the parent.

Handoff document template:

````markdown
# <Feature> <Phase Or Review> Handoff

**Original Goal:** <assigned subagent task>
**Scope:** <phase/review scope>
**Source Documents:**
- Technical design: `<path>`
- Phases document: `<path>`
- Requirements: `<path or "not provided">`

## Progress Made

- <completed work>

## In-Progress Documents

| Document | Status | Notes |
| --- | --- | --- |
| `<path>` | <not started/in progress/needs review> | <notes> |

## Remaining Work

1. <next concrete step>
2. <next concrete step>

## Blockers Or Decisions Needed

- <blocker or "None">

## Completion Criteria

- <what done looks like>

## Replacement Subagent Prompt

```text
Continue this task from the handoff document:
<handoff path>

Use the listed source documents and artifact paths as the source of truth. Do not rely on prior chat context. Follow the original phase/review scope and finish the remaining work only.
```
````

## Plan-Writing Subagent

Dispatch one subagent per approved phase that lacks a valid output plan. Prefer sequential dispatch so later phase plans can build on earlier phase plans.

Each subagent owns exactly one phase and one output plan document. Subagents are not alone in the codebase; they must not edit other phases' plan files, modify the technical design, or implement code.

Prompt:

```text
agent_name: phase-plan-writer: <feature-slug> / <phase-slug>

Use $implementation-plans and load `references/plan-writing.md` to write a detailed implementation plan for this phase only.

Technical design:
<path>

Implementation phases document:
<path>

Phase:
<phase name, goal, builds on, app surface included, smoke test, E2E automation, output path>

Requirements source:
<path or "not provided">

Constraints:
- Stay within this phase boundary.
- Include the UI/API/CLI/jobs/data work needed for this phase's smoke-testable outcome.
- End the plan with a mandatory phase-final E2E QA automation task that duplicates the human smoke test using the appropriate platform harness.
- For web phases, use Playwright to verify browser behavior and API/service wiring unless the repo has an explicit different browser E2E standard.
- For app phases, use simulator/emulator automation appropriate to the platform.
- Mention dependencies on earlier phases, but do not plan their tasks.
- Do not turn the phase into a horizontal backend-only or frontend-only layer unless the approved phase explicitly says the whole product increment is that layer.
- Use exact file paths and verification commands.
- Save the plan to the specified output path.
- Do not implement code.
- Do not modify other plan files.
- If the output plan already exists and appears to match this approved phase, inspect it and return its path plus a summary instead of regenerating it.
- Return only output path, phase name, 3-5 bullet summary, human-in-the-loop TODO count, blockers, and deviations from the phase boundary.
- If context pressure reaches roughly 70%, save a handoff document under `docs/handoffs/` using the Context Handoff Protocol and return only the handoff path plus current artifact paths.
```

Dispatch later phase plans after prerequisite phase plan drafts return when later phases need their exact APIs, files, smoke tests, or assumptions.

## Consolidated Reviewer Subagent

Dispatch one reviewer after all plan-writing subagents return.

Prompt:

```text
agent_name: phase-plan-reviewer: <feature-slug> / consolidated

Use $implementation-plans and load `references/phasing.md` plus this `references/subagent-prompts.md` reference to review these implementation plan documents as a set.

Original technical design:
<path>

Implementation phases document:
<path>

Plan documents:
<paths>

Requirements source:
<path or "not provided">

Review output directory:
<plan output directory>/reviews/

Check for:
- gaps between the technical design and the plan set;
- gaps between approved phases and their generated plans;
- phase boundary mismatches or duplicate work across plans;
- horizontal backend-first/frontend-later splits that prevent the app from coming to life phase by phase;
- missing or unclear cross-plan dependencies;
- verification gaps;
- missing or weak phase-final E2E automation tasks;
- web phase plans that do not use Playwright or an explicitly established browser E2E equivalent;
- app phase plans that do not use simulator/emulator automation or an explicitly established app E2E equivalent;
- plan tasks that escaped their phase boundary.

Return Findings, Coverage Matrix, Phase Boundary Review, and Recommended Plan Edits. Do not modify files. Do not implement code.

Write the detailed review to `<plan output directory>/reviews/YYYY-MM-DD-<feature>-implementation-plan-review.md` and return only the review path, top findings, severity counts, and blocking status. For review reruns, create a new file such as `<plan output directory>/reviews/YYYY-MM-DD-<feature>-implementation-plan-review-rerun-2.md`; do not overwrite prior review artifacts.

If context pressure reaches roughly 70%, save a handoff document under `docs/handoffs/` using the Context Handoff Protocol and return only the handoff path plus current artifact paths.
```

## Parent Walkthrough Format

For each reviewer finding, the parent presents:

```text
Plan review finding N: <severity> - <short issue>
Affected plan(s): <paths>
Design/phase source: <technical design section or phase>
Recommended edit: <specific plan or phase proposal change>

Decision needed: accept, revise, reject as non-issue, defer, or clarify?
```

Patch plan documents and/or the phases document only for accepted or revised findings.
