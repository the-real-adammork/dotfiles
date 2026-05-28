# Supervisor Watchdog

Use this when the supervisor starts, restarts, or repairs the same-session watchdog for an active phase.

The supervisor should not sit in an open Codex turn waiting on `sleep`. After orchestrator launch validation, create a small watchdog script under `docs/implementation-runs/<run-id>/watchdogs/<phase-slug>.sh`, start it in the original supervisor tmux session, record its PID, pane/window, and original supervisor pane wake target in `run.yaml`, and end the supervisor turn.

The watchdog must stay in the same tmux session as the original supervisor. Prefer a dedicated workflow window in that session, shared with post-merge local verification panes when needed, so the human-facing supervisor/orchestrator window remains uncluttered. Use `tmux new-window -d` or `tmux split-window -d` targeting the original supervisor session. Do not use `tmux new-session` for the watchdog.

The watchdog is deterministic shell, not an LLM. It may:

- read the compact supervisor inbox;
- check whether the recorded tmux pane still exists;
- compare `heartbeat_expires_at` to current UTC time;
- print human-readable status lines to its tmux pane;
- append compact JSONL events;
- write `watchdogs/<phase-slug>-trigger.yaml`;
- wake the original supervisor Codex pane with `tmux send-keys` and a short prompt pointing to the trigger file.

The watchdog must not read `phase.yaml`, worker result YAML, raw Codex session logs, full plans, diffs, or artifacts.

The watchdog pane output is the human-observable live log. It must print a timestamped line on startup, before and after each poll, when the inbox does or does not contain an actionable request, when orchestrator pane validation passes or fails, when heartbeat is healthy or expired, when a trigger file is written, when the supervisor pane is validated, when the transition prompt is sent, and when wake is blocked. Keep lines short and avoid full YAML, full prompts, diffs, or command output. Do not mirror these lines into a separate watchdog log file; structured JSONL events remain compact and should be emitted only for lifecycle milestones such as started, poll, triggered, wake_sent, wake_blocked, and stopped.

Use absolute paths in the watchdog script, trigger file, and transition-handler prompt. The watchdog may run from a phase worktree, but the supervisor transition prompt must include both the phase worktree path and the run base worktree path. On `phase_completion`, the supervisor must switch to the run base worktree before merge-back, run-state updates, completed-orchestrator teardown, post-merge local verification setup, and next-phase orchestrator startup.

The original supervisor pane is the only wake target. Record the pane id, containing window, and containing session when the supervisor starts the watchdog. The watchdog must validate that pane and send the transition prompt there. If the recorded supervisor pane is missing, invalid, or no longer a Codex pane, the watchdog must write a blocked trigger with `wake_method: "blocked"` and `wake_blocker: "supervisor_pane_invalid"`, append a compact event, and stop. It must not launch a new Codex transition-handler pane/process.

Recommended launch shape:

```sh
workflow_window='<original-supervisor-session>:workflow'
tmux new-window -d -P -F '#{pane_id}' -t '<original-supervisor-session>:' -n workflow -c "$base_worktree" "sh '$watchdog_script'"
```

If the workflow window already exists, use a detached split in that window:

```sh
tmux split-window -d -P -F '#{pane_id}' -t "$workflow_window" -c "$base_worktree" "sh '$watchdog_script'"
```

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
supervisor_session='<original-supervisor-session>'
base_worktree='<absolute-run-base-worktree>'
phase_worktree='<absolute-phase-worktree>'
transition_prompt='Use the implementation-execution skill as the original supervisor transition handler. Load run state: <absolute-run.yaml>. Load watchdog trigger: <absolute-trigger-yaml>. Base worktree: <absolute-run-base-worktree>. Phase worktree: <absolute-phase-worktree>. Handle only that transition event. For phase_completion, read the transition handoff/report, perform merge-back, run-state updates, completed-orchestrator teardown, post-merge local verification from the handoff, print the smoke-test report, and then start the next phase from the base worktree.'

log() {
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  line="$ts watchdog phase=<phase> $*"
  printf '%s\n' "$line"
}

