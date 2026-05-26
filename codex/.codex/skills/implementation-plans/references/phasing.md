# Implementation Phase Planning Reference

Turn an approved technical design into a sequence of smoke-testable implementation phase plans. Each generated implementation plan is one phase. Phases build on each other so the app comes to life over time, instead of building isolated horizontal stack layers.

## Start

Inputs:

- approved technical design path;
- optional requirements path;
- optional plan output directory, default `docs/plans/`;
- optional review output directory, default `<plan output directory>/reviews/`;
- optional phases document path, default `docs/plans/YYYY-MM-DD-<feature>-implementation-phases.md`.

If the technical design path is missing and cannot be inferred, ask for it.

## Context Budget Rules

Keep files as the source of truth. Do not paste full technical designs, phases documents, implementation plans, or review artifacts into the parent conversation unless the user asks.

- Pass file paths to subagents whenever possible.
- Plan-writing subagents return only path, phase name, 3-5 bullet summary, human TODO count, blockers, and phase-boundary deviations.
- Reviewer subagents write reviews to the review output directory and return only path, top findings, severity counts, and blocking status.
- Parent reads targeted file sections only when patching, resolving a finding, or answering a user question.
- If there are more than 5 phases, or any plan exceeds roughly 500 lines, require a file-based consolidated review.

## Dispatch Efficiency

Keep plan generation bounded and idempotent.

- Maintain a small dispatch table in the phases document or parent notes before starting plan writers: phase name, output path, stable `agent_name`, host agent id/nickname, status, and result path.
- Do not dispatch a plan-writing subagent when its output plan already exists and matches the approved phase unless the user explicitly requests regeneration.
- Do not dispatch a replacement for an active or recently completed phase writer until you have checked the dispatch table, output path, and any handoff path.
- Use stable agent names in the format `phase-plan-writer: <feature-slug> / <phase-slug>` and `phase-plan-reviewer: <feature-slug> / consolidated`.
- Prefer sequential dispatch because later phase plans should build on earlier phase plans. Dispatch phase plan writers in parallel only when phases are explicitly independent and do not need to inherit decisions, APIs, or smoke-test results from earlier phases.

## Subagent Context Handoff

Subagents must self-monitor context pressure. If a subagent estimates it is at or above roughly 70% context usage, or it cannot confidently finish within the remaining context, it must stop normal work, save a handoff document under `docs/handoffs/`, and return only the handoff path plus current artifact paths.

Handoff documents must include:

- original subagent goal and assigned phase/review scope;
- progress made;
- in-progress documents and their current status;
- remaining work;
- blockers or decisions needed;
- exact completion criteria;
- recommended prompt for a replacement subagent.

When this happens, the parent dispatches a replacement subagent using the handoff document and the original source paths. Do not ask the replacement to infer state from chat history.

## Phase Criteria

Each phase should become its own implementation plan when it delivers a substantial logical increment that can be smoke tested after completion and used as the foundation for later phases.

Prefer fewer coherent phase plans over many thin plans. Do not split just because the design has multiple sections.

Do not split phases as horizontal stack layers like data model, backend/API, UI, jobs, and cleanup. Instead, combine the needed parts of those layers into each phase so a real workflow or capability exists at the end of the phase.

Good phase boundaries include:

- the smallest end-to-end read path that proves the model, API/service, and UI/CLI can talk to each other;
- a first write path with validation, persistence, and visible confirmation;
- a meaningful workflow expansion that builds on the earlier read/write paths;
- real integration replacement after a mocked/local path, with smoke testing against the best available real environment;
- hardening, observability, and rollout work once the main workflow exists.

Every phase must state:

- what app behavior works at the end;
- what earlier phase behavior it builds on;
- what smoke test proves it;
- what platform E2E automation will duplicate the smoke test at the end of the phase;
- what later phases can safely assume.

Every generated phase plan must end with a phase-final E2E QA automation task. For web work, this means Playwright unless the repo already standardizes on another browser automation framework. For mobile or app work, use simulator/emulator automation appropriate to the platform. For service, CLI, desktop, or worker-only phases, use the closest true end-to-end harness that exercises the phase through its real runtime boundary.

## Workflow

1. Read the technical design and any referenced requirements.
2. Inspect enough repo context to understand ownership boundaries, test commands, and existing patterns.
3. Identify sequential phases by smoke-testable app state and build-on relationship.
4. Create or update the phases document. Read `references/phases-document.md` for the required format and lifecycle.
5. Present the phase proposal summary to the user and ask for approval or corrections.
6. If the user revises the phases, update the phases document and ask again when needed.
7. After approval, run a phase breakup review against the technical design:
   - all major responsibilities, integration points, sequencing items, risk mitigations, and verification areas map to phases;
   - each phase has a coherent smoke-testable outcome;
   - each phase names the E2E automation that will duplicate the smoke test;
   - dependencies, build-on assumptions, and deferred work are explicit.
   Save detailed phase review artifacts under the review output directory. Keep only the summary/disposition table and review links in the phases document.
8. Walk the user through phase-level findings. Patch the phases document for accepted/revised findings. Do not generate plan docs until High/Medium phase issues are resolved or explicitly deferred.
9. Create or update the plan-writer dispatch table, then dispatch one plan-writing subagent per approved phase that does not already have a valid plan output. Read `references/subagent-prompts.md` for the required prompt and return contract.
10. Update the phases document after each plan is created, then set status to `Plans Generated` once all plan docs exist.
11. Dispatch one consolidated reviewer subagent. Use `references/subagent-prompts.md`.
12. Walk the user through reviewer findings. Patch plan docs and/or the phases document only for accepted/revised findings.
13. Rerun consolidated review when High/Medium findings were patched, phase boundaries changed, or the user asks. Save each rerun as a separate artifact in the review output directory; do not overwrite prior review files.
14. Final local check and handoff.

Do not create detailed task checklists until the user approves the phase proposal. Do not begin implementation unless the user chooses an execution option.

## Final Checks

Before handoff:

- phases document exists, links back to the technical design, and links forward to every generated plan;
- every approved phase has a plan file at the reported path;
- every approved phase plan ends with a phase-final E2E QA automation task;
- review artifacts are stored under the review output directory, not mixed with implementation plan files;
- coverage check maps technical design sections to phases;
- phase breakup review ran before plan generation;
- consolidated plan review ran after all plan docs returned;
- accepted/revised findings were applied;
- every technical design responsibility maps to one or more phases;
- horizontal stack splits have been rejected unless explicitly justified;
- build-on dependencies, deferred work, and verification gaps are resolved or explicitly noted;
- no implementation work was performed.

## Handoff

Report:

```markdown
Created implementation plans:

- `<path>` - <phase goal>
- `<path>` - <phase goal>

Phases document:
- `<path>`

Execution order:
1. <phase>
2. <phase>

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
