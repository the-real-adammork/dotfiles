# Supervisor

The supervisor is a durable run/process manager, not a chatty project manager. It owns the run, phase order, phase transitions, orchestrator processes, escalations, and final handoff.

## Responsibilities

- Load or create `run.yaml`.
- Discover the SLICES document at `docs/plans/SLICES.md` when no path is provided, then select the current phase from ordered phase plans.
- Track execution scope: `run` by default for a phases document or multiple phase plans; `single-phase` only when the user explicitly asks to run one phase only.
- Create or refresh the compact execution manifest for the active phase before launching the orchestrator.
- Spawn or resume one top-level Codex CLI phase orchestrator for the active phase in a new pane in the current tmux window; record an inline fallback only when tmux/Codex process spawning is unavailable.
- Verify any recorded orchestrator pane before trusting it; state files are hints, not proof that a valid orchestrator is running.
- Start a detached deterministic watchdog for the active phase after orchestrator startup is validated.
- End the supervisor Codex turn after launch/watchdog setup; resume only as a transition handler when the watchdog triggers an actionable lifecycle event.
- Append compact supervisor events to `docs/implementation-runs/<run-id>/events/supervisor.jsonl`.
- Store discovered raw Codex session id/path when available, but do not parse raw session logs as workflow state during normal execution.
- Keep supervisor, phase orchestrator, and worker responsibilities distinct.
- Ensure each active phase has a phase branch/worktree recorded in `phase.yaml`, or a recorded fallback reason when worktrees are unavailable.
- Let the watchdog poll only the compact supervisor inbox for the active phase during normal work, using `sleep 120` between checks by default; do not keep an interactive supervisor LLM turn alive just to wait.
- Keep phase execution sequential unless phases are explicitly independent.
- Ensure only allowed escalations stop autonomous work.
- Ensure phase completion requires the phase acceptance gate and packet.
- Merge each accepted phase branch/worktree back into the run base branch before advancing `run.yaml` to the next phase.
- Batch plan consistency updates after phase or lane integration, not after every tiny edit.

## Execution Flow

1. Load `run.yaml`, or create it from `docs/plans/SLICES.md` when no run exists and no slices path was provided.
2. Load the current phase plan, `phases/<phase-slug>.yaml`, and existing manifest if present.
3. If `phase.yaml` does not exist, initialize it from the phase plan.
4. Create or refresh `docs/implementation-runs/<run-id>/manifests/<phase-slug>.yaml` from the phase plan, store its path in `phase.yaml`, and append a compact manifest event.
5. Ensure the phase branch/worktree exists or instruct the phase orchestrator to create it before implementation starts.
6. Ensure `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml` exists with `orchestrator_status: starting`.
7. If `run.yaml` or the inbox records an existing orchestrator pane, validate it before resuming. If validation fails, restart the orchestrator unless doing so would risk losing unrecorded state.
8. Start or resume the phase orchestrator in a new pane in the current tmux window and record its pane/process identity in `run.yaml` and the inbox.
9. Require startup acknowledgement in the inbox. It must name the expected manifest path and pane id before the supervisor treats the orchestrator as running.
10. Start a detached watchdog script for the compact inbox. Record `supervisor_watchdog` in `run.yaml`, append a `watchdog_started` event, and return a running status to the user. Do not keep the supervisor Codex turn alive as a polling loop.
11. The watchdog polls the inbox using `sleep 120` between checks, validates basic pane/heartbeat health, and writes a trigger file only when it sees escalation, restart, graceful exit, phase completion, heartbeat expiry, or pane death.
12. When resumed by a watchdog trigger, act as a short supervisor transition handler. Load only `run.yaml`, the trigger YAML, the compact inbox, and the narrow transition files required by the trigger.
13. If the trigger reports `blocked`, update `run.yaml`, preserve the orchestrator pane, and write a handoff only when needed.
14. If the trigger reports `graceful_exit`, heartbeat expiry, pane death, or restart needed, validate current state and either restart the orchestrator/watchdog or mark the run blocked if restart would risk losing unrecorded state.
15. If the trigger reports `phase_completion`, verify only the transition gate: acceptance packet exists, `phase.yaml` says complete/acceptance passed, required commit/artifact paths exist, and the phase worktree is clean or has expected state.
16. Fast-forward the accepted phase branch/worktree back into the run base branch. Do this before advancing `run.yaml` to the next phase. If the base branch has diverged from the phase branch, stop with a supervisor escalation/handoff instead of silently chaining or creating an unplanned merge.
17. If phase completion verification and base-branch merge pass, mark the phase complete in `run.yaml`, gracefully stop or close the completed orchestrator pane, stop the completed watchdog, and update `run.yaml` to the next phase.
18. If execution scope is `run` and another phase remains, immediately start the next phase orchestrator and watchdog from the updated base branch, then end the supervisor turn with running status.
19. Stop only when all phases in scope are complete, an allowed escalation blocks progress, context handoff is required, or the user explicitly stops.

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

