# Plan Writing Reference

Write plans that an agent or engineer can execute without rediscovering the project. Plans should be concrete, testable, scoped to one smoke-testable phase, and broken into small tasks.

Adapted from the Obra/Superpowers `writing-plans` skill for this Codex setup.

## Start

Before writing tasks, inspect the repo enough to know the existing patterns, commands, test setup, and relevant files. Use `/usr/bin/git` when git is needed.

Save plans to:

```text
docs/plans/YYYY-MM-DD-<short-feature-name>.md
```

User instructions about plan location override this default.

## Scope Check

If the request is too large for one implementation plan, split it into sequential phase plans using `references/phasing.md`. Each plan is one phase: a substantial vertical increment that touches the parts of the stack needed to make that increment work and leaves the app in a smoke-testable state.

Do not split plans horizontally by stack layer, such as "backend plan", "frontend plan", or "database plan", unless the whole project is truly only that layer. Prefer phases where backend, frontend, persistence, CLI, jobs, and integration work appear together as needed to make one coherent behavior come alive.

Do not write a plan with vague umbrella tasks such as "implement backend" or "build UI". Decompose by user-visible behavior, runtime capability, and smoke-testable system state.

## File Map

Before task breakdown, include a file map:

```markdown
## File Map

- Create: `path/to/new-file.ext` - responsibility
- Modify: `path/to/existing-file.ext` - exact role in this change
- Test: `path/to/test-file.ext` - behaviors covered
```

Use exact paths. If a line number matters, include it.

## Plan Header

Every plan starts with:

```markdown
# <Feature Name> Implementation Plan

**Goal:** <one sentence>

**Phase Boundary:** <2-3 sentences describing the vertical increment this plan delivers and what later phases build on>

**Verification:** <primary commands or checks that prove the work>

**Smoke-Testable Outcome:** <specific working behavior available after this phase>

**Phase-Final E2E:** <platform automation and command that will duplicate the human smoke test>

## Human-In-The-Loop TODOs

| Needed By | Task | Human Action | Why It Is Needed | When To Remind |
| --- | --- | --- | --- | --- |
| <dependency/service/key/tool> | <task number or "Before Task N"> | <what the human must do> | <what gap this unlocks> | <before/during task> |

---
```

This TODO table must include all human-required setup across the entire plan: API keys, accounts, service configuration, local dependencies, paid services, test data, manual approvals, device/browser access, credentials, and any environmental setup the agent cannot complete alone. If a human action only matters after a certain task lands, mark that dependency in `Needed By` and `When To Remind`.

Required real dependencies are blocking, not optional. If a task needs a real service, real database, real network/API call, real-data path, or service integration to prove completion, the plan must say so in the task verification steps. The agent should attempt safe provisioning through repo tooling, containers, emulators, dev/staging resources, migrations, and seed scripts. If the agent cannot provision the dependency because credentials, account access, paid setup, approval, or product/engineering steering is required, the dependency belongs in the Human-In-The-Loop TODO table and the task must block until it is available.

## Task Format

Each task should be small enough to review independently and should end with verification. Tasks inside a phase may touch different layers of the stack, but together they must complete the phase's smoke-testable outcome. Prefer TDD for behavior changes.

## Required Phase-Final E2E Task

Every implementation plan must end with a final task dedicated to end-to-end QA automation for the whole phase. This task is mandatory even when earlier tasks include unit, integration, or narrow UI tests.

The final E2E task must:

- duplicate the human smoke test with automation;
- verify the complete phase behavior through the real user/runtime surface, not only isolated internals;
- exercise the wiring between UI/CLI/app surface, API/service layer, persistence, background jobs, and external/local integrations that are in scope for the phase;
- use the appropriate platform automation for the project;
- be blocked, not skipped, if the required automation environment cannot run and the phase cannot be honestly smoke tested.

Choose the QA automation by platform:

- Web apps: use Playwright to drive the browser and verify the page behavior, network/API interaction, service effects, and visible result.
- Mobile apps: use the platform simulator/emulator automation available in the repo, such as XCUITest, XCTest UI tests, Maestro, Detox, Appium, or Android instrumentation.
- Desktop apps: use the repo's desktop UI automation or platform test harness, such as Playwright for Electron, XCTest UI automation, WinAppDriver, or Appium where appropriate.
- CLI/TUI tools: use an end-to-end command/session test that runs the built command against realistic files/services and verifies filesystem, process, and output effects.
- Backend-only services: use an end-to-end API/service test that starts the service with realistic dependencies and verifies request, persistence, downstream service, and observable response behavior.

If the repo has no appropriate E2E harness yet, the phase-final E2E task must include creating the minimal harness required for that platform, then using it to verify the phase smoke test.

````markdown
### Task N: <specific outcome>

**Depends On:** <Task numbers this task depends on, or "None">

**Files:**
- Create: `exact/path`
- Modify: `exact/path`
- Test: `exact/path`

**Human-In-The-Loop Test:**
- <manual check the human can perform to confirm this task works>
- Requires: <keys/services/dev server/browser/device/test account, or "None">
- Expected result: <observable behavior>

**Test Mode Disclosure:**
- Automated tests: <mocked fixtures | fake local service | real local service | real network/service | not applicable>
- Production/dev path exercised: <yes/no and which path>
- Mock-only risk: <what integration could still be broken, or "None">
- Required real dependencies: <service/db/network/API/real-data path and how agent provisions it, or exact human blocker>
- Blocking if unavailable: <yes/no and why>

- [ ] Step 1: Write or update the failing test

```<language>
<actual test code or precise test shape>
```

- [ ] Step 2: Run the focused test and confirm it fails

Run: `<exact command>`
Expected: `<specific failure or missing behavior>`

