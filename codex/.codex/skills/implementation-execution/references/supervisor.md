# Supervisor

The supervisor is a durable run/process manager, not a chatty project manager. It owns the run, phase order, phase transitions, orchestrator processes, escalations, and final handoff.

## Responsibilities

- Load or create `run.yaml`.
- Discover the SLICES document at `docs/plans/SLICES.md` when no path is provided, then select the current phase from ordered phase plans.
- Track execution scope: `run` by default for a phases document or multiple phase plans; `single-phase` only when the user explicitly asks to run one phase only.
- Record the current supervisor Codex tmux pane/window identity before launching the orchestrator so the watchdog can wake this same supervisor session for transition work.
- Create or refresh the compact execution manifest for the active phase before launching the orchestrator.
- Spawn or resume one top-level Codex CLI phase orchestrator for the active phase in a new pane in the current tmux window; record an inline fallback only when tmux/Codex process spawning is unavailable.
- Verify any recorded orchestrator pane before trusting it; state files are hints, not proof that a valid orchestrator is running.
- Start a detached deterministic watchdog for the active phase after orchestrator startup is validated.
- End the supervisor Codex turn after launch/watchdog setup; resume this same supervisor pane as a transition handler when the watchdog triggers an actionable lifecycle event.
- Append compact supervisor events to `docs/implementation-runs/<run-id>/events/supervisor.jsonl`.
- Store discovered raw Codex session id/path when available, but do not parse raw session logs as workflow state during normal execution.
- Keep supervisor, phase orchestrator, and worker responsibilities distinct.
- Ensure each active phase has a phase branch/worktree recorded in `phase.yaml`, or a recorded fallback reason when worktrees are unavailable.
- Let the watchdog poll only the compact supervisor inbox for the active phase during normal work, using `sleep 120` between checks by default; do not keep an interactive supervisor LLM turn alive just to wait.
- Keep phase execution sequential unless phases are explicitly independent.
- Ensure only allowed escalations stop autonomous work.
- Ensure phase completion requires the phase acceptance gate and packet.
- Merge each accepted phase branch/worktree back into the run base branch before advancing `run.yaml` to the next phase.
- Terminate the completed phase orchestrator tmux pane/session after accepted phase merge-back and before launching the next phase orchestrator.
- After each successful phase merge-back, prepare and launch the project locally from the updated base branch/worktree for human verification, unless an allowed escalation prevents it.
- Batch plan consistency updates after phase or lane integration, not after every tiny edit.

## Execution Flow

1. Load `run.yaml`, or create it from `docs/plans/SLICES.md` when no run exists and no slices path was provided.
2. Load the current phase plan, `phases/<phase-slug>.yaml`, and existing manifest if present.
3. If `phase.yaml` does not exist, initialize it from the phase plan.
4. Create or refresh `docs/implementation-runs/<run-id>/manifests/<phase-slug>.yaml` from the phase plan, store its path in `phase.yaml`, and append a compact manifest event.
5. Ensure the phase branch/worktree exists or instruct the phase orchestrator to create it before implementation starts.
6. Ensure `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml` exists with `orchestrator_status: starting`.
7. Record and validate the current supervisor pane/window in `run.yaml` before launching or resuming the orchestrator. The watchdog must use this recorded supervisor pane as its primary wake target.
8. If `run.yaml` or the inbox records an existing orchestrator pane, validate it before resuming. If validation fails, restart the orchestrator unless doing so would risk losing unrecorded state.
9. Start or resume the phase orchestrator in a new pane in the current tmux window and record its pane/process identity in `run.yaml` and the inbox.
10. Require startup acknowledgement in the inbox. It must name the expected manifest path and pane id before the supervisor treats the orchestrator as running.
11. Start a detached watchdog script for the compact inbox. Pass it the recorded supervisor pane/window. Record `supervisor_watchdog` in `run.yaml`, append a `watchdog_started` event, and return a running status to the user. Do not keep the supervisor Codex turn alive as a polling loop.
12. The watchdog polls the inbox using `sleep 120` between checks, validates basic pane/heartbeat health, and writes a trigger file only when it sees escalation, restart, graceful exit, phase completion, heartbeat expiry, or pane death.
13. When the watchdog wakes the recorded supervisor pane with a trigger prompt, act as a short supervisor transition handler. Load only `run.yaml`, the trigger YAML, the compact inbox, and the narrow transition files required by the trigger. A fresh Codex transition-handler pane is valid only when the original supervisor pane could not be validated and the fallback is recorded.
14. If the trigger reports `blocked`, update `run.yaml`, preserve the orchestrator pane, and write a handoff only when needed.
15. If the trigger reports `graceful_exit`, heartbeat expiry, pane death, or restart needed, validate current state and either restart the orchestrator/watchdog or mark the run blocked if restart would risk losing unrecorded state.
16. If the trigger reports `phase_completion`, verify only the transition gate: acceptance packet exists, transition handoff/report exists, `phase.yaml` says complete/acceptance passed, required commit/artifact paths exist, and the phase worktree is clean or has expected state.
17. Load `references/phase-merge-back.md`, then merge or reconcile the accepted phase branch/worktree back into the run base branch before advancing `run.yaml` to the next phase. Prefer fast-forward when valid, but preserve or reasonably reconcile dirty/ad-hoc base worktree changes and escalate only critical mismatches.
18. If phase completion verification and base-branch merge/reconciliation pass, run the lightweight post-merge verification needed to catch integration drift.
19. Immediately record the phase completion in `run.yaml`: completed phase entry, accepted phase commit, base commit after merge, acceptance packet, transition handoff/report, stopped completed watchdog, completed/closing orchestrator state, handled trigger, and the next `current_phase` when another phase remains. Do this before local verification setup so a long-running dev server launch cannot leave the run state stale.
20. Terminate the completed phase orchestrator tmux pane/session after its state is safely recorded. Prefer `tmux kill-pane -t <orchestrator-pane>` for a pane in the supervisor window; use `tmux kill-session -t <orchestrator-session>` only when the orchestrator owns a dedicated session. Record the command/result in `run.yaml` and append a compact `orchestrator_stopped` event. Do not kill the original supervisor pane, watchdog fallback pane, local verification pane/session, or any worker pane that still contains unrecorded state.
21. Load `references/local-verification.md`, then from the updated base branch/worktree perform post-merge local verification setup from the orchestrator's transition handoff/report: install or refresh dependencies, apply local setup steps, start required local services, run the app or service locally, capture the process identity, determine the reachable `localhost` URL/port, and write concise smoke-test instructions for the human. Use repo docs/scripts only to validate or fill gaps in the handoff/report. If a real allowed escalation blocks local launch, record the blocker and any partial setup completed.
22. Update the completed phase entry in `run.yaml` with local verification status, URL, process identity, artifacts, smoke-test checklist, or blocker.
23. Print a user-facing smoke-test report in the supervisor pane, including the local URL or blocker, the new expected behavior checklist from the transition handoff/report, any setup caveats, and artifact paths.
24. If execution scope is `run` and another phase remains, load `references/supervisor-orchestrator-process.md` and `references/supervisor-watchdog.md`, then immediately start the next phase orchestrator and watchdog from the updated base branch while the local verification run remains available when feasible. End the supervisor turn with running status that includes the localhost URL and smoke-test instructions.
25. Stop only when all phases in scope are complete, an allowed escalation blocks progress, context handoff is required, or the user explicitly stops.

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
- Phase orchestrator: active frontier, worker dispatch, integration checkpoints, `phase.yaml`, acceptance packet, plan consistency.
- Worker: bounded implementation, test proposal, implementation result, evidence, no scheduling.

