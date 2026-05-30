# Agentic Review

Review happens without routine human involvement. Use reviewer and fix-worker agents as bounded workers under the orchestrator. When review finds setup, dependency, runtime, environment, or workflow-state blockers, return a classified blocker so the orchestrator can dispatch a blocker-resolver before escalating to the human.

## Test Proposal Review

Approve tests only when they:

- map to the task requirements and phase plan;
- fail for the expected missing behavior, not broken setup;
- cover the named service-wiring rows where applicable;
- use real local services, containers, emulators, dev/staging services, or explicit escalations for real wiring;
- avoid snapshot-only or mock-only assertions for behavior that needs real integration proof;
- are narrow enough to guide implementation without overfitting to a guessed solution.

If tests are weak, dispatch a test-fix worker or return specific edits to the same worker.

## Implementation Review

Review implementation against:

- approved tests;
- task `Agent-Run Acceptance`;
- `Service Wiring Rows Covered`;
- `Test Mode Disclosure`;
- repo patterns and ownership boundaries;
- mock/fixture ledger rules;
- security, migration, and compatibility risks.
- recurring review failures that should become lesson candidates.
- runtime content boundary: smoke-test instructions, reviewer instructions, local setup steps, acceptance checklists, implementation prompts, agent handoff text, and internal QA notes must not appear in product UI, API responses, seed user-facing content, generated demo content, or runtime assets unless explicitly required as end-user product help.

High/Medium findings block completion. Dispatch a fix worker with a narrow goal, then rerun review.

Treat workflow-only text in runtime app surfaces as a high-severity finding. The required fix is to remove it from product code/content and place it in the phase-transition handoff/report, QA artifact, acceptance packet, or developer docs.

Do not mark missing local tools, stale dependencies, local services, generated files, or non-secret env wiring as human blockers. Classify them as blocker-resolver candidates with the failing command and artifact path.

## Mock And Fixture Review

Fixtures and mocks are acceptable for:

- unit tests;
- edge cases;
- hard-to-trigger failures;
- seed data when production code still uses the real path.
- temporary runtime stand-ins during implementation when they are tracked and converted, intentionally bounded, or explicitly deferred.

They do not satisfy phase acceptance or service wiring that requires real integration proof. A temporary fake in runtime code requires a valid mock/fixture ledger disposition before the task can be accepted.

Reject or require a fix when:

- worker results omit a mock/fixture ledger entry for a fake visible in changed files;
- production/dev runtime code still uses fake data but the ledger marks it `test-only`;
- service-wiring rows are claimed as covered by mock-only evidence when the plan requires real integration;
- `deferred-with-conversion-task` lacks a concrete later phase/task path;
- the phase claims real integration but Playwright/API/service evidence exercises only fixture transport;
- a fake is marked `intentional-phase-boundary` but the phase plan does not explicitly make fixture-backed behavior the deliverable.

## Review Output

Keep review output compact:

```yaml
status: approved # approved | needs_fix | blocked
findings:
  - severity: high
    file: "path"
    issue: "short issue"
    required_fix: "specific fix"
verification:
  - command: "pnpm test"
    result: pass
    artifact: "docs/qa/artifacts/<phase>/review.txt"
mock_fixture_findings:
  - id: "mf-001"
    status: approved # approved | needs_fix | blocked
    issue: "short issue or null"
runtime_content_boundary:
  status: approved # approved | needs_fix | blocked
  artifact: "docs/qa/artifacts/<phase>/runtime-workflow-copy-audit.txt"
  issue: "workflow-only instructions in runtime UI, or null"
lesson_candidate:
  problem: "recurring proven problem, or null"
  proven_fix: "durable fix, or null"
  evidence:
    - "docs/qa/artifacts/<phase>/review.txt"
blockers:
  - id: "blocker-review-runtime"
    classification: "runtime_dependency"
    summary: "local Kubernetes runtime missing"
    artifact: "docs/qa/artifacts/<phase>/review-runtime-probe.txt"
    suggested_owner: "blocker-resolver"
```

Store large logs as artifacts and reference paths.

Reviewers may suggest lesson candidates when a repeated failure mode appears in test proposals, implementation reviews, or fix loops. The orchestrator decides whether to promote the candidate into a repo lesson.
