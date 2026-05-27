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
- optional execution scope, default `run` when a phases document or multiple phase plans are provided, and `single-phase` only when the user explicitly asks to run one phase only;
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

One supervisor owns the run. One long-running phase owner owns each active phase. Worker agents handle substantial bounded implementation lanes, including serial lanes that cannot run in parallel. Workers cannot spawn workers or coordinate directly with sibling workers. The supervisor/phase owner is the only scheduler and integrator.

Supervisor, phase owner, and worker are distinct responsibilities. On skill start, the current top-level Codex session is the supervisor and dispatcher. When agent dispatch is available, the supervisor must spawn a phase owner/orchestrator for the active phase. The orchestrator does not spawn workers directly. Instead, the orchestrator builds the active frontier and returns worker dispatch requests to the supervisor. The supervisor spawns workers, routes worker results back into the phase-owner integration flow, handles phase completion, updates `run.yaml`, and starts the next phase owner/orchestrator.

If the runtime supports only single-level sub-agents, supervisor-mediated dispatch is required: the supervisor spawns the orchestrator, receives its dispatch requests, then the supervisor spawns workers. If phase-owner or worker dispatch is unavailable, the top-level session may emulate that role, but it must record the limitation in `phase.yaml` or the handoff and still use worker-style result YAML for substantial implementation chunks.

Human involvement is only for allowed escalations: credentials/secrets, paid/vendor setup, unresolved product/legal/security decisions, destructive production actions, real customer data access, or unavailable real dependencies after an agent-owned attempt.

## Reference Modules

Load only the module needed for the current action:

- `references/state-files.md` - create, update, and resume `run.yaml`, `phase.yaml`, worker result YAML, handoffs, acceptance packets, and evidence artifacts.
- `references/supervisor.md` - run-level state machine, phase order, active phase selection, resumability, and escalation behavior.
- `references/phase-owner.md` - phase-owner orchestration, active frontier construction, worker lane selection, `/goal` usage, integration checkpoints, and phase branch ownership.
- `references/branch-worktree.md` - phase branch, worker branch/worktree isolation, merge-back rules, and parallel lane safety.
- `references/worker-tdd.md` - bounded worker contract, two-stage TDD flow, test proposal approval, implementation, worker result YAML, and worker restrictions.
- `references/agentic-review.md` - agentic test review, implementation review, fix-worker loop, and mock/fixture ledger review rules.
- `references/qa-acceptance.md` - phase acceptance gate, service-wiring verification, mock/fixture ledger reconciliation, platform E2E expectations, and acceptance packet contents.
- `references/lessons.md` - lesson candidate rules, phase-owner promotion criteria, `docs/lessons` creation, and `AGENTS.md` pointers.
- `references/consistency-handoff.md` - batched plan consistency updates, compact actual-vs-planned notes, context handoffs, and final output.
- Use `$secrets` before generating, writing, revealing, hiding, staging, committing, or reviewing secrets, credentials, env files, database passwords, app keys, API tokens, or secret-bearing config.

## Workflow

1. Load `references/state-files.md` and create or resume the run state.
2. Load `references/supervisor.md` and choose the current phase from `run.yaml`.
3. Load `references/phase-owner.md` and `references/branch-worktree.md` before starting or resuming the active phase.
4. Spawn or resume the phase owner/orchestrator for the active phase when agent dispatch is available; otherwise record an inline-orchestrator fallback. The orchestrator builds the active frontier from plan dependencies, task statuses, shared-resource constraints, and active worker lanes.
5. The orchestrator returns worker dispatch requests for substantial implementation lanes. The supervisor spawns those workers, even when only one lane is currently available. Keep glue, integration, tiny edits, state updates, and acceptance ownership with the phase owner.
6. For behavior work, use `references/worker-tdd.md`: test-only goal first, agentic test approval, then implementation.
7. Use `references/agentic-review.md` for test review, implementation review, and fix loops.
8. After each worker result, the phase owner integrates, runs the lane checkpoint, updates `phase.yaml`, reconciles mock/fixture ledger entries, and batches any needed plan consistency notes.
9. Use `references/qa-acceptance.md` before marking a phase complete.
10. If execution scope is `run` and another phase remains, the supervisor must continue by starting the next phase owner/orchestrator. Do not stop after a successful phase unless the user explicitly requested `single-phase`, an allowed escalation blocks progress, context handoff is required, or the user stops the workflow.
11. Use `references/lessons.md` when worker/reviewer results reveal a recurring proven problem future agents should avoid.
12. Use `references/consistency-handoff.md` for downstream plan updates, handoffs, final reporting, or blocked states.

## Non-Negotiables

- Do not use SQLite as workflow state.
- Do not use Linear as workflow state.
- Do not base execution on deprecated Linear/SQLite implementation supervisor skills.
- Do not create PR/MR per task by default.
- Do not write huge markdown review packets.
- Do not save full stdout in YAML or markdown.
- Do not keep the phase owner/orchestrator inline when agent dispatch is available; spawn the orchestrator and record it in `phase.yaml`.
- Do not make the phase owner the default implementer for substantial code/test changes; use workers for implementation lanes even when execution is serial.
- Do not delegate tiny glue, state updates, acceptance packet edits, or integration decisions by default.
- Do not let workers spawn workers.
- Do not accept mock-only completion for service wiring that requires real integration proof.
- Do not ban useful mocks/fixtures during implementation; track them in the mock/fixture ledger and reconcile them before phase completion.
- Do not mark a phase complete until the phase acceptance gate passes and the acceptance packet exists.
- Do not stop after a phase completes while `run.yaml` points at another phase, unless execution scope is explicitly `single-phase`, an allowed escalation blocks progress, context handoff is required, or the user stops the workflow.
- Do not commit plaintext unsafe secrets; use `$secrets` for classification, generation, `git-secret`, and verification.

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
