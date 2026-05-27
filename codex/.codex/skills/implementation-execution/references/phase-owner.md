# Phase Owner

The phase owner is the long-running orchestrator for one phase. It owns the phase branch/worktree, active frontier, worker dispatch requests, integration, verification, `phase.yaml`, and phase acceptance packet.

The phase owner should normally be a spawned orchestrator agent when agent dispatch is available. In runtimes where sub-agents cannot spawn sub-agents, the phase owner does not directly spawn workers. It prepares worker dispatch requests for the supervisor, including worker goal, branch/worktree, result YAML path, allowed files, service-wiring rows, commands, and artifact paths. The supervisor performs the actual spawn and routes worker results back to the phase-owner integration flow.

## Active Frontier

Build the frontier from:

- implementation-plan task dependencies;
- `phase.yaml` task statuses;
- shared-resource constraints from task `Execution` lines and the phase execution contract;
- active worker lanes;
- pending consistency updates that could affect future tasks.

Request workers for substantial bounded implementation lanes, including serial lanes where only one task can safely run right now. Keep small edits, glue code, integration, consistency updates, state updates, and acceptance packet ownership with the phase owner.

Use this selection order:

1. Exclude tasks already `done`, `blocked`, `deferred`, or assigned to an active lane.
2. Exclude tasks whose `Depends On` entries are not complete.
3. Exclude tasks affected by pending consistency updates.
4. Group remaining tasks by shared files, schemas, migrations, generated files, services, databases, queues, ports, devices, and external dependencies.
5. Prefer the smallest set of substantial non-overlapping worker lanes that can make progress.
6. Cap concurrent worker lanes to what the repo can safely isolate; default to one worker lane unless independence is clear.
7. Request at least one worker for substantial code/test/runtime implementation, even when the active frontier is serial.
8. Keep integration-heavy decisions, context-heavy orchestration, state updates, and tiny glue edits with the phase owner.

## Worker Count

Decide worker count after reading the phase plan and state. Prefer a small number of lanes, but do not collapse substantial implementation into the phase owner merely because only one lane is currently unblocked.

- Good lanes: isolated UI workflow, isolated service/API path, E2E harness setup, migration plus repository layer, focused review/fix lane.
- Good serial worker lanes: foundational scaffold, contract/test harness, first persistence adapter, first E2E harness, or any task likely to consume enough context that preserving phase-owner headroom matters.
- Bad lanes: tiny one-file edits, state file edits, acceptance packet edits, glue/integration decisions, unclear ownership, tasks requiring constant phase context, tasks touching the same schema/API/runtime resource as another active lane.

Use zero workers only when the next work is genuinely small orchestration/glue/state work. Otherwise request one worker for serial implementation, and more workers only when independence and resource isolation are clear.

## `/goal` Usage

Use `/goal` only after the phase owner has selected the next lane and is ready to ask the supervisor to dispatch the worker.

Every worker goal must include:

- run id;
- phase plan path;
- task heading or lane scope;
- `run.yaml`, `phase.yaml`, and worker result YAML path;
- branch/worktree and base commit;
- allowed files or directories;
- service-wiring rows covered;
- required commands and artifact directory;
- explicit instruction not to update `run.yaml` or `phase.yaml`;
- return contract.

Return each worker dispatch request to the supervisor in compact form:

```yaml
dispatch_request:
  lane: "<lane-slug>"
  task: "Task N"
  worker_result: "docs/implementation-runs/<run-id>/workers/<lane>-<timestamp>.yaml"
  branch: "impl/<phase>/<lane>"
  worktree: ".worktrees/impl-<phase>-<lane>"
  goal: "<test-only or implementation goal>"
  allowed_paths:
    - "src/..."
  service_wiring_rows:
    - "<row>"
  commands:
    - "<focused command>"
```

For behavior tasks, use two goals:

1. Test-only goal before implementation.
2. Implementation goal after agentic test approval.

Test-only goal shape:

```text
Goal: Write failing tests for <Task/Lane> only. Do not implement production code.
Use worker result path: <path>.
Do not update run.yaml or phase.yaml.
Return test files changed, commands run, expected failure, requirement mapping, service-wiring rows covered, and blockers.
```

Implementation goal shape:

```text
Goal: Implement <Task/Lane> until the approved tests pass. Do not broaden scope.
Use worker result path: <path>.
Do not update run.yaml or phase.yaml.
Return changed files, commands run, evidence, service-wiring rows covered, residual risks, and task completion result YAML.
```

Prefer resuming the same worker after test approval when context is still healthy. Use a fresh implementation worker when context is bloated, the task is risky, or the test proposal result is enough to hand off cleanly.

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

## Mock/Fixture Ledger Ownership

The phase owner is responsible for keeping the mock/fixture ledger accurate. Do not rely on reviewers or final QA to discover all fake usage.

Use the ledger to preserve useful temporary mocks while preventing fake completion:

- temporary fakes may be introduced during TDD or parallel work;
- every fake that affects runtime behavior, service wiring, or acceptance evidence must be tracked;
- service-wiring rows that require real integration cannot be marked covered by mock-only evidence;
- before phase acceptance, run the mock/fixture audit scan from `qa-acceptance.md` and reconcile relevant matches;
- phase acceptance cannot pass with `unresolved`, untracked, or improperly deferred runtime fakes.

## Lesson Promotion

The phase owner is the only default role that promotes lesson candidates into repo lessons.

Promote a candidate only when:

- the problem is likely to recur for future agents;
- the fix is proven by the current phase, tests, review, or artifact evidence;
- the rule is repo-specific enough to be useful;
- the lesson does not duplicate existing docs;
- the lesson contains no secrets, private tokens, or large logs.

When promoted, write the full lesson under `docs/lessons/`, add a concise pointer to root `AGENTS.md`, and record the lesson path in `phase.yaml`.
