# Phase Orchestrator

The phase orchestrator is a separate top-level Codex CLI process for one phase, normally launched by the supervisor in a new pane in the current tmux window. It coordinates the phase branch/worktree, active frontier, worker dispatch, worker communication, integration, verification gates, `phase.yaml`, acceptance-worker dispatch, and compact supervisor inbox updates. It must not own implementation-plan tasks or run phase acceptance inline.

Because the orchestrator is a top-level Codex process, it can spawn and communicate with worker agents directly. It can also dispatch blocker-resolver agents for bounded unblocking work and an acceptance worker/agent for the phase acceptance gate. Every manifest task must be delegated to a worker lane with an approved worker agent; use `general-purpose worker` when no repo-approved specialist is named. The orchestrator's own work is lifecycle coordination, not task execution or acceptance execution. It should write only lifecycle-level messages to the supervisor inbox; detailed worker, blocker, and acceptance state stays in `phase.yaml`, worker/blocker/acceptance result YAML, acceptance packets, and QA artifacts.

The orchestrator is launched with `--dangerously-bypass-approvals-and-sandbox` so it can own worker approvals and phase execution without blocking on Codex edit prompts. Do not ask the supervisor to approve worker edits. Human-only blockers must be written to the supervisor inbox as workflow escalations only after blocker-resolver handling when the issue may be agent-owned setup.

The orchestrator does not perform phase transition work. On normal phase completion, it must validate the delegated acceptance worker result and route completion, but it must not run acceptance inline, merge back to the run base branch, launch local verification, start the next phase, or produce final-style user reporting. It stops at accepted phase state: `phase.yaml` complete, acceptance packet current from the acceptance worker, artifacts recorded, a phase-transition handoff/report written by the acceptance worker, and `request.type: phase_completion` written to the supervisor inbox. The supervisor routes completion first to a native phase-merge sub-agent for merge-back, then after the supervisor stops the completed orchestrator and starts the next phase, to a post-advance native phase-transition sub-agent for local verification and smoke reporting.

Workflow instructions are not product requirements. The orchestrator must prevent workers from adding smoke-test steps, reviewer instructions, local setup notes, acceptance checklist text, agent prompts, handoff language, or internal QA guidance to product UI, API responses, seed user-facing content, generated demo content, screenshots intended as app fixtures, or runtime assets. If a task explicitly requires product help/onboarding copy, frame it as end-user product copy and keep implementation workflow language out of the app.

## Startup Handshake

On startup:

1. Read `run.yaml`, `phase.yaml`, the execution manifest, and the supervisor inbox path from the launch prompt.
2. Verify the manifest phase matches the active `phase.yaml`.
3. Write a compact inbox update with `orchestrator_status: running`, fresh heartbeat, `tmux.pane_id`, `startup.acknowledged: true`, `startup.manifest: <manifest>`, and best-effort `codex_session` id/path if discoverable.
4. Append an `orchestrator_started` event to `docs/implementation-runs/<run-id>/events/orchestrator-<phase>.jsonl`.

If the manifest is missing, stale, or points at a different phase, write `request.type: restart_needed` or an allowed escalation to the inbox instead of reading the entire plan and continuing on assumptions.

## Active Frontier

Build the frontier from:

- the execution manifest task dependencies and execution lanes;
- `phase.yaml` task statuses;
- shared-resource constraints from manifest task file scope, service-wiring rows, and execution lanes;
- active worker lanes;
- pending consistency updates that could affect future tasks.

Use the full phase plan only for targeted task context. Before dispatching a worker, read the selected task section using the manifest's `plan_section_anchor`, and stop at the next task heading. Do not load or paste the full phase plan into the orchestrator's normal scheduling loop or worker goal.

Dispatch workers for every task in the manifest, including serial lanes where only one task can safely run right now. Do not keep task work with the orchestrator because it seems small, glue-like, acceptance-oriented, documentation-only, config-only, or easier to do inline. The orchestrator may update workflow state, collate acceptance evidence, write handoffs, and make integration decisions, but it must not change product/test/runtime files for task completion.

