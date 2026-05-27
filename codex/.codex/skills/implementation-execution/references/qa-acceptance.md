# QA Acceptance

QA automation must be stronger than human smoke testing. Phase completion requires a passing phase acceptance gate and a current acceptance packet.

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
- lessons created during the phase when they affect later phases;
- downstream assumptions later phases may rely on.

Keep this packet concise. Link evidence artifacts instead of embedding logs.

## Mock/Fixture Acceptance

Fixtures, mocks, fake services, placeholder handlers, and generated data are allowed during implementation. Phase acceptance reconciles them rather than banning them.

Before marking a phase complete, audit `phase.yaml` `mock_fixture_ledger` against the plan's service-wiring matrix and the acceptance evidence.

Run a lightweight repository scan before acceptance to catch untracked fake usage. Use the repo's fastest search tool, normally `rg`, and save the short summary as a QA artifact:

```sh
rg -n --hidden --glob '!node_modules' --glob '!.git' --glob '!docs/qa/artifacts/**' --glob '!docs/implementation-runs/**' 'mock|fixture|fake|stub|noop|no-op|placeholder|TODO.*real|temporary.*fake|fixture-only|disabled network' .
```

The orchestrator must review matches that touch runtime code, service wiring, E2E acceptance evidence, or production/dev configuration. Each relevant match must either already appear in `mock_fixture_ledger` or be added with a valid disposition before acceptance. It is acceptable for the artifact to contain irrelevant test helper matches as long as the packet summarizes why they are not runtime/service-wiring fakes.

Every ledger entry must be one of:

- `test-only`: it is not used by production/dev runtime completion evidence.
- `intentional-phase-boundary`: the phase explicitly delivers fixture-backed behavior.
- `converted`: real integration replaced the fake and acceptance evidence proves the real path.
- `deferred-with-conversion-task`: a named later phase/task owns the conversion.
- `blocked`: an allowed escalation prevents real verification and the phase remains blocked unless the plan scope explicitly permits completion without that boundary.

Acceptance fails when:

- a discovered runtime fake is missing from the ledger;
- the mock/fixture audit scan was not run or has unreviewed relevant matches;
- any ledger entry is `unresolved`;
- a service-wiring row claims real coverage with mock-only evidence;
- a runtime fake is marked `test-only`;
- a deferred fake has no concrete conversion task;
- a blocked fake lacks an allowed escalation;
- acceptance packet omits the mock/fixture ledger.

## Completion Rule

The orchestrator may mark a phase complete only when:

- all required tasks are done or explicitly deferred outside the phase boundary;
- no active worker lanes remain;
- phase acceptance commands pass;
- every applicable service-wiring row has evidence;
- mock/fixture audit scan has run and all relevant matches are reconciled into the ledger or dismissed with a short reason in the acceptance packet;
- every mock/fixture ledger entry has an acceptable disposition and no service-wiring row relies on mock-only evidence unless the phase boundary explicitly allows fixture-backed behavior;
- the acceptance packet exists and references current commits/artifacts;
- unresolved escalations are either cleared or recorded as blocking.
- the accepted phase commit is resolved with `/usr/bin/git rev-parse HEAD^{commit}`, validates as a full 40-character commit hash, and exists on the phase branch.

After acceptance passes, update `phase.yaml` immediately:

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
  mock_fixture_ledger_status: reconciled
completed_at: "YYYY-MM-DDTHH:MM:SSZ"
```

Then write `request.type: phase_completion` to the supervisor inbox with the `phase.yaml`, acceptance packet, and accepted phase commit/artifact pointers. The commit must be a quoted full hash generated by Git, not an abbreviated or manually typed value:

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
  commit: "<40-character accepted phase commit>"
```

The supervisor verifies the transition gate, fast-forwards the phase branch into the run base branch, records the resulting base commit, and only then updates `run.yaml` to the next phase or `status: complete` when no phases remain.
