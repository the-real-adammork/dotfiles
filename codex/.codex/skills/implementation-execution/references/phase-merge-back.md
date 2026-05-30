# Phase Merge Back

Use this when the native phase-merge sub-agent handles `phase_completion` merge-back. The orchestrator merges workers into the phase branch. The phase-merge sub-agent merges or reconciles the completed phase branch back into the run base branch during fast transition preparation.

## Preconditions

Before merging:

1. Confirm the inbox requested `phase_completion`.
2. Confirm `phase.yaml` is `status: complete` and `acceptance.status: passed`.
3. Confirm the acceptance packet exists and references current commits/artifacts.
4. Confirm the phase-transition handoff/report exists and includes local setup instructions plus smoke-test expectations.
5. Confirm the phase worktree is clean or only contains explicitly expected state artifacts already committed on the phase branch.
6. Inspect the run base worktree for local/ad-hoc changes and classify them before merge-back. A dirty base worktree is allowed when the supervisor can preserve or reasonably reconcile local changes without overwriting suspected secrets/runtime data or making a critical product/data decision.
7. Confirm whether the base branch is an ancestor of the phase branch. If yes, prefer fast-forward. If no, use the merge reconciliation protocol instead of silently chaining branches or creating an unexplained merge.
8. Resolve and validate the accepted phase commit from the inbox or acceptance packet. It must be a full 40-character commit hash that exists as a commit object.
9. Confirm the phase branch contains the accepted phase commit.

## Default Merge Sequence

```sh
base_branch='<run.yaml branches.base>'
phase_branch='<phase.yaml branch>'
accepted_commit='<phase completion commit>'
artifact_dir='docs/qa/artifacts/<phase-slug>'
printf '%s\n' "$accepted_commit" | rg --quiet '^[0-9a-f]{40}$'
/usr/bin/git cat-file -e "$accepted_commit^{commit}"
/usr/bin/git switch "$base_branch"
mkdir -p "$artifact_dir"
/usr/bin/git status --porcelain=v1 -z > "$artifact_dir/base-worktree-status-before.z"
/usr/bin/git diff --name-only -z > "$artifact_dir/base-dirty-tracked-before.z"
/usr/bin/git ls-files --others --exclude-standard -z > "$artifact_dir/base-dirty-untracked-before.z"
/usr/bin/git diff --name-only -z "$base_branch..$accepted_commit" > "$artifact_dir/phase-changed-paths.z"
/usr/bin/git merge-base --is-ancestor "$base_branch" "$phase_branch" || echo "base_not_ancestor_reconciliation_required"
/usr/bin/git merge-base --is-ancestor "$accepted_commit" "$phase_branch"
/usr/bin/git merge --ff-only "$phase_branch"
/usr/bin/git rev-parse HEAD
```

If `git switch "$base_branch"` fails because local changes would be overwritten, use the merge reconciliation protocol below from the current base worktree; do not force checkout. Before running `git merge --ff-only`, compare dirty base paths to phase-changed paths. If dirty paths are non-overlapping and the base branch is an ancestor, proceed with the fast-forward; Git will preserve those local files. If paths overlap, the base branch diverged, or `git merge --ff-only` fails, attempt a supervised reconciliation instead of blocking by default.

After merging:

- run the lightweight post-merge verification needed to catch integration drift, at minimum the phase acceptance gate or the repo's standard smoke commands;
- verify the base branch now points at the accepted phase commit, or at a descendant that contains it when the phase branch includes final acceptance/state commits;
- record the merge commit and resulting base commit in `transitions/<phase>.yaml` before launching the next phase or any local verification process;
- return the updated base branch/head to the supervisor so it can update minimal `run.yaml` pointers before next-phase startup;
- leave completed-orchestrator teardown, next-phase orchestrator startup, phase-transition sub-agent spawn, local verification setup, and smoke-test report printing to the original supervisor after the merge sub-agent reports `ready_for_supervisor`.

If post-merge verification fails after reconciliation, mark the transition blocked and do not let the supervisor advance `run.yaml`. Stop with a supervisor escalation/handoff or restart a focused fix workflow. Do not silently rebase the phase branch, discard local work, or chain the next phase from the previous phase branch.

## Dirty Base Worktree Protocol

The run base worktree may contain ad-hoc human work, supervisor-owned lifecycle files, local verification artifacts, or runtime files when a phase completes. The supervisor must handle that state deliberately.

1. Capture a names-only status snapshot before merge-back:

```sh
/usr/bin/git status --porcelain=v1 -z > "docs/qa/artifacts/<phase>/base-worktree-status-before.z"
/usr/bin/git diff --name-only -z > "docs/qa/artifacts/<phase>/base-dirty-tracked-before.z"
/usr/bin/git ls-files --others --exclude-standard -z > "docs/qa/artifacts/<phase>/base-dirty-untracked-before.z"
/usr/bin/git diff --name-only -z "<base-commit>..<accepted-commit>" > "docs/qa/artifacts/<phase>/phase-changed-paths.z"
```

Do not dump full diffs by default. If a dirty or untracked path appears secret-bearing (`.env`, key material, credentials, tokens, private keys, runtime databases, uploaded bundles, extracted customer data), use `$secrets` before inspecting content and add a narrow `.gitignore` rule when needed.

2. Classify dirty paths:

- `supervisor-owned`: run state, inbox, watchdog, event, handoff, or QA artifact files created by the supervisor or merge/transition worker during transition.
- `local-verification`: dev-server logs, local smoke reports, generated local runtime data under ignored runtime paths.
- `human-ad-hoc`: anything else.
- `suspected-secret-or-runtime-data`: secret-bearing or customer/runtime data paths; do not open or print contents.