The supervisor does not implement phase tasks, choose implementation lanes, spawn workers, or inspect detailed phase state during normal work. It maintains durable run state, enforces the phase branch/worktree topology, starts/stops orchestrator tmux panes, starts/stops deterministic watchdogs, verifies phase transition gates, records escalations or handoffs, and starts the next phase orchestrator after completion when the run scope continues.

## Detached Watchdog

The supervisor should not sit in an open Codex turn waiting on `sleep`. After launch validation, create a small watchdog script under `docs/implementation-runs/<run-id>/watchdogs/<phase-slug>.sh`, start it with `nohup`, record its PID in `run.yaml`, and end the supervisor turn.

The watchdog is deterministic shell, not an LLM. It may:

- read the compact supervisor inbox;
- check whether the recorded tmux pane still exists;
- compare `heartbeat_expires_at` to current UTC time;
- append compact JSONL events;
- write `watchdogs/<phase-slug>-trigger.yaml`;
- launch a new Codex transition-handler pane or process with a short prompt pointing to the trigger file.

The watchdog must not read `phase.yaml`, worker result YAML, raw Codex session logs, full plans, diffs, or artifacts.

Watchdog script shape:

```sh
inbox='<supervisor-inbox-yaml>'
run_yaml='<run-yaml>'
trigger='<watchdog-trigger-yaml>'
event_log='<events/supervisor.jsonl>'
pane='<orchestrator-pane-id>'
repo_root='<repo-root-or-phase-worktree>'
transition_prompt='Use the implementation-execution skill as supervisor transition handler. Load run state: <run.yaml>. Load watchdog trigger: <trigger-yaml>. Handle only that transition event.'

while true; do
  if rg --quiet 'type: (escalation|phase_completion|graceful_exit|restart_needed)|orchestrator_status: (blocked|failed|complete|acceptance_ready)' "$inbox"; then
    reason="$(sed -n 's/^  type: //p; s/^orchestrator_status: //p' "$inbox" | head -1)"
    break
  fi
  if ! tmux display-message -p -t "$pane" '#{pane_id}' >/dev/null 2>&1; then
    reason='pane_dead'
    break
  fi
  if python3 - "$inbox" <<'PY'
import sys, datetime, re
text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'^heartbeat_expires_at:\s*"?([^"\n]+)"?', text, re.M)
if not m:
    sys.exit(1)
expiry = datetime.datetime.fromisoformat(m.group(1).replace("Z", "+00:00"))
sys.exit(0 if datetime.datetime.now(datetime.timezone.utc) > expiry else 1)
PY
  then
    reason='heartbeat_expired'
    break
  fi
  sleep 120
done

ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
cat > "$trigger" <<EOF
phase: "<phase>"
triggered_at: "$ts"
reason: "$reason"
inbox: "$inbox"
run_yaml: "$run_yaml"
tmux_pane: "$pane"
event_log: "$event_log"
handled: false
EOF
printf '{"ts":"%s","role":"supervisor-watchdog","event":"triggered","reason":"%s","trigger":"%s"}\n' "$ts" "$reason" "$trigger" >> "$event_log"
tmux split-window -h -c "$repo_root" -- codex --dangerously-bypass-approvals-and-sandbox "$transition_prompt"
```

If `tmux` is unavailable, the watchdog may launch `codex --dangerously-bypass-approvals-and-sandbox "$transition_prompt"` directly, or it may stop with a blocked trigger when launching Codex is unavailable. Record the chosen wake method in `run.yaml`.

The transition-handler Codex session must not continue polling after handling the trigger. It either completes the transition, starts the next orchestrator/watchdog, or records the blocker and exits.

Supervisor must not:

- select the next implementation task/lane;
- spawn workers;
- rewrite worker goals;
- load task-specific implementation modules to move the phase forward;
- poll detailed worker/orchestrator state beyond the compact inbox during normal execution.
- keep an interactive supervisor Codex turn alive only to wait for the orchestrator.
- approve, reject, or answer Codex edit/command prompts in the orchestrator pane with `tmux send-keys`.
- approve worker edits on behalf of the orchestrator.
- run broad log reads, full-plan dumps, full diffs, or raw Codex session-log parsing during the normal polling loop.

If the orchestrator pane shows a Codex approval prompt, treat it as a process launch/configuration failure. Do not press `y`, `a`, or otherwise answer the prompt. Capture a short pane excerpt if useful, then restart the orchestrator with `--dangerously-bypass-approvals-and-sandbox` or mark the run blocked if restart would risk losing unrecorded state.

## Tmux Orchestrator Pane

Start each phase orchestrator in a new pane in the current tmux window so the human can see both supervisor and orchestrator.

Recommended pattern:

```sh
orchestrator_prompt='Use the implementation-execution skill as the phase orchestrator for <phase>. Run state: <run.yaml>. Phase state: <phase.yaml>. Execution manifest: <manifest.yaml>. Phase plan: <phase-plan>. Write supervisor inbox: <inbox-yaml>. On startup, write startup.acknowledged=true and codex_session if discoverable.'
tmux split-window -h -P -F '#{pane_id}' -c "$PWD" -- codex --dangerously-bypass-approvals-and-sandbox "$orchestrator_prompt"
```

