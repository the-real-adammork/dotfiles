# Slices Document

Use this reference when creating or updating the implementation slices document.

The slices document should stay concise. For four slices it should usually be about 70-140 lines. It is the contract between the technical design and the per-slice implementation plans, not a second technical design.

Default path:

```text
docs/plans/YYYY-MM-DD-<feature>-implementation-slices.md
```

Default review artifact directory:

```text
docs/plans/reviews/
```

For a custom plan output directory, put review artifacts in `<plan output directory>/reviews/`.

## Template

```markdown
# <Feature> Implementation Slices

**Technical Design:** `<path-to-technical-design>`
**Requirements:** `<path-to-requirements>` or `Not provided`
**Status:** Draft | Approved | Plans Generated | Reviewed
**Last Updated:** YYYY-MM-DD

---

## Slice Proposal

| Slice | Goal | Owns | Depends On | Verification | Planned Output |
| --- | --- | --- | --- | --- | --- |
| <name> | <testable outcome> | <files/modules/surfaces> | <slice or none> | <primary checks> | `docs/plans/YYYY-MM-DD-<feature>-<slice>.md` |

## Coverage Check

| Technical Design Section | Covered By Slice(s) | Notes |
| --- | --- | --- |
| `<section>` | `<slice>` | <coverage note> |

## Slice Breakup Review

| Finding | Severity | Recommendation | Disposition |
| --- | --- | --- | --- |
| <finding or "None"> | High/Medium/Low | <recommendation> | Accepted/Revised/Rejected/Deferred |

Review artifact: `docs/plans/reviews/YYYY-MM-DD-<feature>-slice-breakup-review.md`

## Approved Slice Boundaries

| Slice | Final Scope | Out Of Scope | Dependencies | Plan Document |
| --- | --- | --- | --- | --- |
| <name> | <final scope> | <excluded work> | <dependencies> | `docs/plans/YYYY-MM-DD-<feature>-<slice>.md` |

## Execution Order

1. <slice>
2. <slice>

## Deferred Work

- <deferred work or "None">

## Generated Implementation Plans

- `docs/plans/YYYY-MM-DD-<feature>-<slice>.md` - <slice goal>
```

Before user approval, `Approved Slice Boundaries` and `Generated Implementation Plans` may show planned paths. After plans are generated, update them with final paths.

## User Proposal Summary

Present this summary to the user before generating plan documents:

```markdown
## Proposed Implementation Plan Slices

| Slice | Goal | Owns | Depends On | Verification | Plan Path |
| --- | --- | --- | --- | --- | --- |
| <name> | <testable outcome> | <files/modules/surfaces> | <slice or none> | <primary checks> | `docs/plans/YYYY-MM-DD-<feature>-<slice>.md` |

## Coverage Check

- Technical design sections covered:
- Sections intentionally deferred:
- Risks in this split:

Approve these slices, or tell me what to merge/split/rename?
```

## Lifecycle Updates

- Set status to `Draft` when the slices document is first created.
- Set status to `Approved` once the user approves slice boundaries.
- Save detailed slice review artifacts under `<plan output directory>/reviews/`.
- Record only summary findings, dispositions, and review artifact links in `Slice Breakup Review`.
- Update `Approved Slice Boundaries`, `Coverage Check`, and `Execution Order` when accepted/revised findings change the split.
- After each implementation plan is created, update `Generated Implementation Plans`.
- Set status to `Plans Generated` once all plan docs exist.
- Save consolidated plan reviews and reruns under `<plan output directory>/reviews/`.
- Set status to `Reviewed` after consolidated plan review findings are resolved or explicitly deferred.
