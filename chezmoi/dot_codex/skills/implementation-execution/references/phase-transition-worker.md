# Phase Transition Worker

Use this after the completed phase has already been merged into the run base branch, the completed orchestrator has been stopped, and the next phase orchestrator/watchdog has been started when execution scope continues.

The original supervisor stays high-level. After the fast merge-and-advance path is recorded, it spawns this worker as a native Codex sub-agent and waits for its structured result. The phase-transition sub-agent owns only post-advance local verification and smoke reporting for the completed phase:

- read the completed phase's transition handoff/report, merge result, and resulting base commit from `transitions/<phase>.yaml`;
- load `references/local-verification.md` and perform local setup from the completed phase handoff/report in the updated run base worktree;
- start watchable local services in the original supervisor tmux session when feasible;
- record the local URL, setup status, seeded admin access summary or credential-file path, blockers, and smoke report artifact in `transitions/<phase>.yaml`;
- return a compact smoke-report result to the supervisor when the report is ready;
- leave next-phase orchestration running; local verification must not pause or restart it.

## Launch Contract

The supervisor spawns the transition worker with native Codex sub-agent functionality from the active supervisor turn. The watchdog must not launch this worker, and the supervisor must not create a tmux pane or a new top-level Codex process for this worker. The transition sub-agent may still start local services in tmux panes because those are long-running foreground processes the human may inspect, kill, or restart.

Recommended native sub-agent prompt shape:

```text
Use the implementation-execution skill as the post-advance phase-transition sub-agent. Load run state: <absolute-run.yaml>. Load transition state: <absolute-transitions-phase-yaml>. Completed phase: <phase-slug>. Transition handoff: <absolute-transition-handoff-md>. Base worktree: <absolute-run-base-worktree>. Handle only local setup, local verification, and smoke-report artifact creation for the completed phase. Do not merge, stop orchestrators, start orchestrators, update run.yaml, or mark the watchdog trigger handled. When the smoke report is ready, return a compact result to the supervisor so it can print the report while the next phase continues running.
```

Record the native sub-agent id in `transitions/<phase>.yaml`. If the transition sub-agent cannot be spawned, record the transition with `transition_worker.status: blocked` and `blocker: phase_transition_worker_spawn_failed`; do not perform local verification inline in the original supervisor context unless the user explicitly stops the run and asks for manual verification.

## Scope

The phase-transition sub-agent may edit only `transitions/<phase>.yaml` plus referenced local verification artifacts. It must not edit `run.yaml`. It must not edit `phase.yaml` except for a narrow state repair explicitly required to locate the completed phase handoff/report. It must not merge branches, stop the completed orchestrator, start the next phase orchestrator/watchdog, implement phase tasks, dispatch implementation workers, modify future implementation plans, or mark the original watchdog trigger handled.

The worker should keep context narrow:

- read `run.yaml`, `transitions/<phase>.yaml`, the completed phase entry, and the transition handoff/report first;
- load `references/local-verification.md` for setup and smoke-report requirements;
- avoid `references/phase-merge-back.md`; merge-back has already completed;
- avoid `references/supervisor-orchestrator-process.md` and `references/supervisor-watchdog.md`; orchestrator lifecycle belongs to the original supervisor;
- avoid raw Codex session logs, broad plan dumps, full diffs, or full command output.

## Completion

Before returning to the supervisor, the phase-transition sub-agent must:

1. Mark `transition_worker.status` in `transitions/<phase>.yaml` as `ready_for_report`, `blocked`, or `failed`.
2. Record local verification status or blocker, URL, service pane/process identity, seeded admin access summary or credential-file path, transition handoff path, and smoke-test report artifact.
3. Preserve any local verification pane so the human can inspect or restart the foreground service.
4. Return a compact result to the supervisor that points to `transitions/<phase>.yaml`, `run.yaml`, and the smoke-test report artifact.
5. Append a compact event with the final worker result.

If local verification blocks, keep the next phase running when it is already active. Write a compact blocker summary with the same classification and true-blocker reasoning expected from `references/blocker-resolver.md`, including the exact missing credential/provider/dependency, what setup was attempted, why the issue is or is not human-owned, and the handoff/report paths needed to resume.
