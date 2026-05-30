# Supervisor

The supervisor is a durable run/process manager, not a chatty project manager. It owns the run, phase order, phase transitions, orchestrator processes, escalations, and final handoff.

## Responsibilities

- Load or create `run.yaml`.
- Discover the SLICES document at `docs/plans/SLICES.md` when no path is provided, then select the current phase from ordered phase plans.
- Track execution scope: `run` by default for a phases document or multiple phase plans; `single-phase` only when the user explicitly asks to run one phase only.
- Record the current supervisor Codex thread id and tmux session/window/pane identity before launching the orchestrator so the watchdog can start a transition-router turn on this same supervisor thread.
- Create or refresh the compact execution manifest for the active phase before launching the orchestrator.
- Spawn or resume one top-level Codex CLI phase orchestrator for the active phase in a new pane in the current tmux window; if tmux/Codex process spawning is unavailable, block and repair the launch path instead of falling back to inline orchestration.
- Verify any recorded orchestrator pane before trusting it; state files are hints, not proof that a valid orchestrator is running.
- Start a deterministic watchdog for the active phase in the same tmux session as the original supervisor after orchestrator startup is validated.
- End the supervisor Codex turn after launch/watchdog setup; resume this same supervisor thread as a transition router through `codex app-server` when the watchdog triggers an actionable lifecycle event.
- Append compact supervisor events to `docs/implementation-runs/<run-id>/events/supervisor.jsonl`.
- Store discovered raw Codex session id/path when available, but do not parse raw session logs as workflow state during normal execution.
- Keep supervisor, phase orchestrator, and worker responsibilities distinct.
- Ensure each active phase has a phase branch/worktree recorded in `phase.yaml`, or a recorded fallback reason when worktrees are unavailable.
- Let the watchdog poll only the compact supervisor inbox for the active phase during normal work, using `sleep 120` between checks by default; do not keep an interactive supervisor LLM turn alive just to wait.
- Keep phase execution sequential unless phases are explicitly independent.
- Ensure only allowed escalations stop autonomous work, and that agent-owned setup/dependency blockers have blocker-resolver evidence before they reach the supervisor.
- Ensure phase completion requires the phase acceptance gate and packet.
- Merge each accepted phase branch/worktree back into the run base branch before advancing `run.yaml` to the next phase.
- Terminate the completed phase orchestrator tmux pane/session after the native phase-merge sub-agent records merge-back results and before launching the next phase orchestrator.
- Start the next phase orchestrator/watchdog immediately after merge-back and completed-orchestrator teardown are recorded, then spawn the post-advance phase-transition sub-agent for local verification and smoke reporting.
- Print the transition sub-agent's local verification smoke-test report for the human when it is ready, without blocking the already-started next phase.
- Launch workflow-auditor as a background, non-blocking follow-up after phase transitions or notable workflow friction. The audit writes a global report for later human review and must not delay next-phase startup, local verification, smoke-report printing, escalation routing, or any other supervisor-owned work.
- Batch plan consistency updates after phase or lane integration, not after every tiny edit.

## Execution Flow

