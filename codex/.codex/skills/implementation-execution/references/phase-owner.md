# Phase Owner

The phase owner is the long-running orchestrator for one phase. It owns the phase branch/worktree, active frontier, worker dispatch, integration, verification, `phase.yaml`, and phase acceptance packet.

## Active Frontier

Build the frontier from:

- implementation-plan task dependencies;
- `phase.yaml` task statuses;
- shared-resource constraints from task `Execution` lines and the phase execution contract;
- active worker lanes;
- pending consistency updates that could affect future tasks.

Dispatch only substantial independent lanes. Keep small edits, glue code, integration, consistency updates, and acceptance packet ownership with the phase owner.

Use this selection order:

1. Exclude tasks already `done`, `blocked`, `deferred`, or assigned to an active lane.
2. Exclude tasks whose `Depends On` entries are not complete.
3. Exclude tasks affected by pending consistency updates.
4. Group remaining tasks by shared files, schemas, migrations, generated files, services, databases, queues, ports, devices, and external dependencies.
5. Prefer the smallest set of substantial non-overlapping lanes that can make progress.
6. Cap concurrent worker lanes to what the repo can safely isolate; default to one worker lane unless independence is clear.
7. Keep integration-heavy or context-heavy work with the phase owner.

## Worker Count

Decide worker count after reading the phase plan and state. Prefer a small number of lanes:

- Good lanes: isolated UI workflow, isolated service/API path, E2E harness setup, migration plus repository layer, focused review/fix lane.
- Bad lanes: tiny one-file edits, glue/integration work, unclear ownership, tasks requiring constant phase context, tasks touching the same schema/API/runtime resource as another active lane.

Do not spawn a worker just because a task exists.

## `/goal` Usage

Use `/goal` only after the phase owner has selected the next lane and is ready to dispatch the worker.

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
5. Review worker/reviewer `lesson_candidate` entries and promote only proven recurring fixes.
6. Record downstream plan updates only when reality changed.
7. Dispatch fix worker or reviewer when needed.

Workers do not update `run.yaml` or `phase.yaml` directly unless explicitly assigned a narrow state-edit task.

## Lesson Promotion

The phase owner is the only default role that promotes lesson candidates into repo lessons.

Promote a candidate only when:

- the problem is likely to recur for future agents;
- the fix is proven by the current phase, tests, review, or artifact evidence;
- the rule is repo-specific enough to be useful;
- the lesson does not duplicate existing docs;
- the lesson contains no secrets, private tokens, or large logs.

When promoted, write the full lesson under `docs/lessons/`, add a concise pointer to root `AGENTS.md`, and record the lesson path in `phase.yaml`.
