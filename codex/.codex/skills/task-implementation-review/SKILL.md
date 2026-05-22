---
name: task-implementation-review
description: Use when code changes for a single implementation-plan task need to be reviewed against the local task specification before the supervisor advances the Linear issue.
---

# Task Implementation Review

Review one completed task implementation against its local implementation-plan task section. This is an agentic review step, not human smoke testing.

## Start

Announce: "I'm using the task-implementation-review skill to review the task implementation."

Inputs:

- implementation-plan path and task anchor or task heading;
- Linear issue key or sync key when available;
- diff range, branch, or worktree path;
- verification commands already run by the worker;
- optional sync ledger path.

If the task spec or diff cannot be found, ask for the missing path or issue key.

## Review Scope

Check:

- implementation satisfies the task goal and every required step;
- files changed match the task's ownership boundaries;
- tests cover the requested behavior;
- tests disclose whether they use mocks, fixtures, fake services, real local services, or real network/services;
- tests that cross service, network, database, queue, browser, CLI, filesystem, real-data, or end-to-end boundaries print enough stdout/stderr evidence to understand what passed without opening the test file;
- mocks are not left in production or dev runtime paths unless the plan has a later real-service conversion task;
- human-in-the-loop test requirements are preserved;
- no unrelated changes were included;
- focused verification evidence is credible.

Reviewer agents may run focused tests and inspect the working tree. Use `/usr/bin/git` when git is needed.

## Verification Reuse

Prefer reviewing the worker's exact verification evidence before rerunning slow commands.

- If the worker returned command output, stdout-rich test evidence, and the current diff still matches that evidence, inspect the relevant code/tests first and rerun only targeted commands needed to verify the review concern.
- Rerun a full suite only when the worker skipped required verification, output is missing or not credible, the diff changed after the worker ran it, the task touched shared behavior, or the task's required verification explicitly demands a reviewer rerun.
- When reusing evidence, say so in `Verification run` with the original command and mark any not-rerun command as `reused`.
- If an integration/e2e test crosses service, network, database, queue, browser, CLI, filesystem, real-data, or end-to-end boundaries but prints no useful observable facts, file a Medium finding even if the command passes.

## Findings

Classify findings:

- `High`: task is incomplete, wrong, unsafe, breaks contract, or leaves production/dev path mocked without required conversion.
- `Medium`: missing meaningful tests, important edge case missing, boundary mismatch, unclear integration risk, or integration/e2e tests that pass silently without useful observable stdout evidence.
- `Low`: cleanup, naming, small docs mismatch, or non-blocking improvement.

High and Medium findings are blocking by default. Low findings may be noted or deferred.

## Linear Update

Linear comments must stay compact. The detailed review output belongs in SQLite, a local review artifact, or the reviewer return payload, not in Linear.

When Linear is available, post at most one short status comment on the task issue. Do not include full findings, full command output, logs, diffs, or long explanations. Do not change issue status unless the supervisor explicitly delegated that action.

Use this shape:

```markdown
Agentic review: <approved | fix required | blocked>
Blocking findings: <count>
Details: `<state_db_run_id_or_review_artifact_path>`
```

If there are High/Medium findings, include only the short title of each blocking finding, capped at 3 bullets. Put full details in SQLite or the local artifact.

## Output

Return:

```markdown
Task implementation review complete.

Blocking: yes|no

Findings:
- <severity> - <issue> - <required fix or "note only">

Verification run:
- `<command>` - <passed/failed/skipped/reused> - <key evidence or reuse reason>

Recommendation:
- <approve for human review | fix required | blocked>
```
