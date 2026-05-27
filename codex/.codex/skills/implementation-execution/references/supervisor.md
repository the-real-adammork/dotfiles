# Supervisor

The supervisor is a durable state machine, not a chatty project manager. It owns the run, phase order, state files, escalations, and final handoff.

## Responsibilities

- Load or create `run.yaml`.
- Select the current phase from ordered phase plans.
- Track execution scope: `run` by default for a phases document or multiple phase plans; `single-phase` only when the user explicitly asks to run one phase only.
- Spawn or resume one phase owner/orchestrator for the active phase when agent dispatch is available; record an inline fallback only when dispatch is unavailable.
- Keep supervisor, phase-owner, and worker responsibilities distinct when agent dispatch is available.
- Ensure each active phase has a phase branch/worktree recorded in `phase.yaml`, or a recorded fallback reason when worktrees are unavailable.
- Keep phase execution sequential unless phases are explicitly independent.
- Ensure only allowed escalations stop autonomous work.
- Ensure phase completion requires the phase acceptance gate and packet.
- Batch plan consistency updates after phase or lane integration, not after every tiny edit.

## Execution Flow

1. Load `run.yaml`.
2. Load the current phase plan and `phases/<phase-slug>.yaml`.
3. If `phase.yaml` does not exist, initialize it from the phase plan.
4. Ensure the phase branch/worktree exists or instruct the phase owner to create it before implementation starts.
5. Spawn or resume the phase owner/orchestrator for the active phase when agent dispatch is available, and record its identity in `phase.yaml`.
6. Receive worker dispatch requests from the phase owner. Spawn the requested workers from the supervisor context because workers cannot be spawned by sub-agents in single-level runtimes.
7. Route worker result YAML and artifact paths back into the phase-owner integration flow.
8. When the phase owner reports the phase is acceptance-ready, verify the phase acceptance gate, packet, service-wiring coverage, mock/fixture ledger, and state updates.
9. If blocked, update `run.yaml` and write a handoff only when needed.
10. If the phase acceptance gate passes, mark the phase complete and update `run.yaml`.
11. If execution scope is `run` and another phase remains, immediately start the next phase owner/orchestrator.
12. Stop only when all phases in scope are complete, an allowed escalation blocks progress, context handoff is required, or the user explicitly stops.

## Escalation Policy

Escalate only for:

- credentials, secrets, private keys, or account access unavailable through approved local setup;
- paid account setup, billing, quota purchase, vendor approval, or external allowlist;
- product, legal, privacy, security, or compliance decisions not answered by source docs;
- destructive production actions, real customer data access, or irreversible external side effects;
- unavailable physical devices, entitlements, or external services after an agent-owned attempt.

Everything else is agent-owned setup or implementation work.

## Role Separation

Treat the workflow as three roles:

- Supervisor: run-level state machine, phase ordering, escalation policy, final handoff.
- Phase owner/orchestrator: active frontier, worker dispatch requests, integration checkpoints, `phase.yaml`, acceptance packet, plan consistency.
- Worker: bounded implementation, test proposal, implementation result, evidence, no scheduling.

The supervisor does not implement phase tasks. It maintains durable run state, enforces the branch/worktree topology, performs actual worker spawning, routes worker results to the phase-owner integration flow, checks that workers are used for substantial implementation, verifies acceptance state before phase advancement, records escalations or handoffs, and starts the next phase owner/orchestrator after completion when the run scope continues.

If the environment provides sub-agent dispatch, the supervisor uses it for the phase owner/orchestrator role and for worker roles. A phase owner may execute only tiny bootstrap or glue edits directly when delegating would cost more than the edit itself.

If phase-owner dispatch is unavailable, the supervisor may emulate the phase-owner role inline, but it must:

- record `role_separation.phase_owner_dispatch_available: false`;
- record `role_separation.phase_owner_inline_reason`;
- still preserve phase-owner responsibilities separately from worker evidence.

If worker dispatch is unavailable, the current session may emulate worker execution, but it must:

- create or update worker result YAML for substantial implementation chunks;
- keep phase-owner state updates separate from worker evidence;
- record `role_separation.worker_dispatch_available: false` and `role_separation.worker_dispatch_fallback_reason`;
- avoid using this fallback as a reason to skip TDD, review, mock/fixture ledger, or acceptance gates.

## Linear And SQLite

Do not use Linear or SQLite as workflow state. If Linear is present, treat it as an optional compact mirror only. The canonical execution state is the YAML run directory.
