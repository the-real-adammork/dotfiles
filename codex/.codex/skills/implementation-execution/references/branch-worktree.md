# Branch And Worktree Strategy

Use branches and worktrees only where they reduce conflict risk or enable real parallelism. Avoid PR/MR per task by default.

## Default Shape

- The phase owner works on the phase branch, such as `impl/<phase-slug>`.
- The phase owner keeps glue, integration, small edits, state updates, consistency updates, and acceptance packet work on the phase branch.
- Workers use isolated task branches/worktrees only for substantial parallel lanes or risky work.

## When To Use Worker Worktrees

Create a worker branch/worktree when a lane:

- runs in parallel with another lane;
- touches many files;
- may take a long time;
- has meaningful merge/conflict risk;
- changes migrations, schemas, generated files, dependency files, or runtime resources;
- needs independent test/fix/review cycles.

Use the phase worktree directly only for small serial tasks owned by the phase owner.

## Worker Branch Naming

Prefer deterministic names:

```text
impl/<phase-slug>/<lane-slug>
```

Prefer deterministic worktree paths:

```text
.worktrees/<phase-slug>-<lane-slug>
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