- [ ] Step 3: Implement the smallest change

```<language>
<actual code shape, function signatures, or concrete edit>
```

- [ ] Step 4: Run focused verification

Run: `<exact command>`
Expected: `<specific pass condition>`

- [ ] Step 5: Commit this task

Suggested message: `<type>[optional scope]: <description>`
````

For documentation, config, or mechanical changes where TDD does not apply, replace the failing-test step with the smallest meaningful validation step, such as syntax validation, config parse, render check, or dry run.

The final task in every plan must use this shape:

````markdown
### Task N: Phase-final E2E QA automation

**Depends On:** <all tasks required for the phase behavior>

**Files:**
- Create/Modify/Test: <platform E2E test files and supporting fixtures/config>

**Human-In-The-Loop Test:**
- <same smoke test the automation duplicates>
- Requires: <browser/simulator/device/server/services/test data>
- Expected result: <observable phase behavior>

**Test Mode Disclosure:**
- Automated tests: <Playwright | simulator automation | CLI E2E | service E2E | other platform harness>
- Production/dev path exercised: yes - <specific UI/API/service/persistence/integration path>
- Mock-only risk: <remaining mocked boundary, or "None">
- Required real dependencies: <services/data/dev server/simulator/browser and how agent provisions them, or exact human blocker>
- Blocking if unavailable: yes - phase cannot be accepted without automated E2E coverage of the smoke test

- [ ] Step 1: Add or update the platform E2E test that duplicates the phase smoke test
- [ ] Step 2: Run the E2E test and confirm it fails before missing wiring is complete, when practical
- [ ] Step 3: Complete any missing harness/config/test-data wiring required for the E2E path
- [ ] Step 4: Run the E2E command

Run: `<exact command>`
Expected: `<specific pass condition proving the phase smoke test works through the real app surface>`

- [ ] Step 5: Commit this task

Suggested message: `test(e2e): cover <phase behavior>`
````

## Mock And Real-Service Rules

Every task that includes tests must disclose whether the tests use fixtures/mocks or real service/dev production paths. Be specific: name the mocked dependency, fake service, real local service, or real external service.

## Task Dependency Rules

Every task must include `**Depends On:**`. Use task numbers from the same plan, such as `Task 1`, `Task 2A`, or `None`.

Declare only implementation-order dependencies: a task should depend on another task when it requires code, schema, generated files, interfaces, fixtures, or verified behavior produced by that earlier task. Do not add dependencies merely because tasks appear earlier in the document. Tasks marked `Depends On: None` are expected to be parallelizable after plan setup and human-in-the-loop prerequisites are available.

If a dependency crosses plan boundaries, name the external plan and task explicitly instead of using the same-plan shorthand. The Linear sync workflow only creates automatic Linear issue blocking relations for dependencies within the same implementation plan.

Do not mark real service, credential, account, network, database, queue, storage, or real-data verification as optional when the task or design requires that integration. These dependencies are mandatory verification gates. If unavailable, the task should be blocked and assigned for human action rather than completed with an optional smoke-test note.

Mocks are acceptable for early unit tests, fast failure isolation, and hard-to-trigger error paths. But if production code is temporarily wired to a mock, stub, fake service, fixture-only data source, no-op client, in-memory stand-in, or disabled network path, the plan must include a later task that replaces it with the real implementation.

If production or dev runtime behavior depends on a mock and there is no later conversion task, the implementation plan is invalid and must fail review.

The conversion task must:

- name the mocked production/dev path being replaced;
- identify the real service, network call, persistence layer, or code path;
- include automated verification against the most realistic available path;
- include a human-in-the-loop test when external services, credentials, or local setup are required.
- block instead of completing if that task is the point where real service/data integration is required and the dependency is not available.

## No Placeholders

Never leave:

- `TBD`, `TODO`, "fill this in", "etc."
- "Add appropriate error handling" without exact cases
- "Write tests" without the test names or behavior
- "Similar to previous task"
- Code steps without code shape, API names, or exact commands
- Commands without expected results
- "Mock for now" without a later real-service conversion task
- "Manual test later" without a concrete Human-In-The-Loop Test section
- "Optional" real service, credential, account, database, network, queue, storage, or real-data verification for a task that requires that dependency
- A phase plan whose final task is not dedicated to automated E2E QA for the phase smoke test

## Self-Review

Before presenting the plan, check:

- Every requirement maps to at least one task.
- The plan represents one substantial vertical phase, not a horizontal stack layer.
- The plan has a concrete smoke-testable outcome available after completion.
- The final task is a phase-final E2E QA automation task using the appropriate platform harness.
- The phase-final E2E task duplicates the human smoke test and verifies wiring across the phase's app surface, APIs/services, persistence, jobs, and integrations.
- Later planned phases can build on this plan's verified behavior.
- Every task includes `**Depends On:**`, with `None` for tasks that can start in parallel.
- Every created or modified file appears in the file map.
- Later tasks use names, types, paths, and commands defined earlier.
- The plan can be executed task-by-task without reading unrelated parts of the repo.
- Verification covers the changed behavior, not just formatting.
- The `Human-In-The-Loop TODOs` table includes all human setup required across the whole plan.
- Every task includes a concrete `Human-In-The-Loop Test` section.
- Every task with tests includes a `Test Mode Disclosure`.
- Any production/dev mock, fake, stub, no-op, fixture-only path, or disabled network path has a later conversion task to the real implementation.

Fix gaps inline before delivering the plan.

## Handoff

After saving the plan, say where it is and offer execution options:

```text
Plan saved to `docs/plans/<filename>.md`.

Execution options:
1. Subagent-driven - dispatch focused workers per task, then review/integrate.
2. Inline - execute tasks in this session with checkpoints.
```
