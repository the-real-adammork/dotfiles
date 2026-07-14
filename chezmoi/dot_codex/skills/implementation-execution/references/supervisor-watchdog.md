# Supervisor Watchdog

Use this when the supervisor starts, restarts, or repairs the same-session watchdog for an active phase.

The supervisor should not sit in an open Codex turn waiting on `sleep`. After orchestrator launch validation, create a small watchdog script under `docs/implementation-runs/<run-id>/watchdogs/<phase-slug>.sh`, start it in the original supervisor tmux session, record its PID, pane/window, and original supervisor thread wake target in `run.yaml`, and end the supervisor turn.

The watchdog must stay in the same tmux session as the original supervisor. Prefer a dedicated workflow window in that session, shared with post-merge local verification panes when needed, so the human-facing supervisor/orchestrator window remains uncluttered. Use `tmux new-window -d` or `tmux split-window -d` targeting the original supervisor session. Do not use `tmux new-session` for the watchdog.

The watchdog is deterministic shell, not an LLM. It may:

- read the compact supervisor inbox;
- check whether the recorded tmux pane still exists;
- compare `heartbeat_expires_at` to current UTC time;
- print human-readable status lines to its tmux pane;
- append compact JSONL events;
- write `watchdogs/<phase-slug>-trigger.yaml`;
- wake the original supervisor Codex thread through `codex app-server` with a short prompt pointing to the trigger file.

The watchdog must not read `phase.yaml`, worker result YAML, raw Codex session logs, full plans, diffs, or artifacts.

The watchdog pane output is the human-observable live log. It must print a timestamped line on startup, before and after each poll, when the inbox does or does not contain an actionable request, when orchestrator pane validation passes or fails, when heartbeat is healthy or expired, when a trigger file is written, when the supervisor thread id is present, when the app-server transition turn is accepted, and when wake is blocked. Keep lines short and avoid full YAML, full prompts, diffs, or command output. Do not mirror these lines into a separate watchdog log file; structured JSONL events remain compact and should be emitted only for lifecycle milestones such as started, poll, triggered, wake_sent, wake_blocked, and stopped.

Use absolute paths in the watchdog script, trigger file, and transition-router prompt. The watchdog may run from a phase worktree, but the supervisor prompt must include both the phase worktree path and the run base worktree path. On `phase_completion`, the supervisor must route the trigger to a native phase-merge sub-agent instead of doing merge-back inline. Completed-orchestrator teardown, trigger handling, next-phase startup, and post-advance phase-transition sub-agent launch remain high-level supervisor work after the merge sub-agent reports ready.

The original supervisor thread is the only wake target. Record the Codex thread id, rollout path, pane id, containing window, and containing session when the supervisor starts the watchdog. The watchdog must resume that thread with `codex app-server` and start a transition turn there. If the recorded supervisor thread is missing or cannot be resumed, the watchdog must write a blocked trigger with `wake_method: "blocked"` and `wake_blocker: "codex_control_resume_failed"`, append a compact event, and stop. If the turn cannot be started, use `wake_blocker: "codex_control_turn_start_failed"`. It must not launch a new Codex transition-handler pane/process.

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
transition_yaml='<absolute-transitions-phase-yaml>'
trigger='<absolute-watchdog-trigger-yaml>'
event_log='<absolute-events/supervisor.jsonl>'
pane='<orchestrator-pane-id>'
supervisor_thread_id='<original-supervisor-thread-id>'
supervisor_rollout_path='<original-supervisor-rollout-jsonl>'
supervisor_pane='<original-supervisor-pane-id-for-human-visibility>'
supervisor_window='<original-supervisor-session:window-index>'
supervisor_session='<original-supervisor-session>'
base_worktree='<absolute-run-base-worktree>'
phase_worktree='<absolute-phase-worktree>'
transition_prompt='Use the implementation-execution skill as the original supervisor transition router. Load run state: <absolute-run.yaml>. Load transition state: <absolute-transitions-phase-yaml>. Load watchdog trigger: <absolute-trigger-yaml>. Base worktree: <absolute-run-base-worktree>. Phase worktree: <absolute-phase-worktree>. Handle only that transition event. For phase_completion, do not perform merge-back or local verification inline; spawn a native phase-merge sub-agent using references/phase-merge-worker.md and record the delegation in transitions/<phase>.yaml. When the phase-merge sub-agent returns ready_for_supervisor, stop the completed orchestrator, mark the trigger handled, update only minimal run.yaml pointers/status, start the next phase when applicable from the updated base branch, then spawn a native post-advance phase-transition sub-agent using references/phase-transition-worker.md for local verification and smoke reporting. When the transition sub-agent returns ready_for_report, print its smoke-test report while leaving any next phase running.'

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
transition_yaml: "$transition_yaml"
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
if [ -z "$supervisor_thread_id" ]; then
  wake_blocker='codex_control_missing_supervisor_thread_id'
  python3 - "$trigger" "$wake_blocker" <<'PY'
