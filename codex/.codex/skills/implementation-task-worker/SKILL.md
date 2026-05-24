---
name: implementation-task-worker
description: Use when a sub-agent is assigned to implement or fix exactly one task from an implementation plan, including code changes, focused automated tests, verification, and human-review evidence for the supervisor. Applies to task-worker and fix-worker roles in implementation-plan workflows.
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
- Required real services, real databases, real network paths, real-data paths, and required integrations are mandatory verification gates. Do not label them optional or move them into human smoke-test notes.
- If a required credential, service, account, private key, paid API, or external dependency is missing, first try safe agent-owned provisioning with existing repo/tooling. If it still requires human action or steering, stop and report the blocker.

## Workflow

1. Read the task section, nearby plan context, and any reviewer findings.
2. Inspect the target files and existing test patterns before editing.
3. Check the worktree status and note unrelated changes.
4. Identify required real dependencies from the task, plan, requirements, code path, and test mode disclosure.
5. Provision required dependencies when possible with safe local or authenticated tooling: containers, local services, emulators, seeded databases, migrations, test tenants, queues, topics, buckets, schemas, or dev/staging resources.
6. If a required dependency cannot be provisioned without human credentials, account access, paid setup, approval, or steering, stop before implementing around it and return a blocker.
7. Implement the smallest coherent change that satisfies the task.
8. Add or update focused automated tests for the behavior and integration boundary.
9. Run the required verification commands, plus any focused tests needed for confidence.
10. Prepare test-proof evidence for the supervisor's repo human-review packet.
11. Return the required output and do not commit.

## Automated Test Requirements

Every implementation task should add or update automated tests unless the task is documentation-only or the existing test suite already covers the exact changed behavior. Choose the level that matches the change:

- unit tests for isolated logic, validation, transformations, and edge cases;
- integration tests for database, filesystem, service wiring, queues, CLIs, or internal API boundaries;
- end-to-end tests for user-visible workflows, cross-service behavior, or real-data paths.

Do not rely on manual smoke testing as the main proof that the task is complete. If automated coverage cannot be added, explain why, provide the closest executable check, and flag the gap for the reviewer and supervisor.

When the task requires a real service, real database, real network/API call, real-data path, or service integration, that real dependency is mandatory for task verification. Do not mark it optional. If you cannot satisfy it yourself, return a blocker with the exact human action needed so the supervisor can assign the Linear issue to the admin.

Return a short proof statement that maps each important task requirement to the test or verification command that covers it.

## Test Output Requirements

Tests for service, network, database, queue, filesystem, browser, CLI, real-data, or other end-to-end layers must print enough useful information to stdout/stderr that a human can understand what passed without opening the test file.

When adding or modifying such tests:

- Prefer real local services, test containers, seeded databases, recorded fixtures, or explicit integration-test modes when the plan requires end-to-end coverage.
- For required real integrations, attempt real local/dev/staging provisioning before using fixtures, recordings, mocks, or fakes.
- If mocks/fakes are used, label them clearly in the test name and output.
- If fixtures, recordings, mocks, or fakes are used, identify what real boundary they replace and name the later implementation-plan task that converts the boundary to a real service/data path or adds a larger real end-to-end test. If no later task exists, state that explicitly. If the current task requires the real boundary, stop and report a blocker instead of treating the fake path as sufficient.
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

## Human-Review Evidence

Return evidence the supervisor can put into the repo human-review packet. Include:

- branch, worktree, and current commit if available;
- required real dependencies and how they were provisioned;
- automated tests added or updated, grouped as unit, integration, and end-to-end;
- commands run and concise observed output;
- why the tests prove the task is complete;
- fixture/mock/fake disclosures and future real-service conversion task, if applicable;
- PR review checklist items for the human reviewer;
- known limitations.

Optional local rerun commands are useful, but the main output should help the supervisor justify the PR/MR and explain what the human should inspect in code and tests.

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

Dependency provisioning:
- <required dependency> - provisioned|already available|blocked - <commands/resources used or exact human action needed>

Test proof:
- <requirement-to-test mapping and why this proves completion>

Boundary mode disclosures:
- <real-service/local-service/test-container/real-network/real-data/fixture/recording/mock/fake used, why, and future conversion task or "None">

Test output notes:
- <how tests disclose service/network/real-data mode and important observed values>

Human review packet notes:
- <what the human should inspect in the PR/MR code and tests>

Optional local rerun:
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