1. Load `run.yaml`, or create it from `docs/plans/SLICES.md` when no run exists and no slices path was provided.
2. Load the current phase plan, `phases/<phase-slug>.yaml`, and existing manifest if present.
3. If `phase.yaml` does not exist, initialize it from the phase plan.
4. Create or refresh `docs/implementation-runs/<run-id>/manifests/<phase-slug>.yaml` from the phase plan, store its path in `phase.yaml`, and append a compact manifest event.
5. Ensure the phase branch/worktree exists or instruct the phase orchestrator to create it before implementation starts.
6. Ensure `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml` exists with `orchestrator_status: starting`.
7. Record and validate the current supervisor Codex thread id plus session/window/pane in `run.yaml` before launching or resuming the orchestrator. The watchdog must use this recorded supervisor thread as its only wake target.
8. If `run.yaml` or the inbox records an existing orchestrator pane, validate it before resuming. If validation fails, restart the orchestrator unless doing so would risk losing unrecorded state.
9. Start or resume the phase orchestrator in a new pane in the current tmux window and record its pane/process identity in `run.yaml` and the inbox.
10. Require startup acknowledgement in the inbox. It must name the expected manifest path and pane id before the supervisor treats the orchestrator as running.
11. Start a watchdog script for the compact inbox in the same tmux session as the original supervisor, preferably in a dedicated workflow window that can also host local verification panes. Pass it the recorded supervisor thread id plus pane/window/session for human visibility. Record `active_watchdog` in `run.yaml`, including the watchdog pane and Codex app-server wake target. Append a `watchdog_started` event and return a running status to the user that includes the watchdog tmux target. Do not keep the supervisor Codex turn alive as a polling loop.
12. The watchdog polls the inbox using `sleep 120` between checks, validates basic pane/heartbeat health, and writes a trigger file only when it sees escalation, restart, graceful exit, phase completion, heartbeat expiry, or pane death. It must print one-line status logs in its pane for startup, every poll, inbox decisions, pane/heartbeat checks, trigger creation, and supervisor wake results. Do not mirror those lines into a separate watchdog log file.
13. When the watchdog starts a transition turn on the recorded supervisor thread through the Codex app-server control plane, act as a short supervisor transition router. Load only `run.yaml`, the trigger YAML, the compact inbox, and `transitions/<phase>.yaml` when handling phase completion. If the watchdog reports `wake_method: blocked` because the original supervisor thread could not be resumed or the turn could not be started, repair the control-plane communication path before continuing; do not create a replacement transition-handler pane.
14. If the trigger reports `blocked`, update `run.yaml`, preserve the orchestrator pane, and write a handoff only when needed.
15. If the trigger reports `graceful_exit`, heartbeat expiry, pane death, or restart needed, validate current state and either restart the orchestrator/watchdog or mark the run blocked if restart would risk losing unrecorded state.
16. If the trigger reports `phase_completion` and no phase-merge sub-agent is running, verify only the routing gate: acceptance packet path exists, transition handoff/report path exists, required accepted commit field is present, and the trigger/inbox paths are valid enough to delegate. Then create or open `transitions/<phase>.yaml`, load `references/phase-merge-worker.md`, spawn a native phase-merge sub-agent, record `merge_worker.status: running` plus the native sub-agent id in the transition YAML, and wait for its structured result.
17. When the phase-merge sub-agent reports `ready_for_supervisor`, perform only high-level lifecycle work: validate the merge result paths and resulting base commit, terminate the completed phase orchestrator pane/session, mark the phase-completion trigger handled, set completed phase/next phase state from the merge result, and append compact events.
18. Terminate the completed phase orchestrator tmux pane/session after phase-merge-worker state is safely recorded. Prefer `tmux kill-pane -t <orchestrator-pane>` for a pane in the supervisor window; use `tmux kill-session -t <orchestrator-session>` only when the orchestrator owns a dedicated session. Record the command/result in `transitions/<phase>.yaml`, mirror only minimal active-orchestrator status in `run.yaml`, and append a compact `orchestrator_stopped` event. Do not kill the original supervisor pane, watchdog pane, transition sub-agent-owned local verification pane, or any worker pane that still contains unrecorded state.
19. If execution scope is `run` and another phase remains, load `references/supervisor-orchestrator-process.md` and `references/supervisor-watchdog.md`, then immediately start the next phase orchestrator and watchdog from the updated base branch. Record next-phase startup before doing local verification for the completed phase.
20. After next-phase startup is recorded, or immediately after completed-orchestrator teardown when no next phase remains, load `references/phase-transition-worker.md`, spawn a native post-advance phase-transition sub-agent for the completed phase, record `transition_worker.status: running` plus the native sub-agent id in `transitions/<phase>.yaml`, and wait for its structured result. The transition sub-agent handles local setup, local verification, and smoke-report artifact creation from the completed phase handoff/report.
21. When the phase-transition sub-agent reports `ready_for_report`, print a user-facing smoke-test report in the supervisor pane, including the local URL or blocker, the new expected behavior checklist from the transition sub-agent's smoke report artifact, any setup caveats, and artifact paths. Keep the next phase running when it has already started.
22. After the required transition work is recorded and without waiting for completion, optionally start a background workflow-auditor run using `~/.codex/skills/workflow-auditor/SKILL.md`. Pass the run directory, transition YAML, supervisor/orchestrator/worker session-log references, and any notable friction. The auditor writes one report under `~/.codex/workflow-audits/`; the supervisor may record the expected report path or background process id, but must continue normal responsibilities immediately.
23. Stop only when all phases in scope are complete, an allowed escalation blocks progress, context handoff is required, or the user explicitly stops.