Implementation workers may use repo-approved specialist agents when the approved plan, repo instructions, or installed local skills explicitly define them for the lane. Use `general-purpose worker` as the default/fallback worker type. Ignore legacy custom-agent routing in old plans or manifests unless it is confirmed by current repo instructions or installed local skills. Do not invent, propose, request, wait for, or dispatch unapproved repo-specific implementation agents during execution. Reviewer and fix-worker roles are reserved for review/remediation loops. Blocker-resolver is a separate non-implementation agent type for setup/dependency/runtime/workflow blockers.

Use this selection order:

1. Exclude tasks already `done`, `blocked`, `deferred`, or assigned to an active lane.
2. Exclude tasks whose `Depends On` entries are not complete.
3. Exclude tasks affected by pending consistency updates.
4. Group remaining tasks by shared files, schemas, migrations, generated files, services, databases, queues, ports, devices, and external dependencies.
5. Use the manifest-specified worker agent when it is repo-approved; otherwise use `general-purpose worker`.
6. Prefer the smallest set of substantial non-overlapping worker lanes that can make progress.
7. Cap concurrent worker lanes to what the repo can safely isolate; default to one worker lane unless independence is clear.
8. Dispatch at least one worker for the active frontier whenever any task remains, even when the frontier is serial.
9. Keep only lifecycle bookkeeping, integration decisions, state updates, acceptance-worker dispatch, acceptance result validation, and phase-completion routing with the orchestrator; product/test/runtime changes and acceptance execution always go to a worker, fix-worker, blocker-resolver, or acceptance worker.

## Worker Count

Decide worker count after reading the manifest and state. Read the selected task section from the phase plan only after the active frontier chooses a lane. Prefer a small number of lanes, but do not collapse substantial implementation into the orchestrator merely because only one lane is currently unblocked.

- Good lanes: isolated UI workflow, isolated service/API path, E2E harness setup, migration plus repository layer, focused review/fix lane.
- Good serial worker lanes: foundational scaffold, contract/test harness, first persistence adapter, first E2E harness, or any task likely to consume enough context that preserving orchestrator headroom matters.
- Bad parallel lanes: unclear ownership, tasks requiring constant phase context, or tasks touching the same schema/API/runtime resource as another active lane. Make these serial worker lanes instead of orchestrator work.

Use zero workers only when no manifest task remains and the next work is pure lifecycle bookkeeping, such as updating `phase.yaml`, refreshing the inbox, or validating the delegated acceptance worker result. Acceptance packet creation, acceptance evidence collation, and transition handoff writing belong to the acceptance worker. If a manifest task remains, spawn one worker for serial work, and more workers only when independence and resource isolation are clear.

## Orchestrator Edit Allowlist

The orchestrator may edit workflow files only:

- `docs/implementation-runs/<run-id>/phases/<phase>.yaml`;
- `docs/implementation-runs/<run-id>/supervisor-inbox/<phase>.yaml`;
- `docs/implementation-runs/<run-id>/events/orchestrator-<phase>.jsonl`;
- `docs/implementation-runs/<run-id>/handoffs/<phase>-transition.md` only when copying or validating the delegated acceptance worker's handoff result;
- `docs/qa/phase-acceptance/<phase>.md` only when copying or validating the delegated acceptance worker's packet result;
- `docs/qa/artifacts/<phase>/` summaries that collate existing worker/checkpoint evidence, not acceptance command output generated inline;
- manifest/state repair files when the repair is purely workflow metadata.

The orchestrator must not edit product code, tests, runtime documentation, user-facing content, fixtures, migrations, schemas, configs, Makefiles, scripts, generated assets, registry data, runtime assets, or dependency files to complete a task. If one of those files must change, dispatch a worker, fix-worker, or blocker-resolver and integrate the result.

## `/goal` Usage

Use `/goal` only after the orchestrator has selected the next lane and is ready to dispatch the worker.

Every worker goal must include:

