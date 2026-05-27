# Plan Writing Reference

Write plans that an agent team can execute without rediscovering the project or waiting for routine external checkpoints. Plans should be concrete, testable, scoped to one smoke-testable phase, and broken into small tasks.

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

**Phase Acceptance:** <platform automation, service-wiring coverage, and packet path that prove the smoke-testable outcome>

## Phase Execution Contract

**Execution Model:** The supervisor launches one top-level phase orchestrator for this phase. Worker agents implement bounded substantial tasks; the orchestrator remains responsible for sequencing, integration, verification, the acceptance packet, and downstream assumptions.

**Phase Orchestrator Responsibilities:**
- Maintain the phase branch/worktree and current understanding of completed work.
- Dispatch only worker tasks with clear file/resource boundaries and explicit dependencies.
- Integrate worker results promptly, run the relevant verification, and update downstream task instructions when implementation reality changes.
- Keep the phase acceptance packet current enough that a context handoff can resume from files, not chat history.
- Block only for allowed escalations.

**Worker Delegation Map:**
| Lane | Task(s) | Delegation Decision | Can Run In Parallel With | Shared Resources / Collision Risk | Integration Checkpoint |
| --- | --- | --- | --- | --- | --- |
| <lane name> | <Task N-N> | <orchestrator orchestration/glue, serial worker, or parallel worker> | <lanes/tasks or "None"> | <files/db/services/runtime resources> | <command/evidence orchestrator runs after return> |

**Long-Running Handoff:**
- Handoff path: `docs/implementation-runs/<run-id>/handoffs/YYYY-MM-DD-HHMM-<phase>.md`
- Required contents: current task status, branch/worktree, worker results, verification evidence, service-wiring coverage, acceptance packet status, event log paths, blockers/escalations, and exact restart instructions.

## Implementation Execution Handoff

This phase is intended to be run by `$implementation-execution` after planning approval.

- Run state: `docs/implementation-runs/<run-id>/run.yaml`
- Phase state: `docs/implementation-runs/<run-id>/phases/<phase-slug>.yaml`
- Execution manifest: `docs/implementation-runs/<run-id>/manifests/<phase-slug>.yaml`
- Worker result YAML: `docs/implementation-runs/<run-id>/workers/<lane>-<timestamp>.yaml`
- Event logs: `docs/implementation-runs/<run-id>/events/`
- Acceptance packet: `docs/qa/phase-acceptance/YYYY-MM-DD-<feature>-phase-<n>.md`
- QA artifacts: `docs/qa/artifacts/<phase-slug>/`

## Codex Efficiency Rules

Optimize the plan for the fewest coordination turns that still preserve reviewability and safe parallelism.

- Prefer one phase orchestrator with a small number of substantial worker lanes over many tiny worker tasks.
- Delegate only work that is bounded, independently verifiable, and large enough to justify worker startup/context cost.
- Keep orchestration, cross-cutting integration decisions, tiny glue, consistency edits, and acceptance packet ownership with the orchestrator.
- Do not use the orchestrator as the default implementation worker. Substantial runtime, service/API, persistence, schema/migration, parser, frontend, E2E/integration-test, or shared-contract behavior belongs in a worker lane even when it must run serially.
- Group closely related files and behaviors into one task when splitting would create extra handoffs without meaningful parallelism.
- Split tasks when they touch independent surfaces, can run in parallel without shared resources, or need separate review because of risk.
- Avoid repeating the same context in every task. Put phase-wide rules in the file map, service wiring matrix, execution contract, and acceptance gate; task sections should reference those names.
- Make every delegated lane return compact evidence: changed files, commands run, pass/fail output summary, service-wiring rows covered, risks, and follow-up edits needed.
- For behavior changes in delegated lanes, require the worker to complete a test proposal/approval loop before implementation: write or update tests first, run them to show the expected failure, return test intent and failure evidence to the orchestrator, wait for orchestrator approval that the tests satisfy the task, then implement and make the approved tests pass.

## Orchestrator Work Limits

The orchestrator is an integrator and scheduler, not the default implementer.

Orchestrator-owned tasks are allowed only for:

