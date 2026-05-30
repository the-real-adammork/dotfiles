---
name: implementation-execution
description: "Use when implementing approved implementation phase plans with a git-native, file-backed agent workflow: supervisor-routed phase transitions, Codex app-server supervisor wakeups, same-session watchdogs, tmux-pane phase orchestrators, bounded worker agents, blocker-resolver agents, TDD test approval gates, YAML run state, artifact-backed verification, phase acceptance gates, resumable handoffs, and autonomous execution without Linear or SQLite."
---

# Implementation Execution

Run approved implementation phase plans through a durable, file-backed agent workflow. This skill is independent of deprecated Linear/SQLite implementation workflows.

## Start

Announce: "I'm using the implementation-execution skill to run the phase plans with YAML state, a supervisor-managed tmux orchestrator, Codex app-server supervisor wakeups, a same-session watchdog, native phase-merge and phase-transition sub-agents, bounded workers, blocker resolvers, and phase acceptance gates."

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

- YAML tracks state, split by ownership to avoid merge conflicts.
- Markdown explains decisions.
- Artifacts hold evidence.
- JSONL events explain workflow timing and communication volume.
- Do not make markdown the database.

One supervisor owns the run and is the only writer of `run.yaml`. One top-level Codex CLI phase orchestrator coordinates each active phase and writes only its `phases/<phase>.yaml`, compact inbox, worker results, blocker results, handoffs, and artifacts. The phase orchestrator does not own implementation-plan tasks or phase acceptance execution. Every task in the execution manifest must be assigned to a worker lane, even when the task is serial, small, acceptance-oriented, or mostly documentation/config. Phase acceptance must be delegated to a general-purpose acceptance worker/agent, not run inline by the orchestrator. Native supervisor-spawned phase-merge and phase-transition sub-agents own context-heavy supervisor-side work and write only `transitions/<completed-phase>.yaml` plus referenced artifacts. The phase-merge sub-agent owns the blocking merge/reconciliation work for a completed phase. The phase-transition sub-agent owns post-advance local setup, local verification, and smoke reporting after the next orchestrator is already started. Worker agents handle bounded implementation, docs, config, testing, acceptance-prep, acceptance verification, handoff drafting, and remediation lanes. Blocker-resolver agents handle bounded setup, dependency, runtime, toolchain, environment, and verification blockers that are agent-owned but would distract implementation workers or the orchestrator. Workers cannot spawn workers or coordinate directly with sibling workers. The phase orchestrator is the scheduler, reviewer, integrator, and lifecycle-state writer for its phase.

Supervisor, phase orchestrator, watchdog, and worker are distinct processes/responsibilities. On skill start, the current Codex session is the supervisor. The supervisor records its own Codex thread id plus tmux session/window/pane identity, starts the active phase orchestrator as a separate top-level `codex` process in a new pane in the current tmux window so the human can see both, then starts a deterministic watchdog in the same tmux session and ends the supervisor turn. The watchdog and post-merge local verification panes may share a separate workflow window in that same session so they are out of view from the primary supervisor/orchestrator panes. Because the orchestrator is top-level, it can spawn and communicate with implementation workers directly. The supervisor does not spawn implementation workers, choose lanes, or read detailed phase state during normal work; it may spawn native phase-merge and phase-transition sub-agents only for supervisor-owned transition work.