- run id;
- phase plan path;
- execution manifest path;
- task heading or lane scope;
- worker agent type from the manifest, defaulting to `general-purpose worker`;
- selected task section from the phase plan, not the whole plan;
- `run.yaml`, `phase.yaml`, and worker result YAML path;
- branch/worktree and base commit;
- allowed files or directories;
- service-wiring rows covered;
- required commands and artifact directory;
- explicit instruction not to update `run.yaml` or `phase.yaml`;
- explicit instruction that workflow smoke/review/setup/handoff/acceptance instructions are not product requirements and must not be implemented in runtime app surfaces;
- return contract.
- blocker reporting rules: classify setup/dependency/runtime/env/workflow blockers separately from product/test failures and include artifact paths.

Record each worker dispatch in `phase.yaml` and the worker result YAML path. Do not send worker dispatch details to the supervisor inbox unless the supervisor must handle a process failure.

Append compact dispatch and result events to `events/orchestrator-<phase>.jsonl`. Save full command output to artifacts and reference the artifact path in state/results/events.

Do not mark a task `done`, `accepted`, or `complete` unless there is a worker dispatch record, a worker result YAML, integration checkpoint evidence, and artifact paths for that task. If an existing plan or manifest names an `owner: orchestrator` task, immediately write a consistency update that converts it to one or more worker lanes before work begins, preserving safe parallelism based on task dependencies, integration checkpoints, and shared-resource constraints. Use a serial worker lane only when dependencies or resource collisions require serialization.

```yaml
active_lanes:
  - lane: "<lane-slug>"
    task: "Task N"
    status: "test_proposed"
    worker: "<worker-id>"
    worker_agent: "general-purpose worker"
    branch: "impl/<phase>/<lane>"
    worktree: ".worktrees/impl-<phase>-<lane>"
    result: "docs/implementation-runs/<run-id>/workers/<lane>-<timestamp>.yaml"
```

For behavior tasks, use two goals:

1. Test-only goal before implementation.
2. Implementation goal after agentic test approval.

Test-only goal shape:

```text
Goal: Write failing tests for <Task/Lane> only. Do not implement production code.
Worker agent: <manifest worker agent or general-purpose worker>.
Use execution manifest: <manifest-path>.
Use selected task context: <task heading/section>.
Use worker result path: <path>.
Do not update run.yaml or phase.yaml.
Do not add workflow-only smoke/review/setup/handoff/acceptance text to runtime UI, API responses, seed user-facing content, or generated app content.
Return test files changed, commands run, expected failure, requirement mapping, service-wiring rows covered, and blockers.
```

Implementation goal shape:

```text
Goal: Implement <Task/Lane> until the approved tests pass. Do not broaden scope.
Worker agent: <manifest worker agent or general-purpose worker>.
Use execution manifest: <manifest-path>.
Use selected task context: <task heading/section>.
Use worker result path: <path>.
Do not update run.yaml or phase.yaml.
Do not add workflow-only smoke/review/setup/handoff/acceptance text to runtime UI, API responses, seed user-facing content, or generated app content.
Return changed files, commands run, evidence, service-wiring rows covered, residual risks, and task completion result YAML.
```

Prefer resuming the same worker after test approval when context is still healthy. Use a fresh implementation worker when context is bloated, the task is risky, or the test proposal result is enough to hand off cleanly.

## Blocker Handling

Treat blockers as state that needs an owner. A blocker is not human-only just because a command failed, a dependency is missing, or a local service is unavailable.

When a worker, reviewer, fix-worker, acceptance command, or the orchestrator reports a blocker:

1. Save the failing command output or short diagnostic to a QA artifact.
2. Add or update `phase.yaml` `blockers` with an id, classification, source artifact, status, and owner.
3. If the classification may be `setup_dependency`, `runtime_dependency`, `env_config`, or `workflow_state`, load `references/blocker-resolver.md` and dispatch a blocker-resolver.
4. If the classification is clearly `secret_or_account`, `external_service`, or `product_decision`, dispatch a blocker-resolver only when there is a safe local setup attempt left. Otherwise write a true escalation report with exact human action needed.
5. After resolver completion, rerun the blocked checkpoint or acceptance command when `safe_to_continue: true`.
6. Only stop phase execution when the resolver returns `true_blocker`, the blocker invalidates acceptance, and no other safe work remains.

Good blocker-resolver candidates:

