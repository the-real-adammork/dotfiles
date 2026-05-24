# Plan Branch Merge

The supervisor owns merging completed implementation-plan branches, but delegates the mechanical merge to a dedicated native sub-agent. Task workers, reviewers, and fix workers must not merge plan branches.

After each plan completes:

1. Verify SQLite marks the plan `complete` and records the plan worktree path, branch name, commit list, `state_db`, `run_id`, and `plan_id`.
2. Verify the plan worktree is clean with `/usr/bin/git -C <plan worktree> status --short`.
3. Resolve the merge target:
   - use `merge_target_worktree` when configured;
   - otherwise use the original source or main worktree for the run;
   - use `merge_target_branch` when configured;
   - otherwise use the source branch recorded for the run.
4. Dispatch one `merge-worker` sub-agent with `agent_name` in the format `merge-worker: <plan-slug> -> <target branch>`.
5. Record the stable name and returned host agent id/nickname in `Agent Directory`.
6. Wait for the merge-worker result before running consistency updates or starting the next plan.
7. If the merge succeeds, record the merge commit SHA in SQLite and update the plan row before running cross-plan consistency.
8. If the merge conflicts or the target worktree is dirty, stop before starting the next plan. Update SQLite with `status: blocked`, the conflicting files or dirty paths, and a `restart_action` that resumes merge resolution. Do not ask task workers to perform the merge or conflict resolution unless the user explicitly delegates that work.

Use this merge-worker prompt shape:

```text
agent_name: merge-worker: <plan-slug> -> <target branch>

You are not alone in the codebase. Do not revert unrelated changes.

Merge one completed implementation-plan branch into the target worktree/branch.

Plan:
<implementation-plan path>

Plan worktree:
<plan worktree path>

Plan branch:
<plan branch>

Target worktree:
<target worktree path>

Target branch:
<target branch>

Required checks:
1. Verify the plan worktree is clean.
2. Verify the target worktree exists, is on the target branch, and is clean.
3. Merge the completed plan branch into the target worktree with `/usr/bin/git`, preserving the plan branch commits. Prefer a normal merge commit when the repository allows it; do not squash unless explicitly instructed.
4. If the merge conflicts, stop immediately after recording conflicted files. Do not resolve conflicts unless explicitly instructed.

Return only: merge status, merge commit SHA if successful, target worktree status, conflicted files or dirty paths if blocked, commands run, and blockers. Do not continue into consistency updates. Do not push.
```

When `merge_completed_plan_branches = false`, skip the merge step only if the user or repo config explicitly disables it, and record that skipped merge in SQLite and final output.