Supervisor/orchestrator communication uses one compact file: `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml`. The orchestrator writes heartbeat, blocked/escalation requests, graceful-exit requests, and phase-completion requests there. A non-LLM watchdog polls that file and wakes the original supervisor Codex thread only when action is needed by starting a transition-router turn through `codex app-server`. The watchdog must never launch a fresh supervisor transition-handler Codex session, and must not rely on `tmux send-keys` for normal communication. For `phase_completion`, the original supervisor acts as a short transition router: it validates the trigger, creates or opens `transitions/<phase>.yaml`, spawns a native phase-merge sub-agent, records that delegation in the transition file, waits for the sub-agent result, and does not do merge-back itself. The merge sub-agent performs only the blocking merge/reconciliation into the run base branch, records the resulting base commit and merge decisions in the transition file, and returns a compact result to the supervisor. The supervisor then stops the completed orchestrator, marks the phase-completion trigger handled, updates only minimal `run.yaml` pointers/status on the base branch, starts the next phase orchestrator/watchdog from the updated base branch when appropriate, and only after that spawns a native phase-transition sub-agent for local setup, local verification, and smoke-report artifact creation. The transition sub-agent records local verification and smoke-report state in the transition file, returns its smoke report result to the supervisor, and the supervisor prints it without blocking the already-started next phase. After required transition work is recorded, the supervisor may launch `~/.codex/skills/workflow-auditor/SKILL.md` in the background for later human review; workflow auditing must never block next-phase startup, local verification, smoke-report printing, escalation routing, or other supervisor responsibilities. If the recorded supervisor thread cannot be resumed or the app-server turn cannot be started, the watchdog records a Codex control-plane wake blocker, writes a blocked trigger, appends a compact event, and stops so the supervisor communication path can be repaired. Workflow observability uses compact JSONL event logs under `docs/implementation-runs/<run-id>/events/`; do not use raw Codex session logs as workflow state. If tmux or Codex CLI process spawning is unavailable, record the degraded state in `run.yaml` and the inbox and stop; do not silently collapse the roles into the supervisor.

The watchdog must be visibly inspectable while it runs. Its tmux pane should print timestamped one-line status messages for startup, each poll, inbox decisions, orchestrator pane health, heartbeat checks, trigger creation, supervisor-pane validation, wake success, and blocked wake failures. Reserve `events/*.jsonl` for compact structured lifecycle events; do not create a separate mirrored human-readable watchdog log file.

Human involvement is only for allowed escalations: credentials/secrets, paid/vendor setup, unresolved product/legal/security decisions, destructive production actions, real customer data access, or unavailable real dependencies after a blocker-resolver or other agent-owned attempt.

Implementation workers may use repo-approved specialist agents when the approved plan, repo instructions, or installed local skills explicitly define them for the lane. Use `general-purpose worker` as the default/fallback worker type when no approved specialist is named. Reviewer, fix-worker, and blocker-resolver roles remain available for review, remediation, and unblocking loops. Ignore legacy custom-agent routing in old plans or manifests unless it is confirmed by current repo instructions or installed local skills, and do not invent, propose, request, wait for, or dispatch unapproved repo-specific implementation agents during runtime.

## Reference Modules

Load only the module needed for the current action:

- `references/state-files.md` - create, update, and resume tiny supervisor-owned `run.yaml`, phase YAML, transition YAML, worker result YAML, handoffs, acceptance packets, and evidence artifacts.
- `references/supervisor.md` - run-level state machine, transition routing, phase order, resumability, role separation, and escalation behavior.
- `references/supervisor-orchestrator-process.md` - tmux orchestrator pane launch, launch autonomy, pane validation, and invalid-pane recovery.
- `references/codex-mcp-control-plane.md` - Codex app-server thread/turn control plane for supervisor wakeups.
- `references/supervisor-watchdog.md` - same-session watchdog setup, trigger generation, transition-router wake behavior, and watchdog script shape.
- `references/phase-merge-worker.md` - native phase-merge sub-agent launch, merge-back scope, result contract, and completion contract.
- `references/phase-transition-worker.md` - post-advance native phase-transition sub-agent launch, local verification scope, smoke-report result contract, and completion contract.
- `references/phase-merge-back.md` - accepted phase merge-back, dirty base worktree preservation, merge reconciliation, conflict resolution, and decision logging.
- `references/local-verification.md` - post-merge local setup, dependency refresh, service launch, localhost URL discovery, and smoke-test instructions.
- `references/phase-orchestrator.md` - phase orchestrator coordination, active frontier construction, worker dispatch, `/goal` usage, integration checkpoints, and phase branch coordination.
- `references/branch-worktree.md` - phase branch, worker branch/worktree isolation, merge-back rules, and parallel lane safety.
- `references/worker-tdd.md` - bounded worker contract, two-stage TDD flow, test proposal approval, implementation, worker result YAML, and worker restrictions.
- `references/agentic-review.md` - agentic test review, implementation review, fix-worker loop, and mock/fixture ledger review rules.
- `references/blocker-resolver.md` - blocker classification, resolver dispatch, allowed setup actions, true-blocker reporting, and resolver result YAML.
- `references/qa-acceptance.md` - phase acceptance gate, service-wiring verification, mock/fixture ledger reconciliation, platform E2E expectations, and acceptance packet contents.
- `references/lessons.md` - lesson candidate rules, orchestrator promotion criteria, `docs/lessons` creation, and `AGENTS.md` pointers.
- `references/consistency-handoff.md` - batched plan consistency updates, compact actual-vs-planned notes, context handoffs, and final output.
- Use `$secrets` before generating, writing, revealing, hiding, staging, committing, or reviewing secrets, credentials, env files, database passwords, app keys, API tokens, or secret-bearing config.

