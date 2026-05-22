# Subagent Prompts

Use this reference when dispatching plan-writing or consolidated-review subagents.

## Context Handoff Protocol

Every subagent must self-monitor context pressure. If it estimates it is at or above roughly 70% context usage, or cannot confidently finish within remaining context, it must:

1. Stop normal work at a coherent boundary.
2. Save a handoff document under:

   ```text
   docs/handoffs/YYYY-MM-DD-<feature>-<slice-or-review>-handoff.md
   ```

3. Return only the handoff path and current artifact paths to the parent.

Handoff document template:

````markdown
# <Feature> <Slice Or Review> Handoff

**Original Goal:** <assigned subagent task>
**Scope:** <slice/review scope>
**Source Documents:**
- Technical design: `<path>`
- Slices document: `<path>`
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

Use the listed source documents and artifact paths as the source of truth. Do not rely on prior chat context. Follow the original slice/review scope and finish the remaining work only.
```
````

## Plan-Writing Subagent

Dispatch one subagent per approved slice that lacks a valid output plan. Subagents may run in parallel when their output files are distinct; use waves of 3 when there are more than 3 independent slices.

Each subagent owns exactly one slice and one output plan document. Subagents are not alone in the codebase; they must not edit other slices' plan files, modify the technical design, or implement code.

Prompt:

```text
agent_name: plan-writer: <feature-slug> / <slice-slug>

Use $implementation-plans to write a detailed implementation plan for this slice only.

Technical design:
<path>

Implementation slices document:
<path>

Slice:
<slice name, goal, owns, dependencies, verification, output path>

Requirements source:
<path or "not provided">

Constraints:
- Stay within this slice ownership.
- Mention dependencies on other slices, but do not plan their tasks.
- Use exact file paths and verification commands.
- Save the plan to the specified output path.
- Do not implement code.
- Do not modify other plan files.
- If the output plan already exists and appears to match this approved slice, inspect it and return its path plus a summary instead of regenerating it.
- Return only output path, slice name, 3-5 bullet summary, human-in-the-loop TODO count, blockers, and deviations from slice ownership.
- If context pressure reaches roughly 70%, save a handoff document under `docs/handoffs/` using the Context Handoff Protocol and return only the handoff path plus current artifact paths.
```

If dependencies require strict ordering for understanding, dispatch dependent plans after prerequisite plan drafts return. Otherwise, dispatch independent slice plan subagents in parallel.

## Consolidated Reviewer Subagent

Dispatch one reviewer after all plan-writing subagents return.

Prompt:

```text
agent_name: plan-reviewer: <feature-slug> / consolidated

Review these implementation plan documents as a set.

Original technical design:
<path>

Implementation slices document:
<path>

Plan documents:
<paths>

Requirements source:
<path or "not provided">

Review output directory:
<plan output directory>/reviews/

Check for:
- gaps between the technical design and the plan set;
- gaps between approved slices and their generated plans;
- boundary mismatches or duplicate ownership across plans;
- missing or unclear cross-plan dependencies;
- verification gaps;
- plan tasks that escaped their slice ownership.

Return Findings, Coverage Matrix, Boundary Review, and Recommended Plan Edits. Do not modify files. Do not implement code.

Write the detailed review to `<plan output directory>/reviews/YYYY-MM-DD-<feature>-implementation-plan-review.md` and return only the review path, top findings, severity counts, and blocking status. For review reruns, create a new file such as `<plan output directory>/reviews/YYYY-MM-DD-<feature>-implementation-plan-review-rerun-2.md`; do not overwrite prior review artifacts.

If context pressure reaches roughly 70%, save a handoff document under `docs/handoffs/` using the Context Handoff Protocol and return only the handoff path plus current artifact paths.
```

## Parent Walkthrough Format

For each reviewer finding, the parent presents:

```text
Plan review finding N: <severity> - <short issue>
Affected plan(s): <paths>
Design/slice source: <technical design section or slice>
Recommended edit: <specific plan or slice proposal change>

Decision needed: accept, revise, reject as non-issue, defer, or clarify?
```

Patch plan documents and/or the slices document only for accepted or revised findings.