The bypass flag is for the spawned orchestrator process only. It prevents Codex edit/command approval popups from blocking long-running autonomous phase execution, including worker edit prompts owned by the orchestrator. The orchestrator must still follow the workflow escalation policy and write allowed human-only blockers to the supervisor inbox instead of asking ad hoc approval questions.

Capture the printed pane id and store it in `run.yaml` and the initial inbox. If horizontal split is not usable, use a vertical split. If `$TMUX` is not set or `tmux` fails, record `orchestrator.spawn_method: inline_fallback` and the reason in `run.yaml` and the inbox.

## Orchestrator Pane Validation

Never blindly trust `run.yaml`, `phase.yaml`, or the inbox when they claim an orchestrator pane exists. Before resuming or polling an existing orchestrator, validate the recorded pane id against tmux and the expected launch contract.

Validation checks:

1. `tmux display-message -p -t <pane-id> '#{pane_id}'` succeeds and returns the expected pane id.
2. `tmux display-message -p -t <pane-id> '#{pane_current_command} #{pane_current_path} #{pane_pid}'` shows a live pane in the expected repo or phase worktree.
3. The pane command/process tree contains `codex`.
4. The captured pane text or launch record shows the phase-orchestrator prompt for the expected phase, run state, phase plan, and supervisor inbox path.
5. The pane was launched with `--dangerously-bypass-approvals-and-sandbox`, either from the recorded launch command or from visible shell history/process arguments when available.
6. The inbox startup acknowledgement is present after launch and names the expected manifest path.
7. The inbox heartbeat is fresh enough for the configured heartbeat window and points back to the same pane id.

Suggested validation commands:

```sh
tmux display-message -p -t '<pane-id>' '#{pane_id}'
tmux display-message -p -t '<pane-id>' '#{pane_current_command} #{pane_current_path} #{pane_pid}'
tmux capture-pane -p -t '<pane-id>' -S -80 | tail -80
ps -o pid=,ppid=,command= -g "$(tmux display-message -p -t '<pane-id>' '#{pane_pid}')" 2>/dev/null
```

If validation fails, do not keep polling as if the pane is valid. Mark the existing pane as `invalid` in `run.yaml` with a short reason, then either:

- restart the orchestrator with the recommended tmux command when state is safely persisted; or
- mark the run blocked with a compact handoff if restarting could lose unrecorded work.

If the pane exists but shows a Codex approval prompt, use the approval-prompt rule above: treat it as invalid launch/autonomy state rather than approving the prompt.

## Phase Merge Back

The orchestrator merges workers into the phase branch. The supervisor merges the completed phase branch back into the run base branch during phase transition.

Before merging:

1. Confirm the inbox requested `phase_completion`.
2. Confirm `phase.yaml` is `status: complete` and `acceptance.status: passed`.
3. Confirm the acceptance packet exists and references current commits/artifacts.
4. Confirm the phase worktree is clean or only contains explicitly expected state artifacts already committed on the phase branch.
5. Confirm the base branch from `run.yaml` is clean.
6. Confirm the base branch is an ancestor of the phase branch. This proves the phase was built on the current base and can be fast-forwarded.
7. Confirm the phase branch contains the accepted phase commit recorded in the inbox or acceptance packet.

Default merge sequence:

```sh
base_branch='<run.yaml branches.base>'
phase_branch='<phase.yaml branch>'
accepted_commit='<phase completion commit>'
/usr/bin/git switch "$base_branch"
/usr/bin/git status --short
/usr/bin/git merge-base --is-ancestor "$base_branch" "$phase_branch"
/usr/bin/git merge-base --is-ancestor "$accepted_commit" "$phase_branch"
/usr/bin/git merge --ff-only "$phase_branch"
/usr/bin/git rev-parse HEAD
```

After merging:

- run the lightweight post-merge verification needed to catch integration drift, at minimum the phase acceptance gate or the repo's standard smoke commands;
- verify the base branch now points at the accepted phase commit, or at a descendant that contains it when the phase branch includes final acceptance/state commits;
- record the merge commit in `run.yaml` under the completed phase entry;
- set `branches.current` to the updated base branch before starting the next phase;
- start the next phase orchestrator from the updated base branch, not from the previous phase worktree.

If the base branch has diverged, the fast-forward fails, or post-merge verification fails, do not advance `run.yaml`. Stop with a supervisor escalation/handoff or restart a focused fix workflow. Do not silently create a merge commit, rebase the phase branch, or chain the next phase from the previous phase branch.

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
  commit: null
```

The supervisor should not poll detailed phase internals. On `phase_completion`, it may run the narrow transition verification listed in the execution flow.

## Linear And SQLite

Do not use Linear or SQLite as workflow state. If Linear is present, treat it as an optional compact mirror only. The canonical execution state is the YAML run directory.
