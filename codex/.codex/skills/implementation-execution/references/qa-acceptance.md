# QA Acceptance

QA automation must be stronger than human smoke testing. Phase completion requires a passing phase acceptance gate and a current acceptance packet. The phase acceptance gate is run by a delegated general-purpose acceptance worker/agent, not inline by the orchestrator.

The orchestrator dispatches this worker after all manifest tasks are integrated and no active worker lanes remain. The acceptance worker owns acceptance commands, audits, packet writing, transition handoff/report drafting, and compact acceptance result output. The orchestrator only validates the returned result, updates lifecycle state, and routes `phase_completion`.

## Platform Automation

- Web: Playwright browser flow, network assertions, visible UI result, API side effects, DB assertions, traces/screenshots/videos.
- Mobile/app: simulator automation, persisted state checks, app logs.
- Backend/API: end-to-end service/API tests with real dependencies and persistence assertions.
- CLI/TUI: end-to-end process/session tests against realistic files/services.
- Worker/jobs: queue/job execution against local containers, emulators, or dev/staging services with observable side effects.

## Service Wiring

Every service-wiring matrix row must have evidence:

- user/runtime surface;
- API/service path;
- persistence effect;
- job/queue/event effect when applicable;
- external/local integration effect when applicable;
- artifact path proving the behavior.

## Acceptance Packet

Default path:

```text
docs/qa/phase-acceptance/<phase-slug>.md
```

Contents:

- phase plan path and phase name;
- implementation commit range or task commit list;
- smoke-testable outcome;
- service wiring matrix with evidence path for each covered row;
- mock/fixture ledger with disposition for each tracked mock, fixture, fake service, placeholder, or generated data source that affects runtime behavior, service wiring, or acceptance evidence;
- commands run with result and artifact path;
- E2E traces, screenshots, videos, logs, API output, DB assertions, or CLI output paths;
- mocks/fixtures/fakes still present and why they do not invalidate acceptance;
- secret handling verification for any generated or changed secret material, following `$secrets`;
- escalations encountered and disposition;
- blocker-resolver attempts and disposition for any setup, dependency, runtime, env, workflow-state, or external dependency blocker;
- lessons created during the phase when they affect later phases;
- downstream assumptions later phases may rely on.

Keep this packet concise. Link evidence artifacts instead of embedding logs.

## Runtime Content Boundary

Smoke-test instructions, reviewer instructions, local setup steps, acceptance checklists, implementation prompts, agent handoff text, and internal QA notes are workflow artifacts. They must not be shipped as product UI copy, API response text, generated demo content, user-facing seed data, routes/pages, tooltips, banners, cards, or runtime assets unless the phase plan explicitly requires end-user help/onboarding content.

This boundary is primarily enforced before implementation through worker goals and review. As a final safety net before marking a phase complete, run a lightweight scan for workflow-only language in runtime app files and save the summary as a QA artifact. Tune the include/exclude globs to the repo, but exclude workflow docs and generated QA artifacts:

```sh
rg -n --hidden \
  --glob '!node_modules/**' --glob '!.git/**' \
  --glob '!docs/implementation-runs/**' --glob '!docs/qa/**' \
  --glob '!*.log' \
  'smoke[- ]?test|reviewer instructions|review instructions|handoff|acceptance checklist|local setup|localhost|phase completion|phase[- ]transition|supervisor|orchestrator|agent prompt|implementation workflow' .
```

The acceptance worker must review matches in runtime code, UI templates/components, API response builders, seed data, fixtures used as product/demo content, generated app assets, and app-visible markdown. Matches are allowed only when they are test-only, developer-only, or genuine end-user product help explicitly required by the phase plan. Otherwise acceptance fails and the text must move to the phase-transition handoff/report, QA artifact, acceptance packet, or developer docs.

## Mock/Fixture Acceptance

