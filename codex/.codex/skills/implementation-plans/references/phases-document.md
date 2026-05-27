# Phases Document

Use this reference when creating or updating the implementation phases document.

The phases document should stay concise. For four phases it should usually be about 80-160 lines. It is the contract between the technical design and the per-phase implementation plans, not a second technical design.

Default path:

```text
docs/plans/YYYY-MM-DD-<feature>-implementation-phases.md
```

Default review artifact directory:

```text
docs/plans/reviews/
```

For a custom plan output directory, put review artifacts in `<plan output directory>/reviews/`.

Default HTML approval preview path:

```text
docs/plans/YYYY-MM-DD-<feature>-implementation-phases.html
```

Generate the HTML preview from the markdown phases document with `pandoc`, which is Homebrew-installable:

```sh
pandoc --from=gfm --to=html5 --standalone --metadata title="<Feature> Implementation Phases" -o docs/plans/YYYY-MM-DD-<feature>-implementation-phases.html docs/plans/YYYY-MM-DD-<feature>-implementation-phases.md
```

If `pandoc` is unavailable, stop before requesting phase approval and tell the human to install it:

```sh
brew install pandoc
```

After installation, rerun the phases-document preview step.

## Template

```markdown
# <Feature> Implementation Phases

**Technical Design:** `<path-to-technical-design>`
**Requirements:** `<path-to-requirements>` or `Not provided`
**Status:** Draft | Ready | Plans Generated | Reviewed
**Last Updated:** YYYY-MM-DD

---

## Phase Proposal

| Phase | Goal | Builds On | Phase Owner Scope | Sub-Agent Lanes | App Surface Included | Smoke Test | Service Wiring | E2E Readiness | Phase Acceptance Automation | Acceptance Packet | Planned Output |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <name> | <testable increment> | <phase or none> | <long-running owner responsibility> | <parallel/serialized lanes> | <UI/API/CLI/jobs/data touched together> | <primary smoke test> | <surface/service/persistence/jobs/integrations to prove> | <existing harness or early setup needed> | <Playwright/simulator/CLI/service harness> | `docs/qa/phase-acceptance/...md` | `docs/plans/YYYY-MM-DD-<feature>-phase-<n>.md` |

## Coverage Check

| Technical Design Section | Covered By Phase(s) | Notes |
| --- | --- | --- |
| `<section>` | `<phase>` | <coverage note> |

## Phase Breakup Review

| Finding | Severity | Recommendation | Disposition |
| --- | --- | --- | --- |
| <finding or "None"> | High/Medium/Low | <recommendation> | Accepted/Revised/Rejected/Deferred |

Review artifact: `docs/plans/reviews/YYYY-MM-DD-<feature>-phase-breakup-review.md`

## Ready Phase Boundaries

| Phase | Final Smoke-Testable Outcome | Phase Owner Scope | Sub-Agent Lanes | Service Wiring | E2E Readiness | Phase Acceptance Automation | Acceptance Packet | Builds On | Later Phases Can Assume | Out Of Scope | Plan Document |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <name> | <working behavior> | <long-running owner responsibility> | <parallel/serialized lanes> | <matrix summary> | <harness/setup expectation> | <platform harness and command intent> | <packet path> | <dependency> | <verified capability> | <excluded work> | `docs/plans/YYYY-MM-DD-<feature>-phase-<n>.md` |

## Execution Order

1. <phase>
2. <phase>

## Deferred Work And Escalations

- <deferred work, allowed escalation, or "None">

## HTML Approval Preview

- HTML file: `docs/plans/YYYY-MM-DD-<feature>-implementation-phases.html`
- Local review URL: `http://127.0.0.1:<port>/YYYY-MM-DD-<feature>-implementation-phases.html`
- Generated with: `pandoc --from=gfm --to=html5 --standalone ...`
- Server command: `python3 -m http.server <port> --bind 127.0.0.1 --directory docs/plans`

## Generated Implementation Plans

- `docs/plans/YYYY-MM-DD-<feature>-phase-<n>.md` - <phase goal>
```

Before phase boundaries are ready, `Ready Phase Boundaries` and `Generated Implementation Plans` may show planned paths. After phase boundaries are reviewed and patched, generate the HTML approval preview and populate `HTML Approval Preview` before asking for approval. After plans are generated, update `Generated Implementation Plans` with final paths.

## Proposal Summary

Present this summary before generating plan documents when the user asks for a planning checkpoint. If the user has delegated autonomous planning, record assumptions and proceed once High/Medium phase issues are resolved or explicitly deferred with rationale.

```markdown
## Proposed Implementation Plan Phases

| Phase | Goal | Builds On | Phase Owner Scope | Sub-Agent Lanes | App Surface Included | Smoke Test | Service Wiring | E2E Readiness | Phase Acceptance Automation | Acceptance Packet | Plan Path |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <name> | <testable increment> | <phase or none> | <long-running owner responsibility> | <parallel/serialized lanes> | <UI/API/CLI/jobs/data touched together> | <primary smoke test> | <surface/service/persistence/jobs/integrations to prove> | <existing harness or early setup needed> | <Playwright/simulator/CLI/service harness> | `docs/qa/phase-acceptance/...md` | `docs/plans/YYYY-MM-DD-<feature>-phase-<n>.md` |

## Coverage Check

- Technical design sections covered:
- Sections intentionally deferred:
- Risks in this phasing:
- Horizontal stack splits avoided:
- Long-running phase ownership:
- Sub-agent lanes and serialized resources:
- Phase acceptance automation:
- Acceptance packet expectations:
```

## Lifecycle Updates

- Set status to `Draft` when the phases document is first created.
- Keep status as `Draft` while phase boundaries are being generated, reviewed, and patched.
- Set status to `Ready` only after phase boundaries have passed phase breakup review and the user has explicitly approved the phases document.
- Do not create individual phase plan documents while the phases document is still `Draft`.
- Before requesting phase approval, generate the HTML approval preview and serve it on localhost so the human can review the phase sequence in a browser.
- Save detailed phase review artifacts under `<plan output directory>/reviews/`.
- Record only summary findings, dispositions, and review artifact links in `Phase Breakup Review`.
- Update `Ready Phase Boundaries`, `Coverage Check`, and `Execution Order` when accepted/revised findings change the phase sequence.
- After each implementation plan is created, update `Generated Implementation Plans`.
- Set status to `Plans Generated` once all plan docs exist.
- Save consolidated plan reviews and reruns under `<plan output directory>/reviews/`.
- Set status to `Reviewed` after consolidated plan review findings are resolved or explicitly deferred.
