---
name: implementation-plan-slicing
description: Use when an approved technical design needs to be decomposed into one or more detailed implementation plan documents.
---

# Implementation Plan Slicing

Turn an approved technical design into a set of implementation plan slices, then create one `$implementation-plans` document per approved slice. The parent agent owns decomposition, user approval, cross-plan consistency, and final handoff.

## Start

Announce: "I'm using the implementation-plan-slicing skill to split the technical design into implementation plan slices."

Inputs:

- Approved technical design path.
- Optional requirements path.
- Optional plan output directory. Default:

```text
docs/plans/
```

If the technical design path is missing and cannot be inferred, ask for it.

## Parent-Owned Responsibilities

The parent agent must:

- Read the technical design and any referenced requirements.
- Inspect enough repo context to understand ownership boundaries, test commands, and existing patterns.
- Identify implementation slices by integration boundary and verification path.
- Present the proposed slices to the user before writing detailed plans.
- Ask for human approval or corrections to the slice boundaries.
- Run a review cycle on the slice breakup before writing detailed plans.
- Dispatch subagents to create one detailed `$implementation-plans` document per approved slice.
- Run a consolidated review cycle across all generated plans against the slice breakup and original technical design.
- Walk the user through reviewer findings and apply accepted fixes.

Do not create detailed task checklists until the user approves the slice proposal.

## Slice Criteria

A slice should become its own implementation plan when it has a distinct:

- subsystem, module, service, UI surface, CLI, migration, or integration boundary;
- owner or file set;
- verification path;
- review path;
- dependency relationship with other slices.

Prefer fewer, coherent plans over many thin plans. Do not split just because the design has multiple sections.

Common useful splits:

- data model and migration
- backend/API behavior
- UI workflow
- CLI or automation
- background jobs/queueing
- auth/security/privacy changes
- observability/regression hardening
- documentation or rollout cleanup

## Slice Proposal Format

Before writing plan documents, present:

```markdown
## Proposed Implementation Plan Slices

| Slice | Goal | Owns | Depends On | Verification | Plan Path |
| --- | --- | --- | --- | --- | --- |
| <name> | <testable outcome> | <files/modules/surfaces> | <slice or none> | <primary checks> | `docs/plans/YYYY-MM-DD-<feature>-<slice>.md` |

## Coverage Check

- Technical design sections covered:
- Sections intentionally deferred:
- Risks in this split:

Approve these slices, or tell me what to merge/split/rename?
```

Wait for the user's answer. If they revise the split, update the proposal and ask again if needed.

## Slice Breakup Review

After the user approves the initial slice proposal, run a slice-level review before generating plan documents.

Review the slice proposal against the technical design:

- Every major responsibility, integration point, sequencing item, risk mitigation, and verification area from the technical design maps to a slice.
- Each slice has a coherent owner and verification path.
- Boundaries are not overlapping in ways that would cause duplicate implementation.
- Cross-slice dependencies are explicit and directional.
- Deferred work is explicit.

Present any slice-level findings to the user:

```text
Slice review finding N: <issue>
Recommended slice change: <merge/split/rename/dependency/ownership change>

Decision needed: accept, revise, reject, defer, or clarify?
```

Patch the slice proposal for accepted/revised findings. Do not generate plan documents until all High/Medium slice breakup issues are resolved or explicitly deferred by the user.

## Plan Generation With Subagents

For each approved slice, dispatch one subagent to create a detailed `$implementation-plans` document for only that slice. Subagents may run in parallel when their output files are distinct.

The parent agent must assign each subagent a unique output path and slice ownership. Subagents are not alone in the codebase; they must not edit other slices' plan files, modify the technical design, or implement code.

Each plan prompt or local planning pass must include:

```text
Use $implementation-plans to write a detailed implementation plan for this slice only.

Technical design:
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
```

If dependencies require strict ordering for understanding, dispatch dependent plans after prerequisite plan drafts return. Otherwise, dispatch independent slice plan subagents in parallel.

## Consolidated Plan Review

After all plan subagents return, dispatch one reviewer subagent to review the full set of implementation plan documents against:

- the original technical design;
- the approved slice proposal;
- any requirements source if provided.

Reviewer prompt:

```text
Review these implementation plan documents as a set.

Original technical design:
<path>

Approved implementation slices:
<slice proposal>

Plan documents:
<paths>

Requirements source:
<path or "not provided">

Check for:
- gaps between the technical design and the plan set;
- gaps between approved slices and their generated plans;
- boundary mismatches or duplicate ownership across plans;
- missing or unclear cross-plan dependencies;
- verification gaps;
- plan tasks that escaped their slice ownership.

Return Findings, Coverage Matrix, Boundary Review, and Recommended Plan Edits. Do not modify files. Do not implement code.
```

The parent agent reviews the reviewer output, then walks the user through each finding:

```text
Plan review finding N: <severity> - <short issue>
Affected plan(s): <paths>
Design/slice source: <technical design section or slice>
Recommended edit: <specific plan or slice proposal change>

Decision needed: accept, revise, reject as non-issue, defer, or clarify?
```

Patch plan documents and/or the slice proposal only for accepted or revised findings.

Rerun consolidated plan review when:

- any High/Medium finding was patched;
- slice boundaries changed;
- the user asks for another pass.

## Final Cross-Plan Checks

Before handoff, the parent agent performs a final local check:

- Every technical design responsibility maps to one plan.
- No file or module ownership conflict is left unexplained.
- Cross-plan dependencies are explicit.
- Verification is not duplicated as a substitute for missing slice-specific checks.
- Deferred work is listed clearly.

Patch obvious formatting or consistency issues only when they do not change design intent. Otherwise, ask the user.

## Handoff

Report:

```markdown
Created implementation plans:

- `<path>` - <slice goal>
- `<path>` - <slice goal>

Execution order:
1. <slice>
2. <slice>

Open coordination notes:
- <note or "None">
```

Then offer execution options:

```text
Next options:
1. Execute plans in order.
2. Dispatch subagents per plan.
3. Stop here and keep the plans as handoff artifacts.
```

Do not begin implementation unless the user chooses an execution option.

## Self-Review

Before declaring the workflow complete:

- Confirm every approved slice has a plan file.
- Confirm the plan files exist at the reported paths.
- Confirm the coverage check maps technical design sections to slices.
- Confirm slice breakup review ran before plan generation.
- Confirm consolidated plan review ran after all plan documents returned.
- Confirm every accepted/revised review finding was applied.
- Confirm no implementation work was performed.
