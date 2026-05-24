# Human Review

## Review Packet

Before moving any Linear issue to `status_human_review`, write a human-review packet to a repo file. Default path:

```text
docs/linear/reviews/<plan-slug>/<issue-id>-<task-slug>.md
```

If `.codex/linear.toml` sets `human_review_dir`, use that directory instead. If only legacy `smoke_test_dir` is configured, use it as a compatibility fallback.

The human-review packet must include:

- task summary and exact task branch, task worktree, base branch, base commit, and task commit under review;
- PR/MR URL and Linear issue URL;
- implementation-plan path, task anchor, state DB path, run id, and plan id;
- automated tests added or updated, grouped as unit, integration, and end-to-end;
- exact verification commands the agent ran, with concise stdout-rich evidence and pass/fail/skipped status;
- required real dependencies, how they were provisioned or why the task was blocked before review;
- why those tests prove the task is complete, mapped back to the task requirements;
- fixture/mock/fake disclosure, including which tests use them, what real boundary they stand in for, and the future task or plan that replaces them with real service/data coverage;
- CI/PR checks expected to run on the PR/MR, if known;
- human review checklist focused on what to inspect in the PR: production code paths, test assertions, boundary-mode disclosures, missing real-service gaps, and whether the PR solves the real problem;
- known limitations, residual risk, or tests that cannot be run by the agent, with the reason.

The packet may include optional copy-pasteable commands for a human who wants to rerun checks locally, but local command execution is no longer the primary human-review mechanism. The primary review surface is the PR/MR plus the packet's test-proof explanation.

## Linear Comment

After writing the file, post only a compact Linear comment:

```markdown
Ready for human review.

PR/MR: <url>
Review packet: `<human-review-packet-path>`
Branch: `<branch>`
Target: `<pr_target_branch>`
Commit: `<sha>`

When the PR and review packet look correct, move this issue to `<status_done>`.
```

Do not put full test evidence, command output, PR body, or manual checklist in Linear.

## Wait

The default human-review mode is event-driven. When the supervisor has moved a task to `status_human_review`, it records that task's waiting state and tells the user the exact Linear issue, PR/MR URL, and human-review packet. The supervisor may continue other already-active tasks and dispatch other dependency-unblocked, non-overlapping tasks. It stops active waiting only when no other safe work remains until the user resumes, Linear already shows approval, or the user sends `human review approved <issue id>`.

Only use active polling when `.codex/linear.toml` explicitly sets `human_review_mode = "polling"`. In polling mode, treat normal human-review polling as active supervisor work until `human_review_timeout_minutes` elapses.

Before accepting `status_human_review` as a valid waiting state, verify that the repo human-review packet exists, the PR/MR exists and targets the recorded task base branch when required, and the compact Linear comment links to both.

Human approval is communicated by moving the Linear issue to `status_done`. A separate approval comment is not required.

The user may also notify the supervisor directly in chat:

```text
human review approved <issue id>
```

When this happens:

1. Verify the issue id matches the active task or a task currently in `status_human_review`.
2. Fetch the Linear issue and confirm its status is `status_done`.
3. Read the active plan/task state from SQLite.
4. Continue the supervisor-owned task-completion workflow immediately.
5. Update SQLite with the direct human-approval signal and verified Linear status.

If the direct signal is received but Linear is not `status_done`, tell the user the issue is not marked done yet and keep the task in its current human-review wait. In polling mode, continue the polling loop.
