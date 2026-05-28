---
name: implementation-execution
description: "Use when implementing approved implementation phase plans with a git-native, file-backed agent workflow: supervisor-run phase transitions, detached watchdogs, tmux-pane phase orchestrators, bounded worker agents, TDD test approval gates, YAML run state, artifact-backed verification, phase acceptance gates, resumable handoffs, and autonomous execution without Linear or SQLite."
---

# Implementation Execution

Run approved implementation phase plans through a durable, file-backed agent workflow. This skill is independent of deprecated Linear/SQLite implementation workflows.

## Start

Announce: "I'm using the implementation-execution skill to run the phase plans with YAML state, a supervisor-managed tmux orchestrator, a detached watchdog, bounded workers, and phase acceptance gates."

Inputs:

- optional SLICES document path, default `docs/plans/SLICES.md`;
- one or more implementation plan paths;
- optional execution scope, default `run` when a phases document or multiple phase plans are provided, and `single-phase` only when the user explicitly asks to run one phase only;
- optional run id, default `YYYY-MM-DD-<feature>`;
- optional run directory, default `docs/implementation-runs/<run-id>/`;
- optional QA artifact directory, default `docs/qa/artifacts/<phase-slug>/`;
- optional phase acceptance directory, default `docs/qa/phase-acceptance/`.

If the user does not provide a SLICES document path, look for `docs/plans/SLICES.md` first and use it as the approved phase-order source. If it is missing, but exactly one legacy `docs/plans/*implementation-phases.md` exists, use that legacy file and record the fallback in `run.yaml`. If no slices document can be found, run `$implementation-plans` first. Do not begin implementation from requirements alone.

## Core Model

- YAML tracks state.
- Markdown explains decisions.
- Artifacts hold evidence.
- JSONL events explain workflow timing and communication volume.
- Do not make markdown the database.

One supervisor owns the run. One top-level Codex CLI phase orchestrator owns each active phase. Worker agents handle substantial bounded implementation lanes, including serial lanes that cannot run in parallel. Workers cannot spawn workers or coordinate directly with sibling workers. The phase orchestrator is the scheduler and integrator for its phase.

Supervisor, phase orchestrator, watchdog, and worker are distinct processes/responsibilities. On skill start, the current Codex session is the supervisor. The supervisor records its own tmux pane/window identity, starts the active phase orchestrator as a separate top-level `codex` process in a new pane in the current tmux window so the human can see both, then starts a detached deterministic watchdog and ends the supervisor turn. Because the orchestrator is top-level, it can spawn and communicate with workers directly. The supervisor does not spawn workers, choose lanes, or read detailed phase state during normal work.

Supervisor/orchestrator communication uses one compact file: `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml`. The orchestrator writes heartbeat, blocked/escalation requests, graceful-exit requests, and phase-completion requests there. A detached non-LLM watchdog polls that file and wakes the original supervisor Codex pane only when action is needed by sending a compact transition prompt with `tmux send-keys`. Launching a fresh supervisor transition-handler Codex session is a fallback only when the recorded supervisor pane is missing, invalid, or no longer a Codex pane; record that fallback in `run.yaml` and events. Workflow observability uses compact JSONL event logs under `docs/implementation-runs/<run-id>/events/`; do not use raw Codex session logs as workflow state. If tmux or Codex CLI process spawning is unavailable, record the fallback in `run.yaml` and the inbox; do not silently collapse the roles.

Human involvement is only for allowed escalations: credentials/secrets, paid/vendor setup, unresolved product/legal/security decisions, destructive production actions, real customer data access, or unavailable real dependencies after an agent-owned attempt.

General-purpose implementation workers are the only implementation worker type. Reviewer and fix-worker roles remain available for review and remediation loops. Ignore any legacy custom-agent routing in old plans or manifests, and do not invent, propose, request, wait for, or dispatch custom repo-specific implementation agents during runtime.

## Reference Modules

Load only the module needed for the current action:

