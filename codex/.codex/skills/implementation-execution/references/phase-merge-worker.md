# Phase Merge Worker

Use this when the original supervisor has been woken by the watchdog for `phase_completion` and needs the completed phase merged into the run base branch before the next phase can start.

The original supervisor stays high-level. It validates the trigger, records the phase-merge-worker delegation, spawns a native Codex sub-agent, and waits for its structured result. The phase-merge sub-agent owns only the blocking merge preparation:

- verify the phase-completion gate from the compact inbox, phase state, acceptance packet, accepted commit, and transition handoff/report;
- load `references/phase-merge-back.md` and merge or reconcile the accepted phase branch/worktree into the run base branch;
- record the resulting base commit, merge decisions, completed phase evidence, and phase-merge-worker status in `transitions/<phase>.yaml`;
- leave completed-orchestrator teardown, trigger final handling, next-phase startup, local verification, and user-facing smoke-report printing to the original supervisor and post-advance phase-transition sub-agent;
- return a compact completion result to the supervisor when the merge result is ready for high-level supervisor actions;
- write compact supervisor events for merge-worker start, merge result ready, blocked state, and any repair decisions.

## Launch Contract

The supervisor spawns the phase-merge worker with native Codex sub-agent functionality from the active supervisor turn. The watchdog must not launch this worker, and the supervisor must not create a tmux pane or a new top-level Codex process for this worker.

Recommended native sub-agent prompt shape:

```text
Use the implementation-execution skill as the phase-merge sub-agent. Load run state: <absolute-run.yaml>. Load transition state: <absolute-transitions-phase-yaml>. Load watchdog trigger: <absolute-trigger-yaml>. Load supervisor inbox: <absolute-inbox-yaml>. Base worktree: <absolute-run-base-worktree>. Phase worktree: <absolute-phase-worktree>. Handle only this merge work. For phase_completion, verify the transition handoff/report, perform merge-back into the run base branch, update merge-owned transition state, and return a compact result to the supervisor for completed-orchestrator teardown, trigger handling, run.yaml pointer updates, and next-phase startup.
```

Record the native sub-agent id in `transitions/<phase>.yaml`. If the phase-merge sub-agent cannot be spawned, record the transition as blocked with `blocker: phase_merge_worker_spawn_failed` and do not perform merge-back inline in the original supervisor context.

## Scope

The phase-merge sub-agent may edit only `transitions/<phase>.yaml` plus referenced merge artifacts. It must not edit `run.yaml`. It must not edit `phase.yaml` except for a narrow state repair explicitly required by merge verification. It must not stop the completed orchestrator, start the next phase orchestrator/watchdog, launch local verification, print the user-facing smoke report, implement phase tasks, dispatch implementation workers, or modify future implementation plans except through the normal compact consistency workflow.

The worker should keep context narrow:

- read `run.yaml`, `transitions/<phase>.yaml`, the trigger YAML, the compact inbox, and the transition handoff/report first;
- load `references/phase-merge-back.md` only when merge-back is needed;
- avoid `references/local-verification.md`; post-advance local verification belongs to the phase-transition sub-agent after the next orchestrator starts;
- avoid `references/supervisor-orchestrator-process.md` and `references/supervisor-watchdog.md`; next-phase launch belongs to the original supervisor;
- avoid raw Codex session logs, broad plan dumps, full diffs, or full command output.

## Completion

Before returning to the supervisor, the phase-merge sub-agent must:

1. Mark `merge_worker.status` in `transitions/<phase>.yaml` as `ready_for_supervisor`, `blocked`, or `failed`.
2. Leave the watchdog trigger unhandled until the original supervisor completes high-level lifecycle work.
3. Record merge-back result, resulting base commit, merge decisions, completed phase evidence, transition handoff path, and the next phase candidate if any.
4. Preserve the completed orchestrator pane for the supervisor to stop.
5. Return a compact result to the supervisor that points to `transitions/<phase>.yaml`, `run.yaml`, the trigger, and merge result state.
6. Append a compact event with the final worker result.

If the merge blocks, preserve all panes containing unrecorded state and write a compact blocker summary with the exact state files and artifacts needed to resume.
