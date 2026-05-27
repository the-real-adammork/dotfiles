---
name: implementation-execution
description: "Use when implementing approved implementation phase plans with a git-native, file-backed agent workflow: long-running supervisor/phase-owner execution, bounded worker agents, TDD test approval gates, YAML run state, artifact-backed verification, phase acceptance gates, resumable handoffs, and autonomous execution without Linear or SQLite."
---

# Implementation Execution

Run approved implementation phase plans through a durable, file-backed agent workflow. This skill is independent of deprecated Linear/SQLite implementation workflows.

## Start

Announce: "I'm using the implementation-execution skill to run the phase plans with YAML state, long-running phase ownership, bounded workers, and phase acceptance gates."

Inputs:

- phases document path;
- one or more implementation plan paths;
- optional run id, default `YYYY-MM-DD-<feature>`;
- optional run directory, default `docs/implementation-runs/<run-id>/`;
- optional QA artifact directory, default `docs/qa/artifacts/<phase-slug>/`;
- optional phase acceptance directory, default `docs/qa/phase-acceptance/`.

If phase plans are missing, run `$implementation-plans` first. Do not begin implementation from requirements alone.

## Core Model

- YAML tracks state.
- Markdown explains decisions.
- Artifacts hold evidence.
- Do not make markdown the database.

One supervisor owns the run. One long-running phase owner owns each active phase. Worker agents handle only substantial bounded lanes. Workers cannot spawn workers or coordinate directly with sibling workers. The supervisor/phase owner is the only scheduler and integrator.

Human involvement is only for allowed escalations: credentials/secrets, paid/vendor setup, unresolved product/legal/security decisions, destructive production actions, real customer data access, or unavailable real dependencies after an agent-owned attempt.

## Reference Modules

Load only the module needed for the current action:

- `references/state-files.md` - create, update, and resume `run.yaml`, `phase.yaml`, worker result YAML, handoffs, acceptance packets, and evidence artifacts.
- `references/supervisor.md` - run-level state machine, phase order, active phase selection, resumability, and escalation behavior.
- `references/phase-owner.md` - phase-owner orchestration, active frontier construction, worker lane selection, `/goal` usage, integration checkpoints, and phase branch ownership.
- `references/branch-worktree.md` - phase branch, worker branch/worktree isolation, merge-back rules, and parallel lane safety.
- `references/worker-tdd.md` - bounded worker contract, two-stage TDD flow, test proposal approval, implementation, worker result YAML, and worker restrictions.
- `references/agentic-review.md` - agentic test review, implementation review, fix-worker loop, and mock/fixture rejection rules.
- `references/qa-acceptance.md` - phase acceptance gate, service-wiring verification, no-mock policy, platform E2E expectations, and acceptance packet contents.
- `references/lessons.md` - lesson candidate rules, phase-owner promotion criteria, `docs/lessons` creation, and `AGENTS.md` pointers.
- `references/consistency-handoff.md` - batched plan consistency updates, compact actual-vs-planned notes, context handoffs, and final output.

## Workflow

1. Load `references/state-files.md` and create or resume the run state.
2. Load `references/supervisor.md` and choose the current phase from `run.yaml`.
3. Load `references/phase-owner.md` and `references/branch-worktree.md` before starting or resuming the active phase.
4. Build the active frontier from plan dependencies, task statuses, shared-resource constraints, and active worker lanes.
5. Dispatch only substantial independent worker lanes. Keep glue, integration, small edits, and acceptance ownership with the phase owner.
6. For behavior work, use `references/worker-tdd.md`: test-only goal first, agentic test approval, then implementation.
7. Use `references/agentic-review.md` for test review, implementation review, and fix loops.
8. After each worker result, the phase owner integrates, runs the lane checkpoint, updates `phase.yaml`, and batches any needed plan consistency notes.
9. Use `references/qa-acceptance.md` before marking a phase complete.
10. Use `references/lessons.md` when worker/reviewer results reveal a recurring proven problem future agents should avoid.
11. Use `references/consistency-handoff.md` for downstream plan updates, handoffs, final reporting, or blocked states.

## Non-Negotiables

- Do not use SQLite as workflow state.
- Do not use Linear as workflow state.
- Do not base execution on deprecated Linear/SQLite implementation supervisor skills.
- Do not create PR/MR per task by default.
- Do not write huge markdown review packets.
- Do not save full stdout in YAML or markdown.
- Do not delegate every task by default.
- Do not let workers spawn workers.
- Do not accept mock-only completion for service wiring that requires real integration proof.
- Do not mark a phase complete until the phase acceptance gate passes and the acceptance packet exists.

## Handoff

When pausing or completing, report:

```markdown
Implementation execution status: <running|blocked|complete>

Run state:
- `<run.yaml path>`

Current phase:
- `<phase plan path>` - <status>
- `<phase.yaml path>`

Evidence:
- Acceptance packet: `<path or none yet>`
- QA artifacts: `<directory>`

Blocked or escalated:
- <item or "None">
```
