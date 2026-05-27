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
- commands run with result and artifact path;
- E2E traces, screenshots, videos, logs, API output, DB assertions, or CLI output paths;
- mocks/fixtures/fakes still present and why they do not invalidate acceptance;
- escalations encountered and disposition;
- lessons created during the phase when they affect later phases;
- downstream assumptions later phases may rely on.

Keep this packet concise. Link evidence artifacts instead of embedding logs.

## Completion Rule

The phase owner may mark a phase complete only when:

- all required tasks are done or explicitly deferred outside the phase boundary;
- no active worker lanes remain;
- phase acceptance commands pass;
- every applicable service-wiring row has evidence;
- the acceptance packet exists and references current commits/artifacts;
- unresolved escalations are either cleared or recorded as blocking.

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
completed_at: "YYYY-MM-DDTHH:MM:SSZ"
```

Then update `run.yaml` to the next phase or `status: complete` when no phases remain.