3. Compute path overlap between dirty base paths and paths changed by the accepted phase commit range. Treat exact path matches as potential conflicts. For directories or generated trees, treat a dirty path under a phase-changed directory as a potential conflict unless the repo's ownership rules make it clearly independent.

4. If dirty paths are non-overlapping and the base branch is an ancestor of the phase branch, merge back with `git merge --ff-only`. Do not stash local changes as the default preservation strategy, because stashes can hide secret-bearing files and make the workflow less auditable. Use stash only after explicit human approval and after `$secrets` classification when suspected secrets/runtime data are present.

5. If dirty paths overlap, the base branch diverged, or fast-forward fails, use the merge reconciliation protocol. The supervisor is expected to make reasonable autonomous merge decisions and only escalate critical mismatches.

6. After merge-back or reconciliation, rerun `git status --porcelain=v1 -z`, verify preserved/reconciled local changes are accounted for, and record compact events such as `base_worktree_local_changes_preserved` or `base_worktree_conflicts_resolved` with status artifact paths, path counts, and decision artifact paths. Start the next phase from the updated base commit, with a note when preserved ad-hoc changes remain in the base worktree.

## Merge Reconciliation Protocol

Use this when a clean fast-forward is not available because the base worktree has overlapping ad-hoc changes, local base commits, or Git reports merge conflicts.

1. Create an auditable safety point before changing the base worktree:

```sh
base_head="$(/usr/bin/git rev-parse HEAD^{commit})"
safety_branch="supervisor/<run-id>/<phase-slug>-base-before-reconcile-$(date -u +%Y%m%dT%H%M%SZ)"
/usr/bin/git branch "$safety_branch" "$base_head"
/usr/bin/git status --porcelain=v1 -z > "$artifact_dir/base-worktree-status-before-reconcile.z"
/usr/bin/git diff --binary > "$artifact_dir/base-worktree-tracked-before-reconcile.patch"
/usr/bin/git diff --binary --cached > "$artifact_dir/base-worktree-index-before-reconcile.patch"
```

For untracked non-secret files, record names and preserve them in place when possible. Do not copy, print, or commit suspected secrets, runtime databases, uploaded bundles, or extracted customer data. Use `$secrets` for any suspected secret/runtime path before deciding how to preserve it.

2. Attempt the least surprising Git operation:

- If the base branch is an ancestor of the phase branch and the only issue is dirty working-tree overlap, attempt `git merge --ff-only "$phase_branch"` first after confirming Git can preserve local edits.
- If the base branch has local commits or fast-forward is impossible, run `git merge --no-ff "$phase_branch"` from the base branch so both histories are represented.
- Do not rebase the accepted phase branch during transition handling.

3. Resolve conflicts using reasonableness:

- Prefer the accepted phase branch for completed phase behavior, tests, generated contracts, migrations, and acceptance-backed service wiring.
- Preserve base-worktree ad-hoc changes when they are additive, local verification/reporting artifacts, documentation clarifications, developer-only config, or do not contradict acceptance evidence.
- Combine both sides when changes are compatible, such as adjacent docs, additive config keys, expanded tests, or non-conflicting UI copy.
- For lockfiles and generated artifacts, regenerate with the repo's standard command instead of hand-editing conflict markers when practical.
- For formatting-only conflicts, choose the version consistent with repo tooling and run the formatter/test command.

4. Escalate only critical mismatches. Critical mismatches include:

- a required product, privacy, security, legal, or data retention decision with no clear source-of-truth;
- suspected secret/customer/runtime data that would need to be opened, copied, deleted, or committed to continue;
- destructive data migration or irreversible external side effect;
- conflict between two incompatible schema/migration histories where automated tests cannot establish the correct state;
- conflict that would invalidate phase acceptance evidence and cannot be repaired with a focused fix;
- merge result cannot pass required post-merge verification after one focused fix attempt.

5. Record autonomous decisions. For every medium/high-confidence conflict resolved without human input, write a compact decision log under:

```text
docs/qa/artifacts/<phase>/merge-reconciliation-decisions.md
```

Include:

- accepted phase commit;
- current base commit;
- safety branch;
- conflicted paths;
- decision per path;
- reason/source-of-truth, such as phase acceptance evidence, repo convention, generated-file command, or additive preservation;
- verification command proving the decision.

Low-risk mechanical decisions may be summarized by category. Critical escalations must list path names and the decision needed, but not file contents when secrets or private data might be involved.

6. Commit or preserve the reconciliation result according to the shape of the merge:

- If the merge created a merge commit, use a message such as `merge: integrate <phase-slug>`.
- If the merge was a fast-forward with preserved uncommitted local changes, leave those local changes uncommitted and record them in `transitions/<phase>.yaml`.
- If conflict resolution required edits after a fast-forward or merge, commit those edits on the base branch as supervisor reconciliation work, unless they are local verification artifacts that should remain uncommitted.

7. Run post-merge verification. If it fails, make one focused repair attempt when the failure is clearly caused by the reconciliation. Escalate if the fix would require a critical decision or broad reimplementation.

If the inbox or acceptance packet contains an abbreviated, malformed, or manually typed commit value, do not use it directly. Resolve it only when Git can unambiguously expand it and the resolved commit is contained in the phase branch:

```sh
resolved_commit="$(/usr/bin/git rev-parse --verify "${accepted_commit}^{commit}")"
/usr/bin/git merge-base --is-ancestor "$resolved_commit" "$phase_branch"
```

Patch the state file that had the malformed value to the full 40-character hash, commit that state repair on the phase branch, and then continue transition validation from the repaired state. If resolution fails, is ambiguous, or points outside the phase branch, stop with `restart_needed` or a supervisor escalation.