## Workflow

1. Load `references/state-files.md` and create or resume the run state.
2. Load `references/supervisor.md` and choose the current phase from `run.yaml`.
3. Load `references/supervisor-orchestrator-process.md`, `references/codex-mcp-control-plane.md`, `references/supervisor-watchdog.md`, `references/phase-orchestrator.md`, and `references/branch-worktree.md` before starting or resuming the active phase.
4. Create or refresh the compact generated execution manifest for the active phase, validate any recorded orchestrator pane before trusting it, then start or resume the phase orchestrator in a new pane in the current tmux window. The manifest is a small routing index, not duplicated phase-plan state. The orchestrator builds the active frontier from the manifest, task statuses, shared-resource constraints, and active worker lanes.
5. The orchestrator spawns the manifest-specified worker agent directly for every manifest task, even when only one task is available and even when the lane is serial. If the manifest does not name a repo-approved specialist, use `general-purpose worker`. The orchestrator may do lifecycle bookkeeping, integration decisions, worker result review, phase-state updates, acceptance-worker dispatch, acceptance result validation, and phase-completion routing, but those are not implementation-plan tasks and must not involve product/test/runtime file changes. Use reviewer and fix-worker roles only for review/remediation loops. Use blocker-resolver agents only when a worker, reviewer, fix-worker, acceptance command, or the orchestrator itself identifies a blocker that may be agent-owned setup or dependency work.
6. For behavior work, use `references/worker-tdd.md`: test-only goal first, agentic test approval, then implementation.
7. Use `references/agentic-review.md` for test review, implementation review, and fix loops.
8. After each worker result, the orchestrator integrates, runs the lane checkpoint, updates `phase.yaml`, reconciles mock/fixture ledger entries, and batches any needed plan consistency notes. If the result reports a blocker, load `references/blocker-resolver.md` before deciding whether to dispatch a blocker-resolver or escalate.
9. When all manifest tasks are integrated and no active worker lanes remain, load `references/qa-acceptance.md` and dispatch a general-purpose acceptance worker/agent. The acceptance worker runs the phase acceptance gate, reconciles service-wiring evidence and mock/fixture ledgers, writes the acceptance packet, drafts the phase-transition handoff/report, and returns a compact acceptance result. The orchestrator must not run acceptance inline.
10. The orchestrator validates the acceptance worker result, updates only lifecycle state in `phase.yaml`, and writes the phase-completion request to the supervisor inbox when acceptance passes. The acceptance worker's handoff/report must include local setup instructions, expected ports, caveats, smoke tests for the new behavior, and seeded local admin access instructions when any smoke path requires login. The same-session watchdog wakes the original supervisor thread as a short transition router through the Codex app-server control plane. The supervisor validates the trigger, creates or opens `transitions/<phase>.yaml`, records phase-merge sub-agent delegation there, and spawns a native phase-merge sub-agent. The phase-merge sub-agent verifies acceptance, reads the transition handoff/report, loads `references/phase-merge-back.md`, reconciles the accepted phase branch/worktree back into the run base branch, records the resulting base commit and any merge decisions in the transition YAML, then returns a compact result to the supervisor. The supervisor terminates the completed phase orchestrator pane/session, marks the phase-completion trigger handled in the transition YAML, updates only minimal completed/current-phase pointers in `run.yaml`, and starts the next phase orchestrator/watchdog automatically from the updated base branch when execution scope continues. Only after next-phase startup is recorded does the supervisor spawn a native phase-transition sub-agent. The phase-transition sub-agent loads `references/local-verification.md`, performs post-merge local verification setup from the completed phase handoff/report, writes a smoke-test report artifact, records local verification in the transition YAML, and returns a compact result to the supervisor. The supervisor then prints the local URL and smoke-test report for the human while the next phase is already running. Missing secrets, paid/vendor access, unavailable external services, or other allowed escalations may be flagged; ordinary local setup friction remains agent-owned. Do not stop after a successful phase unless the user explicitly requested `single-phase`, an allowed escalation blocks progress, context handoff is required, or the user stops the workflow.
11. After required transition work is recorded, the supervisor may start a background workflow-auditor run for later review. This is fire-and-forget: record the expected report path or process id when practical, then continue supervisor work without waiting.
12. Use `references/lessons.md` when worker/reviewer results reveal a recurring proven problem future agents should avoid.
13. Use `references/consistency-handoff.md` for downstream plan updates, handoffs, final reporting, or blocked states.