- `references/state-files.md` - create, update, and resume `run.yaml`, `phase.yaml`, worker result YAML, handoffs, acceptance packets, and evidence artifacts.
- `references/supervisor.md` - run-level state machine, transition-handler routing, phase order, resumability, role separation, and escalation behavior.
- `references/supervisor-orchestrator-process.md` - tmux orchestrator pane launch, launch autonomy, pane validation, and invalid-pane recovery.
- `references/supervisor-watchdog.md` - detached watchdog setup, trigger generation, transition-handler wake behavior, and watchdog script shape.
- `references/phase-merge-back.md` - accepted phase merge-back, dirty base worktree preservation, merge reconciliation, conflict resolution, and decision logging.
- `references/local-verification.md` - post-merge local setup, dependency refresh, service launch, localhost URL discovery, and smoke-test instructions.
- `references/phase-orchestrator.md` - phase orchestrator ownership, active frontier construction, worker dispatch, `/goal` usage, integration checkpoints, and phase branch ownership.
- `references/branch-worktree.md` - phase branch, worker branch/worktree isolation, merge-back rules, and parallel lane safety.
- `references/worker-tdd.md` - bounded worker contract, two-stage TDD flow, test proposal approval, implementation, worker result YAML, and worker restrictions.
- `references/agentic-review.md` - agentic test review, implementation review, fix-worker loop, and mock/fixture ledger review rules.
- `references/qa-acceptance.md` - phase acceptance gate, service-wiring verification, mock/fixture ledger reconciliation, platform E2E expectations, and acceptance packet contents.
- `references/lessons.md` - lesson candidate rules, orchestrator promotion criteria, `docs/lessons` creation, and `AGENTS.md` pointers.
- `references/consistency-handoff.md` - batched plan consistency updates, compact actual-vs-planned notes, context handoffs, and final output.
- Use `$secrets` before generating, writing, revealing, hiding, staging, committing, or reviewing secrets, credentials, env files, database passwords, app keys, API tokens, or secret-bearing config.

## Workflow

1. Load `references/state-files.md` and create or resume the run state.
2. Load `references/supervisor.md` and choose the current phase from `run.yaml`.
3. Load `references/supervisor-orchestrator-process.md`, `references/supervisor-watchdog.md`, `references/phase-orchestrator.md`, and `references/branch-worktree.md` before starting or resuming the active phase.
4. Create or refresh the compact execution manifest for the active phase, validate any recorded orchestrator pane before trusting it, then start or resume the phase orchestrator in a new pane in the current tmux window. The orchestrator builds the active frontier from the manifest, task statuses, shared-resource constraints, and active worker lanes.
5. The orchestrator spawns general-purpose workers directly for substantial implementation lanes, even when only one lane is currently available. Keep glue, integration, tiny edits, state updates, and acceptance ownership with the orchestrator. Use reviewer and fix-worker roles only for review/remediation loops.
6. For behavior work, use `references/worker-tdd.md`: test-only goal first, agentic test approval, then implementation.
7. Use `references/agentic-review.md` for test review, implementation review, and fix loops.
8. After each worker result, the orchestrator integrates, runs the lane checkpoint, updates `phase.yaml`, reconciles mock/fixture ledger entries, and batches any needed plan consistency notes.
9. Use `references/qa-acceptance.md` before marking a phase complete.
10. The orchestrator writes a phase-transition handoff/report and phase-completion request to the supervisor inbox when acceptance passes. The handoff/report must include local setup instructions, expected ports, caveats, and smoke tests for the new behavior. The detached watchdog wakes the original supervisor pane as a short supervisor transition handler. The supervisor verifies acceptance, reads the transition handoff/report, loads `references/phase-merge-back.md`, reconciles the accepted phase branch/worktree back into the run base branch, records the resulting base commit and any merge decisions in `run.yaml`, then terminates the completed phase orchestrator pane/session before launching any next-phase orchestrator. The supervisor then loads `references/local-verification.md` for post-merge local verification setup from the transition handoff/report, prints the local URL and smoke-test report for the human, and only then starts the next phase. Missing secrets, paid/vendor access, unavailable external services, or other allowed escalations may be flagged; ordinary local setup friction remains agent-owned. If execution scope is `run` and another phase remains, the supervisor must then load `references/supervisor-orchestrator-process.md` and `references/supervisor-watchdog.md` to start the next phase orchestrator/watchdog automatically from the updated base branch while the local verification run stays available for the human to inspect. Do not stop after a successful phase unless the user explicitly requested `single-phase`, an allowed escalation blocks progress, context handoff is required, or the user stops the workflow.
11. Use `references/lessons.md` when worker/reviewer results reveal a recurring proven problem future agents should avoid.
12. Use `references/consistency-handoff.md` for downstream plan updates, handoffs, final reporting, or blocked states.

## Non-Negotiables

