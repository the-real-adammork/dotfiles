# Branch And Worktree Strategy

Use branches and worktrees to keep long-running phase execution resumable and isolated. Avoid PR/MR per task by default.

## Default Shape

- Every active phase gets a phase branch and phase worktree by default, such as branch `impl/<phase-slug>` and worktree `.worktrees/impl-<phase-slug>`.
- The orchestrator works from the phase worktree and records the branch/worktree in `phase.yaml`.
- The orchestrator keeps glue, integration, small edits, state updates, consistency updates, and acceptance packet work on the phase branch.
- Workers use isolated task branches/worktrees for substantial implementation lanes, including serial lanes. This preserves orchestrator context and keeps worker changes reviewable before merge.
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

Use the phase worktree directly only for tiny orchestrator glue, state updates, acceptance packet edits, plan consistency edits, or emergency fixes where creating a worker worktree would cost more than the change.

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

## Worker Merge Back

The orchestrator integrates worker results:

1. Verify worker result YAML.
2. Verify the worker worktree is clean except intended changes.
3. Run the worker-reported commands when practical.
4. Run the task/lane integration checkpoint from the phase plan.
5. Merge or apply the worker branch into the phase branch.
6. Resolve conflicts only in the orchestrator context.
7. Commit the integrated result on the phase branch.
8. Update `phase.yaml` with commit, verification summary, artifacts, and service-wiring coverage.

Workers do not merge their own branches into the phase branch.

## Phase Merge Back

The supervisor, not the orchestrator, merges the completed phase branch back into the run base branch after phase acceptance passes.

- The orchestrator stops at accepted phase state: all workers merged into the phase branch, acceptance packet written, `phase.yaml` complete, and supervisor inbox requesting `phase_completion`.
- The supervisor verifies the transition gate, classifies any dirty/ad-hoc changes in the run base worktree, and fast-forwards `impl/<phase-slug>` into the run base branch recorded in `run.yaml` when possible.
- If fast-forward is not possible because of overlapping ad-hoc changes, local base commits, or Git conflicts, the supervisor attempts a reasoned merge reconciliation from the base worktree and records the decisions it made.
- The next phase starts from the updated base branch after that merge, so phases build on each other in git history.
- Do not advance `run.yaml.current_phase` before the phase branch is merged back and post-merge verification passes.
- If the run base branch is not an ancestor of the completed phase branch, use the supervisor merge reconciliation protocol. Stop only when the divergence represents a critical mismatch that cannot be resolved reasonably; never silently chain the next phase from the phase branch.
- Escalate only critical merge mismatches: unresolved product/security/privacy/data decisions, suspected secrets/runtime data that must be opened or moved, incompatible schema/migration histories, acceptance-invalidating conflicts, or verification failures that cannot be fixed with a focused reconciliation. Non-critical conflicts should be resolved autonomously with a compact decision log.
