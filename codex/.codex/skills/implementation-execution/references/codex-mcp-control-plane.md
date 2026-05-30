# Codex Control Plane

Use this when the workflow needs to communicate with an existing Codex supervisor, orchestrator, or worker without relying on terminal keystrokes.

Codex exposes an experimental local control-plane API through `codex app-server`. Treat this as the preferred control plane for supervisor wakeups because it can address persisted Codex threads and start real turns instead of typing into a tmux pane. The interface is experimental and may change, so every run must record the Codex CLI version and a short control-plane smoke result before relying on it.

Primary sources:

- `https://github.com/openai/codex/blob/main/codex-rs/docs/codex_mcp_interface.md`
- `https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md`

Verified local behavior with `codex-cli 0.134.0`:

- `codex mcp-server` initializes successfully and exposes MCP tools `codex` and `codex-reply`.
- `codex mcp-server` does not expose direct `thread/read`, `thread/resume`, or `turn/start` JSON-RPC methods in this installed version.
- `codex app-server` exposes direct `thread/start`, `thread/resume`, `thread/read`, and `turn/start`, and can resume a persisted thread after the server process restarts.

Use `codex app-server` for the workflow control plane. Do not build watchdog wakeups on the `codex-reply` MCP tool until a local smoke test proves it can resume the recorded supervisor thread across a fresh server process.

## Supported Shape

Use the v2 thread and turn methods:

- `thread/resume` to load the recorded supervisor thread by id.
- `turn/start` to send the transition-router prompt as a new user turn.
- `thread/read` or event notifications to confirm the thread/turn state when needed.
- `turn/interrupt` only when a workflow-owned turn must be stopped because the durable run state has moved on.

Do not use `tmux send-keys` as the normal wake path. Keep tmux panes for human-visible long-running processes and local services only.

## Supervisor Startup

When the supervisor starts a run, record both the visible tmux identity and the Codex thread identity:

```yaml
codex_control:
  protocol: codex-app-server
  codex_version: "codex-cli 0.134.0"
  supervisor_thread_id: "019e..."
  supervisor_rollout_path: "/Users/example/.codex/sessions/YYYY/MM/DD/rollout-...jsonl"
  server_command: "codex app-server"
  smoke_test:
    checked_at: "YYYY-MM-DDTHH:MM:SSZ"
    status: pass # pass | failed | skipped
    methods: ["thread/start", "turn/start", "thread/resume", "turn/start"]
    reason: null
```

If the supervisor cannot discover a stable thread id, record `codex_control.status: blocked` and do not start the watchdog. Repair the control path first; a watchdog that cannot wake the supervisor is misleading.

## Watchdog Wake

The deterministic watchdog still polls only the compact supervisor inbox and writes the trigger YAML. After writing the trigger, it launches a short-lived control-plane client process that:

1. Starts `codex app-server` over stdio.
2. Initializes the JSON-RPC connection.
3. Calls `thread/resume` with `codex_control.supervisor_thread_id`.
4. Calls `turn/start` with the transition-router prompt.
5. Reads events until the server accepts the turn or reports a hard error.
6. Records the request id, thread id, turn id if returned, and result in the trigger and compact event log.

The watchdog must not start a new Codex supervisor thread for transition handling. If `thread/resume` fails, write `wake_method: "blocked"` and `wake_blocker: "codex_control_resume_failed"`. If `turn/start` fails, write `wake_blocker: "codex_control_turn_start_failed"`. Do not silently fall back to tmux keystrokes.

Recommended trigger fields:

```yaml
wake_method: "codex-app-server-turn-start"
wake_blocker: null
codex_control:
  supervisor_thread_id: "019e..."
  server_command: "codex app-server"
  request_id: 42
  turn_id: "turn_..."
  status: turn_started
```

## Transition Prompt

Keep the prompt compact and path-based:

```text
Use the implementation-execution skill as the original supervisor transition router. Load run state: <absolute-run.yaml>. Load transition state when present: <absolute-transitions-phase-yaml>. Load watchdog trigger: <absolute-trigger-yaml>. Base worktree: <absolute-run-base-worktree>. Phase worktree: <absolute-phase-worktree>. Handle only that transition event.
```

For `phase_completion`, the supervisor must route context-heavy work to the native phase-merge sub-agent and must not perform merge-back inline.

## Failure Policy

Control-plane failure is a workflow blocker, not an invitation to create another supervisor.

- `codex_control_unavailable`: `codex app-server` is missing or fails initialization.
- `codex_control_resume_failed`: the recorded supervisor thread cannot be resumed.
- `codex_control_turn_start_failed`: the transition turn cannot be started.
- `codex_control_turn_rejected`: Codex accepted the thread but rejected the turn due to permissions, approval policy, or active-turn state.

Record the blocker in the trigger YAML and `events/supervisor.jsonl`. If a supervisor later resumes manually, it may mirror only the minimal blocked status/pointer into `run.yaml`. Keep the orchestrator pane and phase worktree intact for repair.