event() {
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '{"ts":"%s","role":"supervisor-watchdog","event":"%s","phase":"%s","reason":"%s","trigger":"%s"}\n' "$ts" "$1" "<phase>" "${2:-}" "${3:-}" >> "$event_log"
}

mkdir -p "$(dirname "$event_log")"
log "started inbox=$inbox orchestrator_pane=$pane supervisor_pane=$supervisor_pane interval=120s"
event "started" "" ""
while true; do
  log "poll_start inbox=$inbox"
  if rg --quiet 'type: (escalation|phase_completion|graceful_exit|restart_needed)|orchestrator_status: (blocked|failed|complete|acceptance_ready)' "$inbox"; then
    request_type="$(sed -n 's/^  type: //p' "$inbox" | head -1)"
    status_type="$(sed -n 's/^orchestrator_status: //p' "$inbox" | head -1)"
    case "$request_type" in
      escalation|phase_completion|graceful_exit|restart_needed) reason="$request_type" ;;
      *) reason="$status_type" ;;
    esac
    [ -n "$reason" ] || reason='lifecycle_request'
    log "inbox_action reason=$reason request_type=${request_type:-none} status=${status_type:-unknown}"
    break
  fi
  log "inbox_no_action"
  if ! tmux display-message -p -t "$pane" '#{pane_id}' >/dev/null 2>&1; then
    reason='pane_dead'
    log "orchestrator_pane_missing pane=$pane"
    break
  fi
  log "orchestrator_pane_ok pane=$pane"
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
    log "heartbeat_expired"
    break
  fi
  log "heartbeat_ok sleeping=120s"
  event "poll" "no_action" ""
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
supervisor_session: "$supervisor_session"
event_log: "$event_log"
wake_method: null
wake_blocker: null
handled: false
EOF
log "trigger_written reason=$reason trigger=$trigger"
event "triggered" "$reason" "$trigger"
if tmux display-message -p -t "$supervisor_pane" '#{pane_id}' >/dev/null 2>&1 \
  && tmux display-message -p -t "$supervisor_pane" '#{pane_current_command}' | rg --quiet 'codex'; then
  python3 - "$trigger" <<'PY'
import sys
p = sys.argv[1]
text = open(p, encoding="utf-8").read()
text = text.replace("wake_method: null", 'wake_method: "tmux-send-keys"')
open(p, "w", encoding="utf-8").write(text)
PY
  log "supervisor_pane_ok pane=$supervisor_pane wake_method=tmux-send-keys"
  tmux send-keys -t "$supervisor_pane" -l "$transition_prompt"
  tmux send-keys -t "$supervisor_pane" Enter
  log "wake_sent pane=$supervisor_pane trigger=$trigger"
  event "wake_sent" "$reason" "$trigger"
else
  wake_blocker='supervisor_pane_invalid'
  python3 - "$trigger" "$wake_blocker" <<'PY'
import sys
p, reason = sys.argv[1], sys.argv[2]
text = open(p, encoding="utf-8").read()
text = text.replace("wake_method: null", 'wake_method: "blocked"')
text = text.replace("wake_blocker: null", f'wake_blocker: "{reason}"')
open(p, "w", encoding="utf-8").write(text)
PY
  log "wake_blocked reason=$wake_blocker supervisor_pane=$supervisor_pane"
  event "wake_blocked" "$wake_blocker" "$trigger"
  exit 2
fi
```

If `tmux` is unavailable, the watchdog must not launch `codex` directly. It must write a blocked trigger with `wake_method: "blocked"` and the relevant `wake_blocker`, append a compact event, and stop. Repair the tmux/supervisor-pane communication path before continuing the workflow.

The supervisor transition handler must not continue polling after handling the trigger. It either completes the transition, starts the next orchestrator/watchdog, or records the blocker and exits. If the trigger reason is `acceptance_ready` but the inbox contains `request.type: phase_completion`, treat it as a phase-completion transition and repair future watchdog behavior to prioritize `request.type`.