Fixtures, mocks, fake services, placeholder handlers, and generated data are allowed during implementation. Phase acceptance reconciles them rather than banning them.

Before marking a phase complete, audit `phase.yaml` `mock_fixture_ledger` against the plan's service-wiring matrix and the acceptance evidence.

Run a lightweight repository scan before acceptance to catch untracked fake usage. Use the repo's fastest search tool, normally `rg`, and save the short summary as a QA artifact:

```sh
rg -n --hidden --glob '!node_modules' --glob '!.git' --glob '!docs/qa/artifacts/**' --glob '!docs/implementation-runs/**' 'mock|fixture|fake|stub|noop|no-op|placeholder|TODO.*real|temporary.*fake|fixture-only|disabled network' .
```

The acceptance worker must review matches that touch runtime code, service wiring, E2E acceptance evidence, or production/dev configuration. Each relevant match must either already appear in `mock_fixture_ledger` or be returned to the orchestrator as a required ledger update before acceptance can pass. It is acceptable for the artifact to contain irrelevant test helper matches as long as the packet summarizes why they are not runtime/service-wiring fakes.

Every ledger entry must be one of:

- `test-only`: it is not used by production/dev runtime completion evidence.
- `intentional-phase-boundary`: the phase explicitly delivers fixture-backed behavior.
- `converted`: real integration replaced the fake and acceptance evidence proves the real path.
- `deferred-with-conversion-task`: a named later phase/task owns the conversion.
- `blocked`: an allowed escalation prevents real verification and the phase remains blocked unless the plan scope explicitly permits completion without that boundary.
- `blocked` entries require a blocker-resolver result unless the blocker is immediately and obviously human-only, such as missing private credentials or a product/legal decision.

Acceptance fails when:

- a discovered runtime fake is missing from the ledger;
- the mock/fixture audit scan was not run or has unreviewed relevant matches;
- any ledger entry is `unresolved`;
- a service-wiring row claims real coverage with mock-only evidence;
- a runtime fake is marked `test-only`;
- a deferred fake has no concrete conversion task;
- a blocked fake lacks an allowed escalation and blocker-resolver result;
- acceptance packet omits the mock/fixture ledger.

## Blocker Acceptance

Acceptance commands that fail because of local setup, missing tools, non-secret env config, runtime services, containers, generated files, local ports, or workflow-state issues are not accepted blockers by themselves. The acceptance worker must return a blocker classification and artifact; the orchestrator must dispatch a blocker-resolver before recording the dependency as allowed or blocking.

Phase acceptance may pass with an unresolved dependency boundary only when all are true:

- the phase plan explicitly allows completion with that boundary unresolved, or the unresolved dependency is outside the phase's deliverable;
- a blocker-resolver result exists under `docs/implementation-runs/<run-id>/blockers/`;
- the resolver attempted reasonable agent-owned setup or explains why no safe setup attempt exists;
- the resolver classifies the issue as a true blocker requiring human action, external access, paid/vendor setup, private credentials, unavailable hardware, external service availability, or another allowed escalation;
- the acceptance packet names the exact retry command after the human resolves it.

This prevents cases such as missing `kind`, `minikube`, Playwright browsers, test CLIs, generated files, safe local env variables, or container setup from being accepted as human blockers before an agent has tried to fix them.

## Completion Rule

The acceptance worker may return `accepted` only when:

- all required tasks are done or explicitly deferred outside the phase boundary;
- no active worker lanes remain;
- phase acceptance commands pass;
- every applicable service-wiring row has evidence;
- mock/fixture audit scan has run and all relevant matches are reconciled into the ledger or dismissed with a short reason in the acceptance packet;
- workflow-only runtime content audit has run and no smoke/review/setup/handoff instructions remain in product UI, API responses, seed user-facing content, generated demo content, or runtime assets;
- every mock/fixture ledger entry has an acceptable disposition and no service-wiring row relies on mock-only evidence unless the phase boundary explicitly allows fixture-backed behavior;
- the acceptance packet exists and references current commits/artifacts;
- unresolved escalations are either cleared or recorded as blocking.
- every accepted blocker has a blocker-resolver result or is immediately human-only under the escalation policy.
- the accepted phase commit is resolved with `/usr/bin/git rev-parse HEAD^{commit}`, validates as a full 40-character commit hash, and exists on the phase branch.

