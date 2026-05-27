# Branch And Worktree Strategy

Use branches and worktrees to keep long-running phase execution resumable and isolated. Avoid PR/MR per task by default.

## Default Shape

- Every active phase gets a phase branch and phase worktree by default, such as branch `impl/<phase-slug>` and worktree `.worktrees/impl-<phase-slug>`.
- The phase owner works from the phase worktree and records the branch/worktree in `phase.yaml`.
- The phase owner keeps glue, integration, small edits, state updates, consistency updates, and acceptance packet work on the phase branch.
- Workers use isolated task branches/worktrees for substantial implementation lanes, including serial lanes. This preserves phase-owner context and keeps worker changes reviewable before merge.
- Skip a phase worktree only when repo tooling makes worktrees impossible or unsafe; record the fallback reason in `phase.yaml` and the handoff.

## When To Use Worker Worktrees

Create a worker branch/worktree when a lane:

- changes substantial runtime code, tests, service wiring, or E2E automation;
- runs in parallel with another lane;
- touches many files;
- may take a long time;
- has meaningful merge/conflict risk;
- changes migrations, schemas, generated files, dependency files, or runtime resources;
- needs independent test/fix/review cycles.

Use the phase worktree directly only for tiny phase-owner glue, state updates, acceptance packet edits, plan consistency edits, or emergency fixes where creating a worker worktree would cost more than the change.

## Worker Branch Naming

Prefer deterministic names:

```text
impl/<phase-slug>/<lane-slug>
```

Prefer deterministic worktree paths:

```text
.worktrees/impl-<phase-slug>-<lane-slug>
```

Record branch, worktree, base commit, and worker id in `phase.yaml` before dispatching the worker.

## Merge Back

The phase owner integrates worker results:

1. Verify worker result YAML.
2. Verify the worker worktree is clean except intended changes.
3. Run the worker-reported commands when practical.
4. Run the task/lane integration checkpoint from the phase plan.
5. Merge or apply the worker branch into the phase branch.
6. Resolve conflicts only in the phase-owner context.
7. Commit the integrated result on the phase branch.
8. Update `phase.yaml` with commit, verification summary, artifacts, and service-wiring coverage.

Workers do not merge their own branches into the phase branch.