## Non-Negotiables

- Do not use SQLite as workflow state.
- Do not use Linear as workflow state.
- Do not base execution on deprecated Linear/SQLite implementation supervisor skills.
- Do not create PR/MR per task by default.
- Do not write huge markdown review packets.
- Do not save full stdout in YAML or markdown.
- Do not use raw Codex session logs as workflow state; store only their session id/path in YAML and compact workflow events in `events/*.jsonl`.
- Do not paste full skill bodies, full phase plans, full diffs, or broad command output into spawned orchestrator or worker prompts. Pass file paths plus a compact execution manifest.
- Do not duplicate phase-plan task details into manifests or phase state. Manifests are generated routing indexes; phase plans remain the source of truth for task detail.
- Do not let phase branches, phase orchestrators, workers, phase-merge sub-agents, or phase-transition sub-agents edit `run.yaml`. Only the supervisor edits `run.yaml`, and only with minimal run-level pointers/status.
- Do not keep the phase orchestrator inline. Start it in a new pane in the current tmux window with `--dangerously-bypass-approvals-and-sandbox`, and record it in `run.yaml`/`phase.yaml`; if that launch path is unavailable, block and repair the process launch path.
- Do not keep the supervisor Codex session alive as a resident polling daemon; launch a same-session watchdog and resume supervisor work only by starting transition-router turns on the recorded supervisor thread through the Codex app-server control plane.
- Do not create a fresh transition-handler Codex pane or process from the watchdog. Use the recorded original supervisor thread with `codex app-server`; if the thread cannot be resumed or the turn cannot be started, record a blocked trigger and repair the supervisor communication path.
- Do not perform context-heavy `phase_completion` transition work inline in the original supervisor thread. The original supervisor should route the trigger to a native phase-merge sub-agent and wait for its result. If that sub-agent cannot be spawned, record a blocked transition instead of doing merge-back inline.
- Do not launch tmux orchestrators with prompts containing unescaped `$implementation-execution`; shell expansion can erase the skill name. Use plain text such as `Use the implementation-execution skill...` or escape the dollar sign.
- Do not blindly trust a recorded orchestrator pane in `run.yaml`, `phase.yaml`, or the inbox. Validate the tmux pane, command/process, launch flags, expected prompt paths, and fresh heartbeat before resuming.
- Do not let the supervisor choose implementation lanes, dispatch workers, or read detailed phase state during normal work; the orchestrator owns phase execution and workers.
- Do not let the supervisor approve or reject Codex edit/command prompts in the orchestrator pane. Approval prompts mean the orchestrator was launched with the wrong autonomy settings and should be restarted or blocked, not manually driven.
- Do not let the orchestrator own implementation-plan tasks. Every task in the execution manifest must be assigned to a worker lane with an approved worker agent; default to `general-purpose worker` when no repo-approved specialist is named. The orchestrator only coordinates, reviews, integrates, records state, and runs lifecycle gates.
- Do not let the orchestrator run phase acceptance inline. Phase acceptance is delegated to an approved acceptance worker/agent, defaulting to `general-purpose worker`, that writes the acceptance packet, acceptance artifacts, and transition handoff/report; the orchestrator only validates the returned result and routes phase completion.
- Do not let the orchestrator edit product code, tests, runtime docs, user-facing content, fixtures, migrations, schemas, configs, Makefiles, scripts, generated assets, registry data, or runtime assets for a task. If those files must change, dispatch a worker, fix-worker, or blocker-resolver.
- Do not represent lifecycle bookkeeping as tasks. Phase kickoff and manifest/state initialization are orchestrator lifecycle responsibilities outside the task list. Acceptance packet creation, final acceptance collation, and transition handoff drafting belong to the delegated acceptance worker/agent.
- Do not let acceptance failures turn into inline orchestrator fixes. If acceptance, verification, or live smoke exposes implementation work, dispatch a worker/fix-worker/blocker-resolver and require a result artifact before continuing.
- Do not mark a worker-owned task done without a worker dispatch event, worker result YAML, integration checkpoint, and artifact evidence.
- Do not let workers spawn workers.
- Do not classify development setup friction, missing local tools, dependency installs, generated-file gaps, local runtime setup, port conflicts, container setup, test-environment drift, or missing non-secret env wiring as human blockers until a blocker-resolver has attempted to resolve them or recorded why they are outside agent-owned setup.
- Do not accept mock-only completion for service wiring that requires real integration proof.
- Do not ban useful mocks/fixtures during implementation; track them in the mock/fixture ledger and reconcile them before phase completion.
- Do not mark a phase complete until the phase acceptance gate passes and the acceptance packet exists.
- Do not request `phase_completion` until the delegated acceptance worker/agent has written the phase-transition handoff/report with local setup instructions and smoke-test expectations, and the orchestrator has validated that result.
- Do not put smoke-test instructions, reviewer instructions, implementation workflow prompts, agent handoff text, acceptance checklists, internal QA notes, or local setup guidance into the actual product UI, API responses, seed user-facing content, generated demo content, or runtime assets unless the product requirements explicitly call for end-user help content. These belong in handoff documents, QA artifacts, acceptance packets, transition YAML, or developer docs only. If workflow-only text appears in runtime app files, phase acceptance is blocked until it is removed from the app surface.
- Do not request `phase_completion` for an app with login-gated smoke tests unless local setup seeds an admin user and the transition handoff/report tells the supervisor how to access it. Include harmless local/demo credentials only when classified safe under `$secrets`; otherwise list the ignored plaintext file path and variable/account names without printing secret values.
- Do not write abbreviated, malformed, manually typed, or unvalidated commit hashes into workflow state; resolve full 40-character hashes with `/usr/bin/git rev-parse ...^{commit}` and validate them before transition handling.
- Do not advance to the next phase before the phase-merge sub-agent merges or reconciles the accepted phase branch/worktree back into the run base branch and records the resulting base commit and any reconciliation decisions in `transitions/<phase>.yaml`.
- Do not launch the next phase orchestrator before the supervisor has stopped the completed phase orchestrator pane/session or recorded an explicit teardown failure.
- Do not silently chain the next phase from the previous phase branch when the run base branch has not advanced.
- Do not discard, stash, overwrite, or ignore dirty/ad-hoc changes in the run base worktree during phase merge-back. Classify dirty paths, detect overlap with the accepted phase diff, preserve or reasonably reconcile changes when possible, record autonomous medium/high merge decisions, and stop only for critical conflicts that require human direction.
- Do not skip post-merge local verification setup after a phase transition. After the next orchestrator is started, the phase-transition sub-agent starts the completed phase locally when feasible and records the reachable `localhost:<port>` URL and smoke-test instructions; only missing secrets, paid/vendor setup, unavailable real dependencies after an agent-owned setup attempt, or similarly allowed escalations are blockers.
- Do not block next-phase orchestrator startup on local verification or smoke-report printing after the completed phase has been merged to the run base branch and the completed orchestrator has been stopped.
- Do not block supervisor progress on workflow-auditor reports. Workflow auditing is background follow-up for later review, not a prerequisite for phase transition, local verification, smoke reporting, or escalation handling.
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
- pane: `<tmux pane id or unavailable>`
- inbox: `<supervisor inbox path>`

Watchdog:
- pid: `<pid or disabled>`
- trigger: `<watchdog trigger path>`

Phase merge sub-agent:
- agent: `<native sub-agent id or none>`
- status: `<not_started|running|ready_for_supervisor|blocked|complete|failed>`

Phase transition sub-agent:
- agent: `<native sub-agent id or none>`
- status: `<not_started|running|ready_for_report|blocked|complete|failed>`

Evidence:
- Acceptance packet: `<path or none yet>`
- Transition handoff: `<path or none yet>`
- Transition state: `<transitions/<phase>.yaml or none yet>`
- QA artifacts: `<directory>`
- Local verification: `<localhost URL or blocked reason>`; smoke report: `<artifact/path or brief checklist>`

Blocked or escalated:
- <item or "None">
```