- missing local tool or runtime such as `kind`, `minikube`, Playwright browsers, test CLIs, SDKs, emulators, or generated code;
- missing non-secret env variable where `.env.example`, README, or docs can be patched;
- setup drift such as stale `.venv`, missing `node_modules`, migrations, seed data, or local containers;
- local port conflict or dev service health failure;
- workflow-state repair such as malformed state fields, branch/worktree conflicts, or missing generated artifacts.

Do not send a blocker to the supervisor until resolver evidence proves it is outside agent-owned setup or the phase plan explicitly allows completion with that unresolved boundary.

If acceptance or verification reveals a code, test, config, runtime, docs, registry, target-data, fixture, generated-asset, or dependency-file defect, the orchestrator must dispatch a worker, fix-worker, or blocker-resolver. It may rerun the failed command and record evidence, but it must not patch the defect inline.

## Supervisor Inbox

Write a compact lifecycle update to `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml` at startup, periodically while running, when blocked, when requesting graceful exit, and when phase acceptance completes.

The inbox is not the phase database. Do not put worker details, full command output, review text, or detailed active-lane state there.

Set:

- `orchestrator_status: running` with fresh heartbeat while active.
- `startup.acknowledged: true`, expected manifest path, pane id, and best-effort Codex session id/path at startup.
- `request.type: escalation` only for allowed escalations the supervisor must surface or preserve.
- `request.type: restart_needed` when the orchestrator cannot continue safely.
- `request.type: phase_completion` only after phase acceptance passed, the acceptance packet exists, the phase-transition handoff/report exists, and `phase_completion.commit` is a quoted full 40-character commit hash resolved with `/usr/bin/git rev-parse HEAD^{commit}`.
- `request.type: graceful_exit` when the supervisor should close the pane after state is safely written.

After writing `request.type: phase_completion`, the orchestrator should leave the pane idle or request graceful exit. If context is exhausted before the completion request and phase-transition handoff/report are safely written, write a blocked/restart-needed inbox request instead of asking the supervisor to infer missing setup or smoke-test details.

## Acceptance Worker Dispatch

After all manifest tasks are integrated and no active lanes remain, dispatch a general-purpose acceptance worker/agent with `references/qa-acceptance.md`.

The acceptance worker owns:

- running the phase acceptance commands and audits;
- reconciling service-wiring evidence and mock/fixture ledger entries;
- writing the acceptance packet;
- writing the phase-transition handoff/report;
- returning accepted commit, packet path, handoff path, command artifacts, blocker-resolver requirements, and residual risks.

The orchestrator owns only acceptance-worker dispatch, result validation, lifecycle state updates in `phase.yaml`, and supervisor inbox routing. If the acceptance worker reports implementation defects, missing setup, runtime/tooling issues, or workflow-state blockers, dispatch a fix-worker or blocker-resolver. Do not patch or rerun the acceptance gate inline as a substitute for the delegated acceptance result.

## Phase-Transition Handoff Report

After phase acceptance passes and before writing `request.type: phase_completion`, ensure the acceptance worker wrote a compact handoff/report under:

```text
docs/implementation-runs/<run-id>/handoffs/<phase-slug>-transition.md
```

This is not final user reporting and does not transfer ownership of implementation work. It is the phase-merge sub-agent's input for merge-back, the post-advance transition sub-agent's input for local verification, and the supervisor's input for next-phase startup plus later smoke-test reporting.

Required contents:

- phase slug, run id, phase plan path, `phase.yaml`, acceptance packet path, accepted commit, and artifact directory;
- concise summary of new expected behavior delivered by the phase;
- setup instructions for running the completed phase locally from the run base worktree after merge-back, including dependency install, env/example setup, local services, migrations/seeds, dev server command, expected ports, and safe alternate-port guidance when known;
- seeded local admin access details for any login-gated app or smoke path. If credentials are harmless local/demo values classified safe by `$secrets`, include the username/email and password directly. If credentials are unsafe plaintext or stored in an ignored file, list the exact ignored file path and account/variable names where the human can find them, without printing secret values. If no seeded admin user exists, treat it as a phase-completion gap and do not request `phase_completion`;
- human smoke-test checklist focused on new behavior and acceptance boundaries, with expected outcomes and any login/demo/test data needed;
- known local setup caveats, such as safe placeholder env values, required external services, intentionally unavailable devices, port conflicts seen during acceptance, or commands that must not be run against production data;
- verification commands and artifacts that prove the phase passed acceptance;
- residual risks and downstream assumptions that matter to later phases.