import sys
p, reason = sys.argv[1], sys.argv[2]
text = open(p, encoding="utf-8").read()
text = text.replace("wake_method: null", 'wake_method: "blocked"')
text = text.replace("wake_blocker: null", f'wake_blocker: "{reason}"')
open(p, "w", encoding="utf-8").write(text)
PY
  log "wake_blocked reason=$wake_blocker"
  event "wake_blocked" "$wake_blocker" "$trigger"
  exit 2
fi

if python3 - "$trigger" "$supervisor_thread_id" "$transition_prompt" <<'PY'
import json
import selectors
import subprocess
import sys
import time

trigger, thread_id, prompt = sys.argv[1], sys.argv[2], sys.argv[3]
proc = subprocess.Popen(
    ["codex", "app-server"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
    bufsize=1,
)
sel = selectors.DefaultSelector()
sel.register(proc.stdout, selectors.EVENT_READ)

def send(obj):
    proc.stdin.write(json.dumps(obj, separators=(",", ":")) + "\n")
    proc.stdin.flush()

def wait_for(pred, timeout):
    deadline = time.time() + timeout
    while time.time() < deadline:
        for key, _ in sel.select(0.5):
            line = key.fileobj.readline()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except json.JSONDecodeError:
                continue
            if pred(msg):
                return msg
    return None

try:
    send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"clientInfo": {"name": "implementation-execution-watchdog", "version": "0.1.0"}, "capabilities": {"experimentalApi": True, "optOutNotificationMethods": ["item/agentMessage/delta"]}}})
    init = wait_for(lambda m: m.get("id") == 1, 10)
    if not init or "error" in init:
        raise SystemExit("codex_control_unavailable")
    send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
    send({"jsonrpc": "2.0", "id": 2, "method": "thread/resume", "params": {"threadId": thread_id, "excludeTurns": True}})
    resume = wait_for(lambda m: m.get("id") == 2, 30)
    if not resume or "error" in resume:
        raise SystemExit("codex_control_resume_failed")
    send({"jsonrpc": "2.0", "id": 3, "method": "turn/start", "params": {"threadId": thread_id, "input": [{"type": "text", "text": prompt}]}})
    turn = wait_for(lambda m: m.get("id") == 3, 30)
    if not turn or "error" in turn:
        raise SystemExit("codex_control_turn_start_failed")
    turn_id = turn.get("result", {}).get("turn", {}).get("id")
    text = open(trigger, encoding="utf-8").read()
    text = text.replace("wake_method: null", 'wake_method: "codex-app-server-turn-start"')
    text = text.replace("wake_blocker: null", "wake_blocker: null")
    text += f'codex_control:\n  supervisor_thread_id: "{thread_id}"\n  server_command: "codex app-server"\n  turn_id: "{turn_id or ""}"\n  status: "turn_started"\n'
    open(trigger, "w", encoding="utf-8").write(text)
finally:
    try:
        proc.terminate()
        proc.wait(timeout=2)
    except Exception:
        proc.kill()
PY
then
  log "wake_sent method=codex-app-server thread=$supervisor_thread_id trigger=$trigger"
  event "wake_sent" "$reason" "$trigger"
else
  wake_blocker='codex_control_turn_start_failed'
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

If `codex app-server` is unavailable or the recorded supervisor thread cannot be resumed, the watchdog must not launch a replacement supervisor. It must write a blocked trigger with `wake_method: "blocked"` and the relevant `wake_blocker`, append a compact event, and stop. Repair the control-plane communication path before continuing the workflow.

The supervisor transition router must not continue polling after handling the trigger. For `phase_completion`, it spawns a native phase-merge sub-agent, handles a completed merge sub-agent result, spawns the post-advance phase-transition sub-agent after next-phase startup, handles a completed smoke-report result, or records a blocked delegation failure, then exits. If the trigger reason is `acceptance_ready` but the inbox contains `request.type: phase_completion`, treat it as a phase-completion transition and repair future watchdog behavior to prioritize `request.type`.