- sequencing and active-frontier decisions;
- shared contract approval before workers start;
- tiny glue or mechanical edits where a worker lane would be larger than the change;
- run/phase state, handoff, acceptance packet, and plan consistency updates;
- post-worker integration fixes that are small, local, and do not add new behavior.

Substantial implementation must be a worker lane even when it is serial, context-heavy, or unsafe to parallelize. This includes runtime code, service/API behavior, persistence, migrations, schemas, parser logic, frontend behavior, E2E/integration tests, and shared contracts consumed by downstream tasks.

Do not write ambiguous ownership such as `orchestrator or worker`, `orchestrator or one worker`, or `orchestrator unless delegated`. Choose one owner. If substantial work cannot run in parallel, write `worker lane: <lane>; parallel with none`.

Every task marked `orchestrator` must include an `Owner-Only Justification` field explaining why the task is orchestration, glue, state, acceptance, or plan consistency rather than substantial implementation.

## Autonomy And Escalation

| Escalation | Needed By | Agent-Owned Attempt First | Escalate Only If | Blocking Behavior |
| --- | --- | --- | --- | --- |
| <dependency/service/key/tool> | <task number or "Before Task N"> | <repo/tooling/container/emulator/dev-resource attempt> | <credential/paid account/product/legal/destructive production action/external approval/device unavailable> | <what stops and what evidence to report> |

---
```

The escalation table must include only work the agent team cannot safely or legitimately complete alone. Normal setup is agent-owned: local dependencies, containers, emulators, dev servers, migrations, seed data, fixtures, test accounts available through repo tooling, and deterministic QA evidence must be planned as tasks instead of delegated externally.

Allowed escalation categories are narrow:

- credentials, secrets, private keys, or account access that cannot be obtained through approved local setup;
- paid account setup, billing, quota purchase, or vendor approval;
- product, legal, privacy, security, or compliance decisions not already answered by the requirements or design;
- destructive production actions, real customer data access, or irreversible external side effects;
- physical device, simulator entitlement, browser profile, or external service availability that the agent cannot provision after a documented attempt.

If a task needs a real service, real database, real network/API call, real-data path, or service integration to prove completion, the plan must say how the agent provisions it through repo tooling, containers, emulators, dev/staging resources, migrations, or seed scripts. If it falls into an allowed escalation category, record the blocker in `Autonomy And Escalation` and make the dependent task block with clear fallback evidence.

## Service Wiring Matrix

Every plan must include a matrix of the phase flows that need integrated verification:

```markdown
## Service Wiring Matrix

