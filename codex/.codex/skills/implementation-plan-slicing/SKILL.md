---
name: implementation-plan-slicing
description: Use when an approved technical design needs to be decomposed into one or more detailed implementation plan documents.
---

# Implementation Plan Slicing

Turn an approved technical design into a set of implementation plan slices, then create one `$implementation-plans` document per approved slice. The parent agent owns decomposition, user approval, cross-plan consistency, and final handoff.

## Start

Announce: "I'm using the implementation-plan-slicing skill to split the technical design into implementation plan slices."

Inputs:

- approved technical design path;
- optional requirements path;
- optional plan output directory, default `docs/plans/`;
- optional review output directory, default `<plan output directory>/reviews/`;
- optional slices document path, default `docs/plans/YYYY-MM-DD-<feature>-implementation-slices.md`.

If the technical design path is missing and cannot be inferred, ask for it.

## Context Budget Rules

Keep files as the source of truth. Do not paste full technical designs, slices documents, implementation plans, or review artifacts into the parent conversation unless the user asks.

- Pass file paths to subagents whenever possible.
- Plan-writing subagents return only path, slice name, 3-5 bullet summary, human TODO count, blockers, and ownership deviations.
- Reviewer subagents write reviews to the review output directory and return only path, top findings, severity counts, and blocking status.
- Parent reads targeted file sections only when patching, resolving a finding, or answering a user question.
- If there are more than 5 slices, or any plan exceeds roughly 500 lines, require a file-based consolidated review.

## Dispatch Efficiency

Keep plan generation bounded and idempotent.

- Maintain a small dispatch table in the slices document or parent notes before starting plan writers: slice name, output path, stable `agent_name`, host agent id/nickname, status, and result path.
- Do not dispatch a plan-writing subagent when its output plan already exists and matches the approved slice unless the user explicitly requests regeneration.
- Do not dispatch a replacement for an active or recently completed slice writer until you have checked the dispatch table, output path, and any handoff path.
- Use stable agent names in the format `plan-writer: <feature-slug> / <slice-slug>` and `plan-reviewer: <feature-slug> / consolidated`.
- Run independent plan writers in parallel only after the dispatch table is recorded. If there are more than 3 independent slices, dispatch them in waves of 3 to avoid overloading the session and making results harder to reconcile.

## Subagent Context Handoff

Subagents must self-monitor context pressure. If a subagent estimates it is at or above roughly 70% context usage, or it cannot confidently finish within the remaining context, it must stop normal work, save a handoff document under `docs/handoffs/`, and return only the handoff path plus current artifact paths.

Handoff documents must include:

- original subagent goal and assigned slice/review scope;
- progress made;
- in-progress documents and their current status;
- remaining work;
- blockers or decisions needed;
- exact completion criteria;
- recommended prompt for a replacement subagent.

When this happens, the parent dispatches a replacement subagent using the handoff document and the original source paths. Do not ask the replacement to infer state from chat history.

## Slice Criteria

A slice should become its own implementation plan when it has a distinct subsystem/module/service/UI/CLI/migration/integration boundary, owner or file set, verification path, review path, or dependency relationship.

Prefer fewer coherent plans over many thin plans. Do not split just because the design has multiple sections.

Common splits: data model and migration, backend/API behavior, UI workflow, CLI/automation, background jobs, auth/security/privacy, observability/regression hardening, documentation/rollout cleanup.

## Workflow

1. Read the technical design and any referenced requirements.
2. Inspect enough repo context to understand ownership boundaries, test commands, and existing patterns.
3. Identify slices by integration boundary and verification path.
4. Create or update the slices document. Read `references/slices-document.md` for the required format and lifecycle.
5. Present the slice proposal summary to the user and ask for approval or corrections.
6. If the user revises the split, update the slices document and ask again when needed.
7. After approval, run a slice breakup review against the technical design:
   - all major responsibilities, integration points, sequencing items, risk mitigations, and verification areas map to slices;
   - each slice has coherent ownership and verification;
   - overlap, dependencies, and deferred work are explicit.
   Save detailed slice breakup review artifacts under the review output directory. Keep only the summary/disposition table and review links in the slices document.
8. Walk the user through slice-level findings. Patch the slices document for accepted/revised findings. Do not generate plan docs until High/Medium slice issues are resolved or explicitly deferred.
9. Create or update the plan-writer dispatch table, then dispatch one plan-writing subagent per approved slice that does not already have a valid plan output. Read `references/subagent-prompts.md` for the required prompt and return contract.
10. Update the slices document after each plan is created, then set status to `Plans Generated` once all plan docs exist.
11. Dispatch one consolidated reviewer subagent. Use `references/subagent-prompts.md`.
12. Walk the user through reviewer findings. Patch plan docs and/or the slices document only for accepted/revised findings.
13. Rerun consolidated review when High/Medium findings were patched, slice boundaries changed, or the user asks. Save each rerun as a separate artifact in the review output directory; do not overwrite prior review files.
14. Final local check and handoff.

Do not create detailed task checklists until the user approves the slice proposal. Do not begin implementation unless the user chooses an execution option.

## Final Checks

Before handoff:

- slices document exists, links back to the technical design, and links forward to every generated plan;
- every approved slice has a plan file at the reported path;
- review artifacts are stored under the review output directory, not mixed with implementation plan files;
- coverage check maps technical design sections to slices;
- slice breakup review ran before plan generation;
- consolidated plan review ran after all plan docs returned;
- accepted/revised findings were applied;
- every technical design responsibility maps to one plan;
- ownership conflicts, dependencies, deferred work, and verification gaps are resolved or explicitly noted;
- no implementation work was performed.

## Handoff

Report:

```markdown
Created implementation plans:

- `<path>` - <slice goal>
- `<path>` - <slice goal>

Slices document:
- `<path>`

Execution order:
1. <slice>
2. <slice>

Open coordination notes:
- <note or "None">
```

Then offer:

```text
Next options:
1. Execute plans in order.
2. Dispatch subagents per plan.
3. Stop here and keep the plans as handoff artifacts.
```
