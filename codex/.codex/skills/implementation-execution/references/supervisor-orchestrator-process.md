# Supervisor Orchestrator Process

Use this when the supervisor starts, resumes, validates, restarts, or replaces a phase orchestrator process.

## Tmux Orchestrator Pane

Start each phase orchestrator in a new pane in the current tmux window and same tmux session as the original supervisor so the human can see both supervisor and orchestrator. Do not use `tmux new-session` for the orchestrator.

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

If the pane exists but shows a Codex approval prompt, treat it as an invalid launch/autonomy state. Do not press `y`, `a`, or otherwise answer the prompt. Capture a short pane excerpt if useful, then restart the orchestrator with `--dangerously-bypass-approvals-and-sandbox` or mark the run blocked if restart would risk losing unrecorded state.