| Flow | User/Runtime Surface | API/Service | Persistence | Jobs/Queues | External/Local Integration | Required Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| <flow name> | <UI/CLI/app/API entry> | <service/code path> | <db/files/cache> | <job/event or "None"> | <external/local dependency or "None"> | <test/log/screenshot/trace/db assertion> |
```

The matrix is not a design recap. It is the enforcement list for agent-run integration verification. Each row must be covered by at least one task, and every row still relevant at the end of the phase must be covered by the phase acceptance gate.

## E2E Harness Readiness

Bring E2E automation into the phase as soon as it can verify real wiring. If the repo has no appropriate harness, include an early task that creates the minimum viable harness and proves it can launch the app/service with deterministic test data. Do not defer harness creation to a late QA task when earlier integration work depends on it.

During phase development, tasks that wire user/runtime surfaces to APIs, services, persistence, jobs, or integrations must add or extend E2E or integration coverage for that wiring. Do not reserve E2E work for a final QA task; that creates the wrong incentive and lets broken integration accumulate until the end.

Choose QA automation by platform:

- Web apps: use Playwright to drive the browser and verify page behavior, network/API interaction, service effects, and visible result unless the repo has an explicit different browser E2E standard.
- Mobile apps: use the platform simulator/emulator automation available in the repo, such as XCUITest, XCTest UI tests, Maestro, Detox, Appium, or Android instrumentation.
- Desktop apps: use the repo's desktop UI automation or platform test harness, such as Playwright for Electron, XCTest UI automation, WinAppDriver, or Appium where appropriate.
- CLI/TUI tools: use an end-to-end command/session test that runs the built command against realistic files/services and verifies filesystem, process, and output effects.
- Backend-only services: use an end-to-end API/service test that starts the service with realistic dependencies and verifies request, persistence, downstream service, and observable response behavior.

## Task Format

Each task should be small enough to review independently and should end with verification. Tasks inside a phase may touch different layers of the stack, but together they must complete the phase's smoke-testable outcome. Prefer TDD for behavior changes.

Tasks are potential worker units, not automatic worker units. A task is suitable for delegation only when its dependencies, files, runtime resources, acceptance evidence, and integration checkpoint are explicit enough that a bounded worker can complete it without inferring phase-level intent. Use `orchestrator` only for orchestration, tiny glue, state, acceptance, and plan consistency work. Substantial implementation that is not safe to parallelize is still a serial worker lane.

````markdown
### Task N: <specific outcome>

**Depends On:** <Task numbers this task depends on, or "None">

**Execution:** <orchestrator orchestration/glue | worker lane: lane name>; parallel with <task/lane or "none">; checkpoint <command/evidence>

**Owner-Only Justification:** <required if Execution is orchestrator; otherwise "not applicable">

**Files:**
- Create: `exact/path`
- Modify: `exact/path`
- Test: `exact/path`

**Service Wiring Rows Covered:**
- <Service Wiring Matrix row name, or "None - isolated change">

**Agent-Run Acceptance:**
- Automation command: `<exact command>`
- Expected result: <observable behavior or artifact>
- Evidence to collect: <logs/screenshots/videos/traces/db rows/API output/files>

**Test Mode Disclosure:**
- Automated tests: <mocked fixtures | fake local service | real local service | real network/service | not applicable>
- Production/dev path exercised: <yes/no and which path>
- Mock-only risk: <what integration could still be broken, or "None">
- Required real dependencies: <service/db/network/API/real-data path and how agent provisions it, or exact escalation blocker>
- Blocking if unavailable: <yes/no and why>

**TDD Approval Gate:** <required for delegated behavior work | not applicable with reason>
- Worker writes or updates tests first.
- Worker runs focused tests and records the expected failure.
- Worker returns test intent, covered requirements, command, expected failure, and affected files to the orchestrator.
- Orchestrator approves that the tests satisfy the task requirements before implementation starts.
- Worker implements only after approval, then reruns the approved tests until green.

- [ ] Step 1: Write or update the failing test

```<language>
<actual test code or precise test shape>
```

- [ ] Step 2: Run the focused test and confirm it fails

Run: `<exact command>`
Expected: `<specific failure or missing behavior>`

- [ ] Step 3: For delegated behavior work, return the test proposal and expected-failure evidence to the orchestrator for approval

Approval evidence: `<worker result YAML path or orchestrator note path>`
Expected: `<orchestrator approves the tests as sufficient for this task before implementation>`

- [ ] Step 4: Implement the smallest change

```<language>
<actual code shape, function signatures, or concrete edit>
```

- [ ] Step 5: Run focused verification

Run: `<exact command>`
Expected: `<specific pass condition>`

- [ ] Step 6: Commit this task

Suggested message: `<type>[optional scope]: <description>`
````

For orchestrator-owned work, documentation, config, or mechanical changes where TDD approval does not apply, mark `TDD Approval Gate` as not applicable with a concrete reason and replace the failing-test step with the smallest meaningful validation step, such as syntax validation, config parse, render check, or dry run.

## Phase E2E And Acceptance Gate

Every implementation plan must define a phase acceptance gate. This is a completion gate for the phase, not a task-position requirement. The plan should place E2E and integration work in the tasks where wiring is introduced, then use the acceptance gate to rerun the complete evidence set and confirm the phase is shippable to the next phase.

The acceptance gate must:

- prove the complete phase behavior through the real user/runtime surface, not only isolated internals;
- cover every applicable row in the `Service Wiring Matrix`;
- verify wiring between UI/CLI/app surface, API/service layer, persistence, background jobs, and external/local integrations that are in scope for the phase;
- use the appropriate platform automation for the project;
- require a phase acceptance packet with commands, results, evidence, and residual risks;
- block phase completion if the automation environment cannot run and the phase cannot be honestly smoke tested.

Each plan must include this section after the task list or before handoff:

````markdown
## Phase Acceptance Gate

**Acceptance Commands:**
- Run: `<exact command>`
  Expected: `<specific pass condition proving the phase smoke test works through the real app surface>`

**Required Service Wiring Coverage:**
- <Flow row name> - <E2E test/assertion/evidence that covers it>
- <Flow row name> - <E2E test/assertion/evidence that covers it>

**Acceptance Packet:** `docs/qa/phase-acceptance/YYYY-MM-DD-<feature>-phase-<n>.md`

**Completion Rule:** The phase cannot be marked complete until the commands pass, every applicable service-wiring row has evidence, and the acceptance packet exists with current commit evidence.
````

## Phase Acceptance Packet

The phase acceptance packet is the handoff artifact a long-running agent team leaves for later phases and occasional operator audits. It may be created or updated by any task, but it must be current before the phase is marked complete.

Packet contents:

- phase plan path and phase name;
- implementation commit range or task commit list;
- smoke-testable outcome;
- service wiring matrix with covered evidence for each row;
- commands run, exact results, and timestamps where available;
- E2E artifacts such as Playwright traces, screenshots, videos, simulator logs, API logs, database assertions, or CLI output paths;
- mock/fixture ledger summary with disposition for any tracked mock, fixture, fake service, placeholder, generated data source, or temporary runtime stand-in;
- escalations encountered and final disposition;
- downstream assumptions later phases may rely on.

## Mock And Real-Service Rules

Every task that includes tests must disclose whether the tests use fixtures/mocks or real service/dev production paths. Be specific: name the mocked dependency, fake service, real local service, or real external service.

## Task Dependency Rules

Every task must include `**Depends On:**`. Use task numbers from the same plan, such as `Task 1`, `Task 2A`, or `None`.

Declare only implementation-order dependencies: a task should depend on another task when it requires code, schema, generated files, interfaces, fixtures, or verified behavior produced by that earlier task. Do not add dependencies merely because tasks appear earlier in the document. Tasks marked `Depends On: None` are expected to be parallelizable after plan setup and agent-owned prerequisites are available.

If a dependency crosses plan boundaries, name the external plan and task explicitly instead of using the same-plan shorthand so `$implementation-execution` can build the active frontier from file-backed plan state.

## Dependency And Parallelism Consistency

Before finalizing a plan, verify every task's `Depends On` and `Execution` line against the worker delegation map.

- A task cannot be marked parallel with any task it depends on.
- A task cannot be marked parallel with any task that depends on it.
- Parallel lanes must share no required sequential contract unless the plan names the contract handoff point, such as "after shared contract exports are approved" or "after API fixture route exists."
- If two tasks share files, schema, API contracts, package/config, migrations, generated fixtures, browser harness setup, or long-lived runtime resources, either serialize them or name the precise handoff/checkpoint that makes parallel execution safe.
- If the safe parallel point is conditional, write it in both the `Execution` line and the `Worker Delegation Map`; do not rely on task order alone.

Do not mark real service, credential, account, network, database, queue, storage, or real-data verification as optional when the task or design requires that integration. These dependencies are mandatory verification gates. If unavailable, the task should be blocked and recorded as an escalation only when it fits an allowed escalation category.

Mocks, fixtures, fake services, placeholders, generated data, and temporary runtime stand-ins are acceptable during implementation when they speed up safe development or make tests deterministic. The plan must make their disposition explicit so `$implementation-execution` can track them in the mock/fixture ledger.

Valid dispositions:

- `test-only`: used only in tests or deterministic seed data; production/dev runtime path still uses the real implementation.
- `intentional-phase-boundary`: fixture-backed runtime behavior is explicitly the deliverable of this phase, such as a fixture shell phase.
- `converted`: temporary fake is replaced by real integration inside this phase and verified through the real runtime boundary.
- `deferred-with-conversion-task`: fake remains by design and a named later phase/task owns conversion to real integration.
- `blocked`: real dependency is unavailable under allowed escalation rules and the phase cannot honestly complete unless the phase boundary explicitly allows that blocker.

If production or dev runtime behavior depends on a mock, stub, fake service, fixture-only data source, no-op client, in-memory stand-in, or disabled network path and none of the valid dispositions applies, the implementation plan is invalid and must fail review.

Any conversion task must:

- name the mocked production/dev path being replaced;
- identify the real service, network call, persistence layer, or code path;
- include automated verification against the most realistic available path;
- include agent-run acceptance evidence for the real integration;
- block instead of completing if that task is the point where real service/data integration is required and the dependency is not available.

## No Placeholders

Never leave:

- `TBD`, `TODO`, "fill this in", "etc."
- "Add appropriate error handling" without exact cases
- "Write tests" without the test names or behavior
- "Similar to previous task"
- Code steps without code shape, API names, or exact commands
- Commands without expected results
- "Mock for now" without a valid mock/fixture ledger disposition and, when needed, a later real-service conversion task
- "Manual test later" or optional non-automated verification language
- "Optional" real service, credential, account, database, network, queue, storage, or real-data verification for a task that requires that dependency
- A phase plan without a `Phase Execution Contract`
- A task without a compact `Execution` line
- Ambiguous ownership such as `orchestrator or worker`, `orchestrator or one worker`, or `orchestrator unless delegated`
- An orchestrator-owned task without an `Owner-Only Justification`
- An orchestrator-owned task that includes substantial runtime, service/API, persistence, schema/migration, parser, frontend, E2E/integration-test, or shared-contract behavior
- A phase plan without `Autonomy And Escalation`, `Service Wiring Matrix`, E2E harness readiness coverage, and a `Phase Acceptance Gate`
- A task that touches service wiring but does not name the service-wiring rows it covers

## Self-Review

Before presenting the plan, check:

- Every requirement maps to at least one task.
- The plan represents one substantial vertical phase, not a horizontal stack layer.
- The plan has a concrete smoke-testable outcome available after completion.
- The `Phase Execution Contract` defines the supervisor-launched phase orchestrator, worker delegation map, integration checkpoints, and handoff path.
- The `Codex Efficiency Rules` are followed: substantial lanes, minimal coordination, no tiny delegation churn.
- Every task includes a compact `Execution` line, with safe parallelism and integration checkpoint stated.
- No task uses ambiguous ownership such as `orchestrator or worker`, and every orchestrator-owned task has an `Owner-Only Justification`.
- Every substantial runtime, service/API, persistence, schema/migration, parser, frontend, E2E/integration-test, or shared-contract change is assigned to a worker lane, even when serial.
- The plan includes a `Service Wiring Matrix`, and every row is covered by task-level evidence or the phase acceptance gate.
- E2E automation appears early enough to verify integrations during phase development.
- Tasks that introduce service wiring include `Service Wiring Rows Covered`.
- The `Phase Acceptance Gate` uses the appropriate platform harness and verifies wiring across the phase's app surface, APIs/services, persistence, jobs, and integrations.
- The `Phase Acceptance Gate` requires a current phase acceptance packet with evidence and downstream assumptions.
- Later planned phases can build on this plan's verified behavior.
- Every task includes `**Depends On:**`, with `None` for tasks that can start in parallel.
- Every created or modified file appears in the file map.
- Later tasks use names, types, paths, and commands defined earlier.
- The plan can be executed task-by-task without reading unrelated parts of the repo.
- Verification covers the changed behavior, not just formatting.
- The `Autonomy And Escalation` table includes only allowed escalation categories, and normal setup remains agent-owned.
- Every task includes a concrete `Agent-Run Acceptance` section.
- Every task with tests includes a `Test Mode Disclosure`.
- Any production/dev mock, fake, stub, no-op, fixture-only path, or disabled network path has a valid mock/fixture ledger disposition and, when needed, a later conversion task to the real implementation.

Fix gaps inline before delivering the plan.

## Handoff

After saving the plan, say where it is and offer execution options:

```text
Plan saved to `docs/plans/<filename>.md`.

Execution options:
1. Run `$implementation-execution` for this phase.
```