The setup instructions must be concrete enough that the supervisor can execute them without re-reading the full phase plan. For login-gated apps, concrete setup includes a seeded local admin account and a clear path to credentials. If the phase cannot be launched locally because of an allowed escalation, state the blocker explicitly and include the closest useful smoke-test alternative. Missing seeded local admin access is not an allowed escalation by itself; fix the seed/setup path before requesting phase completion.

The handoff/report is the only normal home for human smoke-test instructions. Do not duplicate the handoff/report checklist into the app as banners, cards, helper copy, route content, seed records, or demo data. Product help text is allowed only when it is a real product requirement and is written for end users, not for the implementation reviewer or supervisor.

## Integration Checkpoint

After every worker result:

1. Inspect changed files and result YAML.
2. Run the task/lane checkpoint from the implementation plan.
3. Run any affected integration or E2E commands needed for service-wiring rows.
4. Merge compact evidence into `phase.yaml`.
5. Merge every worker `mocks_or_fixtures` entry into `phase.yaml` `mock_fixture_ledger`.
6. Reconcile ledger entries against service-wiring rows:
   - mark pure test fixtures as `test-only`;
   - mark approved fixture-backed phase deliverables as `intentional-phase-boundary`;
   - mark replaced fakes as `converted` only after real runtime evidence exists;
   - require a concrete later phase/task for `deferred-with-conversion-task`;
   - keep unavailable real dependencies as `blocked` only when they match allowed escalation rules and blocker-resolver evidence proves they are outside agent-owned setup.
7. Dispatch a fix worker or plan-consistency update when a runtime fake lacks a valid disposition.
8. Review worker/reviewer `lesson_candidate` entries and promote only proven recurring fixes.
9. Record downstream plan updates only when reality changed.
10. Dispatch fix worker, reviewer, or blocker-resolver when needed.

Workers do not update `run.yaml` or `phase.yaml` directly unless explicitly assigned a narrow state-edit task.

## Context Discipline

The manifest is the normal scheduling surface. The full phase plan is the source of truth for the selected task only after the active frontier chooses that task.

Use targeted reads such as:

```sh
rg -n '^### Task 4:' docs/plans/<phase>.md
sed -n '<task-start>,<next-task-start-minus-one>p' docs/plans/<phase>.md
```

Avoid broad `sed` dumps, full `git diff` output, raw Codex session-log reads, and copying full plan sections into events or state. Use `--stat`, exact file lists, bounded line ranges, and artifact files.

## Mock/Fixture Ledger Ownership

The orchestrator is responsible for keeping the mock/fixture ledger accurate. Do not rely on reviewers or final QA to discover all fake usage.

Use the ledger to preserve useful temporary mocks while preventing fake completion:

- temporary fakes may be introduced during TDD or parallel work;
- every fake that affects runtime behavior, service wiring, or acceptance evidence must be tracked;
- service-wiring rows that require real integration cannot be marked covered by mock-only evidence;
- before phase acceptance, ensure the acceptance worker runs the mock/fixture audit scan from `qa-acceptance.md` and reconciles relevant matches;
- phase acceptance cannot pass with `unresolved`, untracked, or improperly deferred runtime fakes.

## Lesson Promotion

The orchestrator is the only default role that promotes lesson candidates into repo lessons.

Promote a candidate only when:

- the problem is likely to recur for future agents;
- the fix is proven by the current phase, tests, review, or artifact evidence;
- the rule is repo-specific enough to be useful;
- the lesson does not duplicate existing docs;
- the lesson contains no secrets, private tokens, or large logs.

When promoted, write the full lesson under `docs/lessons/`, add a concise pointer to root `AGENTS.md`, and record the lesson path in `phase.yaml`.
