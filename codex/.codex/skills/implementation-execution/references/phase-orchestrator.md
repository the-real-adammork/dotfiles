# Phase Orchestrator

The phase orchestrator is a separate top-level Codex CLI process for one phase, normally launched by the supervisor in a new pane in the current tmux window. It owns the phase branch/worktree, active frontier, worker dispatch, worker communication, integration, verification, `phase.yaml`, acceptance packet, and compact supervisor inbox updates.

Because the orchestrator is a top-level Codex process, it can spawn and communicate with worker agents directly. It should write only lifecycle-level messages to the supervisor inbox; detailed worker state stays in `phase.yaml`, worker result YAML, acceptance packets, and QA artifacts.

The orchestrator is launched with `--dangerously-bypass-approvals-and-sandbox` so it can own worker approvals and phase execution without blocking on Codex edit prompts. Do not ask the supervisor to approve worker edits. Human-only blockers must be written to the supervisor inbox as workflow escalations.

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

Dispatch workers for substantial bounded implementation lanes, including serial lanes where only one task can safely run right now. Keep small edits, glue code, integration, consistency updates, state updates, and acceptance packet ownership with the orchestrator.

Use this selection order:

1. Exclude tasks already `done`, `blocked`, `deferred`, or assigned to an active lane.
2. Exclude tasks whose `Depends On` entries are not complete.
3. Exclude tasks affected by pending consistency updates.
4. Group remaining tasks by shared files, schemas, migrations, generated files, services, databases, queues, ports, devices, and external dependencies.
5. Prefer the smallest set of substantial non-overlapping worker lanes that can make progress.
6. Cap concurrent worker lanes to what the repo can safely isolate; default to one worker lane unless independence is clear.
7. Dispatch at least one worker for substantial code/test/runtime implementation, even when the active frontier is serial.
8. Keep integration-heavy decisions, context-heavy orchestration, state updates, and tiny glue edits with the orchestrator.

## Worker Count

Decide worker count after reading the manifest and state. Read the selected task section from the phase plan only after the active frontier chooses a lane. Prefer a small number of lanes, but do not collapse substantial implementation into the orchestrator merely because only one lane is currently unblocked.

- Good lanes: isolated UI workflow, isolated service/API path, E2E harness setup, migration plus repository layer, focused review/fix lane.
- Good serial worker lanes: foundational scaffold, contract/test harness, first persistence adapter, first E2E harness, or any task likely to consume enough context that preserving orchestrator headroom matters.
- Bad lanes: tiny one-file edits, state file edits, acceptance packet edits, glue/integration decisions, unclear ownership, tasks requiring constant phase context, tasks touching the same schema/API/runtime resource as another active lane.

Use zero workers only when the next work is genuinely small orchestration/glue/state work. Otherwise spawn one worker for serial implementation, and more workers only when independence and resource isolation are clear.

## `/goal` Usage

Use `/goal` only after the orchestrator has selected the next lane and is ready to dispatch the worker.

Every worker goal must include:

- run id;
- phase plan path;
- execution manifest path;
- task heading or lane scope;
- selected task section from the phase plan, not the whole plan;
- `run.yaml`, `phase.yaml`, and worker result YAML path;
- branch/worktree and base commit;
- allowed files or directories;
- service-wiring rows covered;
- required commands and artifact directory;
- explicit instruction not to update `run.yaml` or `phase.yaml`;
- return contract.

Record each worker dispatch in `phase.yaml` and the worker result YAML path. Do not send worker dispatch details to the supervisor inbox unless the supervisor must handle a process failure.

Append compact dispatch and result events to `events/orchestrator-<phase>.jsonl`. Save full command output to artifacts and reference the artifact path in state/results/events.

```yaml
active_lanes:
  - lane: "<lane-slug>"
    task: "Task N"
    status: "test_proposed"
    worker: "<worker-id>"
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
Use execution manifest: <manifest-path>.
Use selected task context: <task heading/section>.
Use worker result path: <path>.
Do not update run.yaml or phase.yaml.
Return test files changed, commands run, expected failure, requirement mapping, service-wiring rows covered, and blockers.
```

Implementation goal shape:

```text
Goal: Implement <Task/Lane> until the approved tests pass. Do not broaden scope.
Use execution manifest: <manifest-path>.
Use selected task context: <task heading/section>.
Use worker result path: <path>.
Do not update run.yaml or phase.yaml.
Return changed files, commands run, evidence, service-wiring rows covered, residual risks, and task completion result YAML.
```

Prefer resuming the same worker after test approval when context is still healthy. Use a fresh implementation worker when context is bloated, the task is risky, or the test proposal result is enough to hand off cleanly.

## Supervisor Inbox

Write a compact lifecycle update to `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml` at startup, periodically while running, when blocked, when requesting graceful exit, and when phase acceptance completes.

The inbox is not the phase database. Do not put worker details, full command output, review text, or detailed active-lane state there.

Set:

- `orchestrator_status: running` with fresh heartbeat while active.
- `startup.acknowledged: true`, expected manifest path, pane id, and best-effort Codex session id/path at startup.
- `request.type: escalation` only for allowed escalations the supervisor must surface or preserve.
- `request.type: restart_needed` when the orchestrator cannot continue safely.
- `request.type: phase_completion` only after phase acceptance passed and the acceptance packet exists.
- `request.type: graceful_exit` when the supervisor should close the pane after state is safely written.

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
   - keep unavailable real dependencies as `blocked` only when they match allowed escalation rules.
7. Dispatch a fix worker or plan-consistency update when a runtime fake lacks a valid disposition.
8. Review worker/reviewer `lesson_candidate` entries and promote only proven recurring fixes.
9. Record downstream plan updates only when reality changed.
10. Dispatch fix worker or reviewer when needed.

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
- before phase acceptance, run the mock/fixture audit scan from `qa-acceptance.md` and reconcile relevant matches;
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