The supervisor does not implement phase tasks, choose implementation lanes, spawn workers, or inspect detailed phase state during normal work. It maintains durable run state, enforces the phase branch/worktree topology, starts/stops orchestrator tmux panes, starts/stops deterministic watchdogs, verifies phase transition gates, records escalations or handoffs, and starts the next phase orchestrator after completion when the run scope continues. The watchdog wakes this original supervisor pane for transition handling; a replacement supervisor Codex session is only a recorded fallback.

## Operational Modules

Load these focused references only for the relevant supervisor action:

- `references/supervisor-orchestrator-process.md` for tmux orchestrator launch, launch autonomy, pane validation, invalid-pane recovery, and next-phase orchestrator startup.
- `references/supervisor-watchdog.md` for detached watchdog creation, trigger generation, transition-handler wake behavior, and watchdog script shape.
- `references/phase-merge-back.md` for accepted phase merge-back, dirty base worktree handling, merge reconciliation, autonomous conflict decisions, and post-merge verification.
- `references/local-verification.md` for post-merge local dependency setup, service startup, localhost URL detection, process recording, allowed blockers, and smoke-test reporting.

Supervisor must not:

- select the next implementation task/lane;
- spawn workers;
- rewrite worker goals;
- load task-specific implementation modules to move the phase forward;
- poll detailed worker/orchestrator state beyond the compact inbox during normal execution.
- keep an interactive supervisor Codex turn alive only to wait for the orchestrator.
- approve, reject, or answer Codex edit/command prompts in the orchestrator pane with `tmux send-keys`. `tmux send-keys` is reserved for the watchdog waking the recorded supervisor pane with a transition prompt.
- approve worker edits on behalf of the orchestrator.
- run broad log reads, full-plan dumps, full diffs, or raw Codex session-log parsing during the normal polling loop.

If the orchestrator pane shows a Codex approval prompt, treat it as a process launch/configuration failure. Do not press `y`, `a`, or otherwise answer the prompt. Capture a short pane excerpt if useful, then restart the orchestrator with `--dangerously-bypass-approvals-and-sandbox` or mark the run blocked if restart would risk losing unrecorded state.

## Compact Inbox Contract

The watchdog polls only:

```text
docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml
```

Example:

```yaml
phase: "phase-2"
orchestrator_status: running # starting | running | blocked | acceptance_ready | complete | failed | exiting
updated_at: "YYYY-MM-DDTHH:MM:SSZ"
heartbeat_expires_at: "YYYY-MM-DDTHH:MM:SSZ"
tmux:
  pane_id: "%12"
codex_session:
  id: "019e..."
  path: "/Users/example/.codex/sessions/YYYY/MM/DD/session.jsonl"
startup:
  acknowledged: true
  manifest: "docs/implementation-runs/<run-id>/manifests/<phase>.yaml"
request:
  type: none # none | escalation | phase_completion | graceful_exit | restart_needed
  reason: null
  artifact: null
phase_completion:
  phase_yaml: "docs/implementation-runs/<run-id>/phases/<phase>.yaml"
  acceptance_packet: null
  transition_handoff: null
  commit: null # full 40-character commit hash when populated
```

The supervisor should not poll detailed phase internals. On `phase_completion`, it may run the narrow transition verification listed in the execution flow.

## Linear And SQLite

Do not use Linear or SQLite as workflow state. If Linear is present, treat it as an optional compact mirror only. The canonical execution state is the YAML run directory.
