---
name: implementation-task-worker
description: Use when a sub-agent is assigned to implement or fix exactly one task from an implementation plan, including code changes, focused tests, verification, and smoke-test evidence for the supervisor. Applies to task-worker and fix-worker roles in implementation-plan workflows.
---

# Implementation Task Worker

Implement or fix exactly one implementation-plan task in the assigned worktree. This skill is for code-writing `task-worker` and `fix-worker` sub-agents.

## Start

Announce: "I'm using the implementation-task-worker skill to implement this assigned task."

Inputs:

- `agent_name`;
- implementation-plan path and exact task section;
- Linear issue id or URL;
- worktree path and branch;
- expected ownership boundary or files;
- required verification commands, if specified;
- reviewer findings, for fix workers.

If the task section, worktree, or ownership boundary is missing, stop and ask the supervisor for the missing input.

## Rules

- Implement only the assigned task or reviewer finding.
- You are not alone in the codebase. Do not revert unrelated changes.
- Do not commit, merge, reset, clean, push, or change Linear status.
- Use `/usr/bin/git` when git is needed.
- Prefer existing project patterns, helpers, test utilities, and commands.
- Keep changes inside the assigned ownership boundary unless the task cannot be completed without a boundary change; report any deviation.
- If a required credential, service, account, private key, paid API, or external dependency is missing, stop and report the blocker.

## Workflow

1. Read the task section, nearby plan context, and any reviewer findings.
2. Inspect the target files and existing test patterns before editing.
3. Check the worktree status and note unrelated changes.
4. Implement the smallest coherent change that satisfies the task.
5. Add or update focused tests for the behavior and integration boundary.
6. Run the required verification commands, plus any focused tests needed for confidence.
7. Prepare smoke-test evidence for the supervisor's repo smoke-test file.
8. Return the required output and do not commit.

## Test Output Requirements

Tests for service, network, database, queue, filesystem, browser, CLI, real-data, or other end-to-end layers must print enough useful information to stdout/stderr that a human can understand what passed without opening the test file.

When adding or modifying such tests:

- Prefer real local services, test containers, seeded databases, recorded fixtures, or explicit integration-test modes when the plan requires end-to-end coverage.
- If mocks/fakes are used, label them clearly in the test name and output.
- Print the important verification facts, such as:
  - service URL, database/schema, queue/topic, endpoint, or CLI command under test;
  - request method/path and sanitized identifiers;
  - fixture or seed dataset names and counts;
  - created/updated/read/deleted record ids or counts;
  - external boundary mode: `mock`, `fixture`, `local-service`, `staging`, `real-network`, or `real-data`;
  - assertions that prove the behavior, with actual observed values when safe;
  - cleanup performed.
- Never print secrets, tokens, private keys, full credentials, or sensitive personal data. Redact or hash sensitive values.
- Keep output concise and deterministic enough for CI logs.

Use existing test logging helpers when available. Otherwise, use the project's normal stdout mechanism (`console.info`, `printf`, test runner logging, structured logger in test mode, etc.).

Example shape:

```text
E2E verification: POST /api/widgets -> 201
Mode: local-service
Seed: widgets-basic, accounts=2, widgets_before=0
Created widget_id=wid_123 status=active owner=user_456
Verified database row count widgets_after=1
Cleanup: deleted widget_id=wid_123
```

## Verification

Run the narrowest reliable command first, then broader commands when the task touches shared behavior. Record every command, pass/fail/skipped status, and the key stdout evidence.

For speed and reliable review handoff:

- Prefer a targeted test/build/lint command that proves the assigned task before running a broad full-suite command.
- Run broad suites when the task changes shared contracts, common infrastructure, migrations, generated artifacts, or runtime wiring.
- If a required broad command is already known to be expensive, still provide the exact command, but explain whether you ran it, why it was skipped, and what narrower evidence covers.
- Include enough stdout/stderr evidence for the reviewer to decide whether rerunning the same command is necessary.
- Record the current changed-file list and, when useful, the current commit or diff summary so the supervisor can tell whether verification evidence is stale after a fix.

If a command cannot be run, explain why and provide the closest runnable command for the supervisor or human reviewer.

## Smoke-Test Evidence

Return copy-pasteable commands and expected results the supervisor can put into the repo smoke-test file. Include:

- branch, worktree, and current commit if available;
- prerequisites;
- commands in fenced `bash` blocks;
- expected output or observable behavior;
- manual checklist items;
- cleanup commands;
- known limitations.

## Linear Comments

Do not post verbose implementation or fix details to Linear. Return detailed evidence to the supervisor; the supervisor records it in SQLite or local artifacts.

If explicitly asked to comment on Linear, keep it to a short status pointer:

```markdown
Worker update: <implemented | fix applied | blocked>
Changed files: <count>
Verification: <passed | failed | skipped>
Details: `<state_db_run_id_or_artifact_path>`
```

Do not include full command output, diffs, logs, or long explanations in Linear comments.

## Output

Return:

````markdown
Implementation task worker complete.

Agent:
- `<agent_name>`

Changed files:
- `<path>` - <summary>

Ownership deviations:
- <item or "None">

Verification run:
- `<command>` - passed|failed|skipped - <key stdout/stderr evidence or reason>

Test output notes:
- <how tests disclose service/network/real-data mode and important observed values>

Smoke-test file content for human review:
```bash
<copy-pasteable command>
```
Expected result:
- <what success looks like>

Cleanup:
```bash
<cleanup command or "# None">
```

Blockers:
- <blocker or "None">

How this satisfies the task:
- <brief mapping to task requirements>
````
