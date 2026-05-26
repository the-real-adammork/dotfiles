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

## Template

```markdown
# <Feature> Implementation Phases

**Technical Design:** `<path-to-technical-design>`
**Requirements:** `<path-to-requirements>` or `Not provided`
**Status:** Draft | Approved | Plans Generated | Reviewed
**Last Updated:** YYYY-MM-DD

---

## Phase Proposal

| Phase | Goal | Builds On | App Surface Included | Smoke Test | Planned Output |
| --- | --- | --- | --- | --- | --- |
| <name> | <testable increment> | <phase or none> | <UI/API/CLI/jobs/data touched together> | <primary smoke test> | `docs/plans/YYYY-MM-DD-<feature>-phase-<n>.md` |

## Coverage Check

| Technical Design Section | Covered By Phase(s) | Notes |
| --- | --- | --- |
| `<section>` | `<phase>` | <coverage note> |

## Phase Breakup Review

| Finding | Severity | Recommendation | Disposition |
| --- | --- | --- | --- |
| <finding or "None"> | High/Medium/Low | <recommendation> | Accepted/Revised/Rejected/Deferred |

Review artifact: `docs/plans/reviews/YYYY-MM-DD-<feature>-phase-breakup-review.md`

## Approved Phase Boundaries

| Phase | Final Smoke-Testable Outcome | Builds On | Later Phases Can Assume | Out Of Scope | Plan Document |
| --- | --- | --- | --- | --- | --- |
| <name> | <working behavior> | <dependency> | <verified capability> | <excluded work> | `docs/plans/YYYY-MM-DD-<feature>-phase-<n>.md` |

## Execution Order

1. <phase>
2. <phase>

## Deferred Work

- <deferred work or "None">

## Generated Implementation Plans

- `docs/plans/YYYY-MM-DD-<feature>-phase-<n>.md` - <phase goal>
```

Before user approval, `Approved Phase Boundaries` and `Generated Implementation Plans` may show planned paths. After plans are generated, update them with final paths.

## User Proposal Summary

Present this summary to the user before generating plan documents:

```markdown
## Proposed Implementation Plan Phases

| Phase | Goal | Builds On | App Surface Included | Smoke Test | Plan Path |
| --- | --- | --- | --- | --- | --- |
| <name> | <testable increment> | <phase or none> | <UI/API/CLI/jobs/data touched together> | <primary smoke test> | `docs/plans/YYYY-MM-DD-<feature>-phase-<n>.md` |

## Coverage Check

- Technical design sections covered:
- Sections intentionally deferred:
- Risks in this phasing:
- Horizontal stack splits avoided:

Approve these phases, or tell me what to merge/split/rename?
```

## Lifecycle Updates

- Set status to `Draft` when the phases document is first created.
- Set status to `Approved` once the user approves phase boundaries.
- Save detailed phase review artifacts under `<plan output directory>/reviews/`.
- Record only summary findings, dispositions, and review artifact links in `Phase Breakup Review`.
- Update `Approved Phase Boundaries`, `Coverage Check`, and `Execution Order` when accepted/revised findings change the phase sequence.
- After each implementation plan is created, update `Generated Implementation Plans`.
- Set status to `Plans Generated` once all plan docs exist.
- Save consolidated plan reviews and reruns under `<plan output directory>/reviews/`.
- Set status to `Reviewed` after consolidated plan review findings are resolved or explicitly deferred.
