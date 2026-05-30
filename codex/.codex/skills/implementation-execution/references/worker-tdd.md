# Worker TDD

Workers are bounded executors. They do not spawn workers, schedule sibling work, update run state, or infer phase-level intent beyond the assigned lane.

Workers receive the execution manifest path plus the selected task section from the phase plan. They should not read the whole phase plan unless the assigned task section is missing or ambiguous. If extra plan context is required, read only the specific referenced section and record why in the worker result.

Workers are dispatched with the worker agent specified by the manifest when that agent is repo-approved by the current plan, repo instructions, or installed local skills. Otherwise use `general-purpose worker`. Ignore legacy custom-agent routing in old plans, manifests, or prompts unless confirmed by current repo instructions. Do not request, invent, or switch to unapproved repo-specific implementation agent roles. If blocked by setup, dependency, runtime, environment, or workflow-state issues, report the blocker clearly and let the orchestrator decide whether to dispatch a blocker-resolver.

Workflow instructions are not product requirements. Workers must never add smoke-test steps, reviewer instructions, local setup notes, acceptance checklist text, agent prompts, handoff language, or internal QA guidance to product UI, API responses, seed user-facing content, generated demo content, or runtime assets. If a task asks for product help/onboarding copy, write it as end-user product copy only; do not expose implementation workflow language.

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
4. Orchestrator or reviewer approves the tests.
5. Worker implements only after test approval.
6. Worker runs focused tests and required integration/E2E checks.
7. Worker writes or returns worker result YAML.

For low-risk isolated behavior, the orchestrator may allow inline test-first implementation in one worker goal. The worker must still write tests before production code, show the expected failing test or explain why a pre-implementation failure was not practical, and return enough evidence for reviewer validation.

For docs, config, or mechanical changes where TDD is not meaningful, replace test-first with the smallest meaningful validation command and explain why.

## Test Proposal Result

Return compact YAML or a compact message containing:

```yaml
status: test_proposed
task: "Task N"
execution_manifest: "docs/implementation-runs/<run-id>/manifests/<phase>.yaml"
worker_agent: "<manifest worker agent or general-purpose worker>"
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

If the proposed tests use mocks, fixtures, generated data, fake services, or placeholder handlers, `mock_or_fixture_disclosure` must name the fake, its scope, why it is acceptable for the test proposal, and whether it is expected to create a `mock_fixture_ledger` entry after implementation.

Blockers must include a classification and evidence artifact when possible:

```yaml
blockers:
  - id: "blocker-task-4-runtime-tool"
    classification: "setup_dependency" # setup_dependency | runtime_dependency | env_config | secret_or_account | external_service | product_decision | workflow_state
    summary: "kind is not installed"
    artifact: "docs/qa/artifacts/<phase>/task-4-kind-probe.txt"
    attempted:
      - "command -v kind"
    suggested_owner: "blocker-resolver"
```

## Implementation Result

After approved tests pass, return worker result YAML as described in `state-files.md`.

The result must include:

- files changed;
- commands run;
- pass/fail result;
- worker agent used, matching the manifest or `general-purpose worker` fallback;
- service-wiring rows covered;
- real dependencies used;
- mocks or fixtures used, with ledger-ready fields: name, kind, scope, affected paths, service-wiring rows, disposition, acceptable reason, conversion task if any, and evidence path;
- residual risk;
- lesson candidate when the worker found a recurring, proven, repo-specific problem;
- recommended downstream plan edits;
- blockers or escalations.
- secret handling fields from `$secrets` when secret material changed.
- compact event log path when the worker wrote `events/worker-<lane>-<timestamp>.jsonl`.

## Restrictions

- Do not broaden scope.
- Do not invent, request, or switch to an unapproved repo-specific implementation agent role.
- Do not read or paste the whole phase plan by default; use the selected task section and manifest.
- Do not rewrite the phase plan unless assigned.
- Do not update `run.yaml` or `phase.yaml` unless assigned.
- Do not place workflow-only smoke/review/setup/handoff/acceptance instructions in runtime app surfaces. Store that guidance only in worker results, handoffs, QA artifacts, acceptance packets, transition YAML, or developer docs.
- Do not hide failing tests.
- Do not satisfy service wiring with mocks when real wiring is required; if a mock/fixture/fake is useful during implementation, disclose it and make sure it can be reconciled by the orchestrator's mock/fixture ledger.
- Do not spawn other agents.
- Do not call local setup friction a human blocker. Missing dev tools, stale installs, local runtime setup, generated files, migrations, ports, and non-secret env config should be reported as blocker-resolver candidates.
- Do not generate, write, reveal, hide, stage, or commit secret material without following `$secrets`.

## Lesson Candidates

Workers may suggest a lesson, but they do not write repo lessons or edit `AGENTS.md`.

Suggest `lesson_candidate` only when the problem appears reusable beyond this one task, the fix is proven by the current work, and the evidence path is available. Do not suggest lessons for one-off typos, obvious mistakes, or speculative preferences.
