# Agentic Review

Review happens without routine human involvement. Use reviewer and fix-worker agents as bounded workers under the phase owner.

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
- no-mock/no-fixture rules;
- security, migration, and compatibility risks.
- recurring review failures that should become lesson candidates.

High/Medium findings block completion. Dispatch a fix worker with a narrow goal, then rerun review.

## Mock And Fixture Rejection

Fixtures and mocks are acceptable for:

- unit tests;
- edge cases;
- hard-to-trigger failures;
- seed data when production code still uses the real path.

They do not satisfy phase acceptance or service wiring that requires real integration proof. A temporary fake in runtime code requires a concrete conversion task before the phase can be accepted unless the phase scope explicitly excludes that real boundary.

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
lesson_candidate:
  problem: "recurring proven problem, or null"
  proven_fix: "durable fix, or null"
  evidence:
    - "docs/qa/artifacts/<phase>/review.txt"
```

Store large logs as artifacts and reference paths.

Reviewers may suggest lesson candidates when a repeated failure mode appears in test proposals, implementation reviews, or fix loops. The phase owner decides whether to promote the candidate into a repo lesson.
