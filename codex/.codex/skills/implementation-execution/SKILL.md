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

Supervisor, phase orchestrator, watchdog, and worker are distinct processes/responsibilities. On skill start, the current Codex session is the supervisor. The supervisor starts the active phase orchestrator as a separate top-level `codex` process in a new pane in the current tmux window so the human can see both, then starts a detached deterministic watchdog and ends the supervisor turn. Because the orchestrator is top-level, it can spawn and communicate with workers directly. The supervisor does not spawn workers, choose lanes, or read detailed phase state during normal work.

Supervisor/orchestrator communication uses one compact file: `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml`. The orchestrator writes heartbeat, blocked/escalation requests, graceful-exit requests, and phase-completion requests there. A detached non-LLM watchdog polls that file and wakes a short supervisor transition-handler Codex session only when action is needed. Workflow observability uses compact JSONL event logs under `docs/implementation-runs/<run-id>/events/`; do not use raw Codex session logs as workflow state. If tmux or Codex CLI process spawning is unavailable, record the fallback in `run.yaml` and the inbox; do not silently collapse the roles.

Human involvement is only for allowed escalations: credentials/secrets, paid/vendor setup, unresolved product/legal/security decisions, destructive production actions, real customer data access, or unavailable real dependencies after an agent-owned attempt.

General-purpose implementation workers are always available. If the approved phase plan names specialist implementation agents, treat them as fixed worker-routing metadata approved before planning. The execution workflow must not invent, propose, or block on new specialist agents during runtime; when no approved specialist clearly fits a lane, dispatch a general-purpose worker.

## Reference Modules

Load only the module needed for the current action:

- `references/state-files.md` - create, update, and resume `run.yaml`, `phase.yaml`, worker result YAML, handoffs, acceptance packets, and evidence artifacts.
- `references/supervisor.md` - run-level state machine, tmux-pane orchestrator process management, detached watchdog setup, transition-handler behavior, phase order, resumability, and escalation behavior.
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
3. Load `references/phase-orchestrator.md` and `references/branch-worktree.md` before starting or resuming the active phase.
4. Create or refresh the compact execution manifest for the active phase, validate any recorded orchestrator pane before trusting it, then start or resume the phase orchestrator in a new pane in the current tmux window. The orchestrator builds the active frontier from the manifest, task statuses, shared-resource constraints, and active worker lanes.
5. The orchestrator spawns workers directly for substantial implementation lanes, even when only one lane is currently available. Dispatch the planned approved specialist only when the manifest/task names one and the lane matches its approved scope; otherwise use a general-purpose worker. Keep glue, integration, tiny edits, state updates, and acceptance ownership with the orchestrator.
6. For behavior work, use `references/worker-tdd.md`: test-only goal first, agentic test approval, then implementation.
7. Use `references/agentic-review.md` for test review, implementation review, and fix loops.
8. After each worker result, the orchestrator integrates, runs the lane checkpoint, updates `phase.yaml`, reconciles mock/fixture ledger entries, and batches any needed plan consistency notes.
9. Use `references/qa-acceptance.md` before marking a phase complete.
10. The orchestrator writes a phase-completion request to the supervisor inbox when acceptance passes. The detached watchdog wakes a short supervisor transition handler. The supervisor verifies acceptance, fast-forwards the phase branch/worktree back into the run base branch, then advances `run.yaml`. If the base branch has diverged or cannot be fast-forwarded, stop with a supervisor escalation/handoff instead of silently chaining branches. If execution scope is `run` and another phase remains, the supervisor must transition the run and start the next phase orchestrator/watchdog from the updated base branch. Do not stop after a successful phase unless the user explicitly requested `single-phase`, an allowed escalation blocks progress, context handoff is required, or the user stops the workflow.
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
- Do not keep the supervisor Codex session alive as a resident polling daemon; launch a detached watchdog and resume supervisor work only for transition events.
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
- Do not write abbreviated, malformed, manually typed, or unvalidated commit hashes into workflow state; resolve full 40-character hashes with `/usr/bin/git rev-parse ...^{commit}` and validate them before transition handling.
- Do not advance to the next phase before the supervisor fast-forwards the accepted phase branch/worktree back into the run base branch and records the resulting base commit.
- Do not silently chain the next phase from the previous phase branch when the run base branch has not advanced.
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
- QA artifacts: `<directory>`

Blocked or escalated:
- <item or "None">
```