- Do not use SQLite as workflow state.
- Do not use Linear as workflow state.
- Do not base execution on deprecated Linear/SQLite implementation supervisor skills.
- Do not create PR/MR per task by default.
- Do not write huge markdown review packets.
- Do not save full stdout in YAML or markdown.
- Do not use raw Codex session logs as workflow state; store only their session id/path in YAML and compact workflow events in `events/*.jsonl`.
- Do not paste full skill bodies, full phase plans, full diffs, or broad command output into spawned orchestrator or worker prompts. Pass file paths plus a compact execution manifest.
- Do not keep the phase orchestrator inline when tmux/Codex process spawning is available; start it in a new pane in the current tmux window with `--dangerously-bypass-approvals-and-sandbox`, and record it in `run.yaml`/`phase.yaml`.
- Do not keep the supervisor Codex session alive as a resident polling daemon; launch a detached watchdog and resume supervisor work only for transition events sent to the recorded supervisor pane.
- Do not make a fresh transition-handler Codex pane the normal watchdog wake path. Use the recorded original supervisor pane with `tmux send-keys`; create a new Codex transition-handler only as an explicit fallback when the original supervisor pane cannot be validated.
- Do not launch tmux orchestrators with prompts containing unescaped `$implementation-execution`; shell expansion can erase the skill name. Use plain text such as `Use the implementation-execution skill...` or escape the dollar sign.
- Do not blindly trust a recorded orchestrator pane in `run.yaml`, `phase.yaml`, or the inbox. Validate the tmux pane, command/process, launch flags, expected prompt paths, and fresh heartbeat before resuming.
- Do not let the supervisor choose implementation lanes, dispatch workers, or read detailed phase state during normal work; the orchestrator owns phase execution and workers.
- Do not let the supervisor approve or reject Codex edit/command prompts in the orchestrator pane. Approval prompts mean the orchestrator was launched with the wrong autonomy settings and should be restarted or blocked, not manually driven.
- Do not make the orchestrator the default implementer for substantial code/test changes; use workers for implementation lanes even when execution is serial.
- Do not delegate tiny glue, state updates, acceptance packet edits, or integration decisions by default.
- Do not let workers spawn workers.
- Do not accept mock-only completion for service wiring that requires real integration proof.
- Do not ban useful mocks/fixtures during implementation; track them in the mock/fixture ledger and reconcile them before phase completion.
- Do not mark a phase complete until the phase acceptance gate passes and the acceptance packet exists.
- Do not request `phase_completion` until the orchestrator has written the phase-transition handoff/report with local setup instructions and smoke-test expectations.
- Do not write abbreviated, malformed, manually typed, or unvalidated commit hashes into workflow state; resolve full 40-character hashes with `/usr/bin/git rev-parse ...^{commit}` and validate them before transition handling.
- Do not advance to the next phase before the supervisor merges or reconciles the accepted phase branch/worktree back into the run base branch and records the resulting base commit and any reconciliation decisions.
- Do not launch the next phase orchestrator before the supervisor has stopped the completed phase orchestrator pane/session or recorded an explicit teardown failure.
- Do not silently chain the next phase from the previous phase branch when the run base branch has not advanced.
- Do not discard, stash, overwrite, or ignore dirty/ad-hoc changes in the run base worktree during phase merge-back. Classify dirty paths, detect overlap with the accepted phase diff, preserve or reasonably reconcile changes when possible, record autonomous medium/high merge decisions, and stop only for critical conflicts that require human direction.
- Do not skip post-merge local verification setup after a phase transition. Start the project locally when feasible, report the reachable `localhost:<port>` URL and smoke-test instructions, and only treat missing secrets, paid/vendor setup, unavailable real dependencies, or similarly allowed escalations as blockers.
- Do not start the next phase orchestrator until the supervisor has read the transition handoff/report, performed or recorded local verification setup, and printed the smoke-test report for the completed phase.
- Do not stop after a phase completes while `run.yaml` points at another phase, unless execution scope is explicitly `single-phase`, an allowed escalation blocks progress, context handoff is required, or the user stops the workflow.
- Do not commit plaintext unsafe secrets; use `$secrets` for classification, generation, `git-secret`, and verification.

## Handoff

When pausing or completing, report:

```markdown
Implementation execution status: <running|blocked|complete>

Run state:
- `<run.yaml path>`

Current phase:
- `<phase plan path>` - <status>
- `<phase.yaml path>`

Orchestrator:
- pane: `<tmux pane id or inline fallback>`
- inbox: `<supervisor inbox path>`

Watchdog:
- pid: `<pid or disabled>`
- trigger: `<watchdog trigger path>`

Evidence:
- Acceptance packet: `<path or none yet>`
- Transition handoff: `<path or none yet>`
- QA artifacts: `<directory>`
- Local verification: `<localhost URL or blocked reason>`; smoke report: `<artifact/path or brief checklist>`

Blocked or escalated:
- <item or "None">
```
