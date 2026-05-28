# Supervisor Watchdog

Use this when the supervisor starts, restarts, or repairs the detached watchdog for an active phase.

The supervisor should not sit in an open Codex turn waiting on `sleep`. After orchestrator launch validation, create a small watchdog script under `docs/implementation-runs/<run-id>/watchdogs/<phase-slug>.sh`, start it with `nohup`, record its PID and the original supervisor pane wake target in `run.yaml`, and end the supervisor turn.

The watchdog is deterministic shell, not an LLM. It may:

- read the compact supervisor inbox;
- check whether the recorded tmux pane still exists;
- compare `heartbeat_expires_at` to current UTC time;
- append compact JSONL events;
- write `watchdogs/<phase-slug>-trigger.yaml`;
- wake the original supervisor Codex pane with `tmux send-keys` and a short prompt pointing to the trigger file.

The watchdog must not read `phase.yaml`, worker result YAML, raw Codex session logs, full plans, diffs, or artifacts.

Use absolute paths in the watchdog script, trigger file, and transition-handler prompt. The watchdog may run from a phase worktree, but the supervisor transition prompt must include both the phase worktree path and the run base worktree path. On `phase_completion`, the supervisor must switch to the run base worktree before merge-back, run-state updates, completed-orchestrator teardown, post-merge local verification setup, and next-phase orchestrator startup.

The original supervisor pane is the primary wake target. Record the pane id and containing window when the supervisor starts the watchdog. The watchdog must validate that pane and send the transition prompt there. It may launch a new Codex transition-handler pane/process only as an explicit fallback when the recorded supervisor pane is missing, invalid, or no longer a Codex pane. When a fallback is used, write the fallback reason and pane/process identity to the trigger and supervisor event log so the supervisor can repair `run.yaml`.

## Script Shape

```sh
inbox='<absolute-supervisor-inbox-yaml>'
run_yaml='<absolute-run-yaml>'
phase_yaml='<absolute-phase-yaml>'
trigger='<absolute-watchdog-trigger-yaml>'
event_log='<absolute-events/supervisor.jsonl>'
pane='<orchestrator-pane-id>'
supervisor_pane='<original-supervisor-pane-id>'
supervisor_window='<original-supervisor-session:window-index>'
base_worktree='<absolute-run-base-worktree>'
phase_worktree='<absolute-phase-worktree>'
transition_prompt='Use the implementation-execution skill as the original supervisor transition handler. Load run state: <absolute-run.yaml>. Load watchdog trigger: <absolute-trigger-yaml>. Base worktree: <absolute-run-base-worktree>. Phase worktree: <absolute-phase-worktree>. Handle only that transition event. For phase_completion, read the transition handoff/report, perform merge-back, run-state updates, completed-orchestrator teardown, post-merge local verification from the handoff, print the smoke-test report, and then start the next phase from the base worktree.'

while true; do
  if rg --quiet 'type: (escalation|phase_completion|graceful_exit|restart_needed)|orchestrator_status: (blocked|failed|complete|acceptance_ready)' "$inbox"; then
    request_type="$(sed -n 's/^  type: //p' "$inbox" | head -1)"
    status_type="$(sed -n 's/^orchestrator_status: //p' "$inbox" | head -1)"
    case "$request_type" in
      escalation|phase_completion|graceful_exit|restart_needed) reason="$request_type" ;;
      *) reason="$status_type" ;;
    esac
    [ -n "$reason" ] || reason='lifecycle_request'
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
phase_yaml: "$phase_yaml"
base_worktree: "$base_worktree"
phase_worktree: "$phase_worktree"
tmux_pane: "$pane"
supervisor_pane: "$supervisor_pane"
supervisor_window: "$supervisor_window"
event_log: "$event_log"
wake_method: null
fallback_reason: null
handled: false
EOF
printf '{"ts":"%s","role":"supervisor-watchdog","event":"triggered","reason":"%s","trigger":"%s"}\n' "$ts" "$reason" "$trigger" >> "$event_log"
if tmux display-message -p -t "$supervisor_pane" '#{pane_id}' >/dev/null 2>&1 \
  && tmux display-message -p -t "$supervisor_pane" '#{pane_current_command}' | rg --quiet 'codex'; then
  python3 - "$trigger" <<'PY'
import sys
p = sys.argv[1]
text = open(p, encoding="utf-8").read()
text = text.replace("wake_method: null", 'wake_method: "tmux-send-keys"')
open(p, "w", encoding="utf-8").write(text)
PY
  tmux send-keys -t "$supervisor_pane" -l "$transition_prompt"
  tmux send-keys -t "$supervisor_pane" Enter
else
  fallback_reason='supervisor_pane_invalid'
  python3 - "$trigger" "$fallback_reason" <<'PY'
import sys
p, reason = sys.argv[1], sys.argv[2]
text = open(p, encoding="utf-8").read()
text = text.replace("wake_method: null", 'wake_method: "tmux-pane-fallback"')
text = text.replace("fallback_reason: null", f'fallback_reason: "{reason}"')
open(p, "w", encoding="utf-8").write(text)
PY
  printf '{"ts":"%s","role":"supervisor-watchdog","event":"wake_fallback","reason":"%s","trigger":"%s"}\n' "$ts" "$fallback_reason" "$trigger" >> "$event_log"
  tmux split-window -h -t "$supervisor_window" -c "$base_worktree" -- codex --dangerously-bypass-approvals-and-sandbox "$transition_prompt"
fi
```

If `tmux` is unavailable, the watchdog may launch `codex --dangerously-bypass-approvals-and-sandbox "$transition_prompt"` directly, or it may stop with a blocked trigger when launching Codex is unavailable. Record the chosen wake method in `run.yaml`.

The supervisor transition handler must not continue polling after handling the trigger. It either completes the transition, starts the next orchestrator/watchdog, or records the blocker and exits. If the trigger reason is `acceptance_ready` but the inbox contains `request.type: phase_completion`, treat it as a phase-completion transition and repair future watchdog behavior to prioritize `request.type`.
