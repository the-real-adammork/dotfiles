# Worker TDD

Workers are bounded executors. They do not spawn workers, schedule sibling work, update run state, or infer phase-level intent beyond the assigned lane.

## Adaptive TDD Contract

Use full two-stage TDD for high-risk or integration-sensitive behavior:

- service wiring;
- auth/security/permissions;
- migrations or persistence changes;
- E2E harnesses;
- external integrations;
- cross-service behavior;
- bug fixes where the failure must be demonstrated first.

Two-stage flow:

1. Worker writes tests first.
2. Worker runs the tests and confirms they fail for the expected reason.
3. Worker returns a test proposal result without production implementation.
4. Phase owner or reviewer approves the tests.
5. Worker implements only after test approval.
6. Worker runs focused tests and required integration/E2E checks.
7. Worker writes or returns worker result YAML.

For low-risk isolated behavior, the phase owner may allow inline test-first implementation in one worker goal. The worker must still write tests before production code, show the expected failing test or explain why a pre-implementation failure was not practical, and return enough evidence for reviewer validation.

For docs, config, or mechanical changes where TDD is not meaningful, replace test-first with the smallest meaningful validation command and explain why.

## Test Proposal Result

Return compact YAML or a compact message containing:

```yaml
status: test_proposed
task: "Task N"
test_files:
  - "test/path"
commands:
  - command: "pnpm test path"
    result: fail_expected
    artifact: "docs/qa/artifacts/<phase>/task-n-test-proposal.txt"
expected_failure: "missing behavior X"
requirement_mapping:
  - "Task acceptance bullet"
service_wiring_rows:
  - "row-name"
mock_or_fixture_disclosure: []
blockers: []
```

## Implementation Result

After approved tests pass, return worker result YAML as described in `state-files.md`.

The result must include:

- files changed;
- commands run;
- pass/fail result;
- service-wiring rows covered;
- real dependencies used;
- mocks or fixtures used and why they are acceptable;
- residual risk;
- lesson candidate when the worker found a recurring, proven, repo-specific problem;
- recommended downstream plan edits;
- blockers or escalations.
- secret handling fields from `$secrets` when secret material changed.

## Restrictions

- Do not broaden scope.
- Do not rewrite the phase plan unless assigned.
- Do not update `run.yaml` or `phase.yaml` unless assigned.
- Do not hide failing tests.
- Do not satisfy service wiring with mocks when real wiring is required.
- Do not spawn other agents.
- Do not generate, write, reveal, hide, stage, or commit secret material without following `$secrets`.

## Lesson Candidates

Workers may suggest a lesson, but they do not write repo lessons or edit `AGENTS.md`.

Suggest `lesson_candidate` only when the problem appears reusable beyond this one task, the fix is proven by the current work, and the evidence path is available. Do not suggest lessons for one-off typos, obvious mistakes, or speculative preferences.
