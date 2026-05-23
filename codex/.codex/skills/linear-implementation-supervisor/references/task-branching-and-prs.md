# Task Branching And PR Targeting

Each task must use a dedicated task branch based on the worktree and branch it starts from. This keeps task PR/MR links scoped to the task's own diff instead of showing all changes relative to `main` or the repository default branch.

## Before Dispatch

Before dispatching the task worker, the supervisor must:

1. Resolve the task base worktree as the active plan worktree unless an explicit task base worktree is recorded in SQLite.
2. Resolve the task base branch as the active plan branch checked out in that worktree.
3. Record the task base commit with `/usr/bin/git -C <base worktree> rev-parse HEAD`.
4. Create the task branch from that exact base commit using `task_branch_template`.
5. Record `task_branch`, `task_base_worktree`, `task_base_branch`, `task_base_commit`, and `pr_target_branch = task_base_branch` in SQLite before dispatch.

The task branch may live in the plan worktree if only one task is active, or in a separate task worktree under `worktree_dir` if the supervisor needs to keep the plan branch checked out. In both cases, worker, fix-worker, reviewer, commit, push, and PR/MR creation operate on the task branch, not directly on the plan branch.

## PR/MR Creation

When creating or updating the PR/MR:

- the source/head branch is the task branch;
- the target/base branch is the recorded `pr_target_branch`;
- the target/base branch must be the branch for the worktree the task branch was based on, not `main`, `master`, or the remote default branch unless that branch is the recorded base;
- custom `pr_create_command` templates must receive both source/head and target/base values, and the supervisor must verify the resulting PR/MR targets the recorded base branch;
- default CLI creation must pass the provider-specific target/base option, such as `glab mr create --source-branch <task branch> --target-branch <pr_target_branch>` for GitLab.

After review passes and the supervisor commits the task, push the task branch and create or update a remote pull/merge request:

1. Use `remote_name` from config, default `origin`.
2. Use `pr_provider`, default `gitlab`.
3. Use the recorded `pr_target_branch` as the PR/MR target/base branch.
4. If `pr_create_command` is configured, run it from the task worktree after substituting known source branch, target branch, title, and body values when needed.
5. Otherwise infer the repository host from `/usr/bin/git remote get-url <remote_name>` and use an available project CLI such as `glab` for GitLab when installed.
6. Verify the created or updated PR/MR targets the recorded `pr_target_branch`.
7. If no PR/MR can be created because authentication, remote access, or tooling is missing, set the Linear issue to `Blocked` when `pr_link_required_for_human_review = true`; otherwise write the blocker and exact manual create command in the review packet.

If an existing PR/MR targets the wrong branch, retarget it before human review when the provider supports that. If it cannot be retargeted, close or supersede it with a PR/MR targeting the recorded base branch. Do not move the task to human review with a PR/MR whose target branch would show unrelated changes.

## Merge Back After Approval

After human approval, merge the task branch back into the recorded base worktree/branch before updating task-consistency docs or starting the next dependent task.

1. Verify the base worktree is clean.
2. Verify the base worktree is checked out on `task_base_branch`.
3. Verify the base branch still contains `task_base_commit` in its history.
4. If the base branch moved since the task branch was created, merge or rebase only when the diff still corresponds to the approved PR/MR; otherwise block and ask for review guidance.
5. Record the merge-back commit SHA, or the fast-forward SHA, in SQLite.