## Escalation Policy

Escalate only for:

- credentials, secrets, private keys, or account access unavailable through approved local setup;
- paid account setup, billing, quota purchase, vendor approval, or external allowlist;
- product, legal, privacy, security, or compliance decisions not answered by source docs;
- destructive production actions, real customer data access, or irreversible external side effects;
- unavailable physical devices, entitlements, or external services after a blocker-resolver or other agent-owned attempt.

Everything else is agent-owned setup or implementation work.

If an escalation artifact shows a setup/dependency/runtime/env/workflow blocker without blocker-resolver evidence, route it back to the orchestrator as `restart_needed` or `escalation_rejected_agent_owned` instead of stopping the run for the human.

## Role Separation

Treat the workflow as four roles:

- Supervisor: run-level state machine, phase ordering, escalation policy, final handoff.
- Phase orchestrator: active frontier, worker dispatch, integration checkpoints, acceptance-worker dispatch, `phase.yaml`, plan consistency.
- Worker: bounded implementation, test proposal, implementation result, acceptance verification, evidence, no scheduling.
- Blocker-resolver: bounded setup/dependency/runtime/env/workflow unblocking, retry evidence, and true-blocker reports.

The supervisor does not implement phase tasks, choose implementation lanes, spawn implementation workers, spawn blocker-resolvers, merge phase branches, run local verification, or inspect detailed phase state during normal work. It maintains durable run state, enforces the phase branch/worktree topology, starts/stops orchestrator tmux panes, starts/stops deterministic watchdogs, routes phase-completion triggers to native phase-merge sub-agents, spawns post-advance transition sub-agents, prints transition smoke reports, records true escalations or handoffs, starts the next phase orchestrator after merge-back when the run scope continues, and may start background workflow-auditor runs for later review. The watchdog wakes this original supervisor thread through Codex app-server for transition routing; a replacement supervisor Codex session is not part of the workflow.

## Operational Modules

Load these focused references only for the relevant supervisor action:

- `references/supervisor-orchestrator-process.md` for tmux orchestrator launch, launch autonomy, pane validation, invalid-pane recovery, and next-phase orchestrator startup.
- `references/codex-mcp-control-plane.md` for Codex app-server supervisor thread wakeups.
- `references/supervisor-watchdog.md` for same-session watchdog creation, trigger generation, transition-router wake behavior, and watchdog script shape.
- `references/phase-merge-worker.md` for native phase-merge sub-agent launch and merge-result contract.
- `references/phase-transition-worker.md` for post-advance native phase-transition sub-agent launch and smoke-report result contract.
- `~/.codex/skills/workflow-auditor/SKILL.md` for optional background workflow audits that analyze session logs and workflow artifacts after phase transitions. This is not a blocking supervisor module.

Supervisor must not:

- select the next implementation task/lane;
- spawn implementation workers;
- spawn blocker-resolvers;
- rewrite worker goals;
- load task-specific implementation modules to move the phase forward;
- poll detailed worker/orchestrator state beyond the compact inbox during normal execution.
- keep an interactive supervisor Codex turn alive only to wait for the orchestrator.
- approve, reject, or answer Codex edit/command prompts in the orchestrator pane with `tmux send-keys`. Watchdog communication uses Codex app-server, not terminal keystrokes.
- approve worker edits on behalf of the orchestrator.
- run broad log reads, full-plan dumps, full diffs, or raw Codex session-log parsing during the normal polling loop.
- wait for workflow-auditor reports, review them inline, or make workflow auditing a prerequisite for next-phase startup, transition verification, smoke-report printing, or escalation handling.

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