After the acceptance worker returns `accepted`, the orchestrator validates the result and updates `phase.yaml` immediately:

```yaml
status: complete
acceptance:
  status: passed
  packet: "docs/qa/phase-acceptance/<phase-slug>.md"
  commands:
    - command: "<acceptance command>"
      result: pass
      artifact: "docs/qa/artifacts/<phase>/<artifact>"
    - command: "rg -n --hidden ... 'mock|fixture|fake|stub|noop|no-op|placeholder|TODO.*real|temporary.*fake|fixture-only|disabled network' ."
      result: pass
      artifact: "docs/qa/artifacts/<phase>/mock-fixture-audit.txt"
    - command: "rg -n --hidden ... 'smoke[- ]?test|reviewer instructions|review instructions|handoff|acceptance checklist|local setup|localhost|phase completion|phase[- ]transition|supervisor|orchestrator|agent prompt|implementation workflow' ."
      result: pass
      artifact: "docs/qa/artifacts/<phase>/runtime-workflow-copy-audit.txt"
  mock_fixture_ledger_status: reconciled
  blockers:
    - id: "blocker-001"
      status: true_blocker
      resolver_result: "docs/implementation-runs/<run-id>/blockers/blocker-001.yaml"
      accepted_as_allowed_boundary: true
completed_at: "YYYY-MM-DDTHH:MM:SSZ"
```

The acceptance worker must also write the phase-transition handoff/report with local run instructions, seeded local admin access instructions for login-gated smoke tests, and smoke-test expectations. The orchestrator then writes `request.type: phase_completion` to the supervisor inbox with the `phase.yaml`, acceptance packet, transition handoff/report, and accepted phase commit/artifact pointers. The commit must be a quoted full hash generated by Git, not an abbreviated or manually typed value:

```sh
accepted_commit="$(/usr/bin/git rev-parse HEAD^{commit})"
printf '%s\n' "$accepted_commit" | rg --quiet '^[0-9a-f]{40}$'
/usr/bin/git cat-file -e "$accepted_commit^{commit}"
```

```yaml
request:
  type: phase_completion
phase_completion:
  phase_yaml: "docs/implementation-runs/<run-id>/phases/<phase-slug>.yaml"
  acceptance_packet: "docs/qa/phase-acceptance/<phase-slug>.md"
  transition_handoff: "docs/implementation-runs/<run-id>/handoffs/<phase-slug>-transition.md"
  commit: "<40-character accepted phase commit>"
```

After writing the phase-completion request, the orchestrator must stop at accepted phase state. It may leave the pane idle or request graceful exit, but it must not report final run status, merge or reconcile the base branch, launch local verification, or start the next phase.

The supervisor transition router verifies the routing gate and delegates context-heavy merge work to a native phase-merge sub-agent. The merge sub-agent verifies the transition gate, reads the transition handoff/report, merges or reconciles the phase branch into the run base branch, records the resulting base commit and any merge decisions in `transitions/<phase>.yaml`, and returns a compact result to the supervisor. The supervisor stops the completed orchestrator pane/session, marks the phase-completion trigger handled, updates only minimal `run.yaml` pointers/status, starts the next phase orchestrator/watchdog from the updated base branch when another phase remains, then spawns the post-advance phase-transition sub-agent. The transition sub-agent runs local verification setup from the handoff/report, writes the smoke-test report artifact, records local verification state in `transitions/<phase>.yaml`, and returns a compact result to the supervisor to print the localhost URL and smoke-test checklist while the next phase continues running.
