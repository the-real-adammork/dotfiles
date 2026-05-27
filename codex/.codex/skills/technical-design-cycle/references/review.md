# Technical Design Review Reference

Use this reference to review a technical design against the requirements document it was created from. The goal is traceability and sufficiency: every requirement should map to a place in the technical design, and the design decision there should be capable of satisfying the requirement completely at the design level.

## Start

Read both documents:

- Requirements source: PRD, spec, issue, approved brief, or user-provided requirements.
- Technical design: the design/strategy document being reviewed.

If either document path is missing and cannot be inferred, ask for the missing path.

## Context Budget

Keep source documents as files. Do not paste full requirements or full technical designs into the conversation unless the user asks.

If the review has more than about 20 requirement units, or the traceability table would be too large for a concise response, write the full review to:

```text
docs/reviews/YYYY-MM-DD-<feature>-technical-design-review.md
```

Then return only:

- review file path;
- top findings;
- coverage counts;
- whether anything blocks approval.

## Review Standard

For each requirement section or paragraph:

- Identify the requirement in your own words.
- Find the exact section, heading, table row, bullet, or paragraph in the technical design that addresses it.
- Verify the design decision is capable of satisfying the requirement to completeness.
- Do not require task-level implementation detail. A technical design can pass if the architecture, responsibility boundary, data/control flow, or integration decision is sufficient to support the requirement.
- Mark a gap when the design omits the requirement, contradicts it, delegates it to an unclear owner, or proposes an approach that cannot fully satisfy it.

For designs that touch authentication, authorization, secrets, credentials, deployment, databases, external services, or environment configuration, also verify:

- the design states project posture: `side-project/greenfield`, `internal/demo`, or `production/customer`;
- the design follows `$secrets` for generated-vs-human credentials, storage, `git-secret`, masking, ignored plaintext, and no plaintext staging;
- the design does not unnecessarily block on human-provided secrets that `$secrets` allows the agent to generate for the selected posture.

## Coverage Levels

Use exactly these labels:

- `Covered` - the design clearly provides a viable strategy for the full requirement.
- `Partially Covered` - the design addresses the requirement, but leaves an important part unsupported or ambiguous.
- `Missing` - no meaningful design coverage found.
- `Inconsistent` - the design conflicts with the requirement or with another design section.
- `Out Of Scope` - the requirements source explicitly allows this requirement to be excluded from the current design.

Do not use `Covered` just because a keyword appears. The design text must describe a relevant responsibility, flow, interface, state shape, constraint, or decision.

## Method

1. Split the requirements document into review units. Prefer headings and paragraphs. For dense bullet lists, treat each bullet as its own unit.
2. Review units in source order. Do not skip low-level or awkward requirements.
3. For each unit, search the technical design for the specific decision that handles it.
4. Record the best matching design location and a short sufficiency judgment.
5. After all units are reviewed, summarize cross-cutting problems, contradictions, and recommended design edits.

## Output Format

Lead with findings, then the traceability table.

```markdown
## Findings

- [Severity] <gap or inconsistency>. Requirement: `<source heading or short quote>`. Design location: `<heading or "none">`. Recommendation: <specific design edit>.

## Traceability Review

| Requirement | Design Location | Coverage | Sufficiency Judgment |
| --- | --- | --- | --- |
| <source section/paragraph summary> | <design heading/bullet/paragraph> | Covered | <why the design can satisfy it> |
| <source section/paragraph summary> | None | Missing | <what is absent> |

## Summary

- Covered: <count>
- Partially Covered: <count>
- Missing: <count>
- Inconsistent: <count>
- Out Of Scope: <count>

## Recommended Design Changes

1. <Concrete edit to the technical design document>
2. <Concrete edit to the technical design document>
```

If there are no findings, say so clearly and still provide the traceability table and counts.

For file-based reviews, the saved review must use the same output format. The chat response should summarize rather than duplicate the full table.

## Severity

Use severity only for findings:

- `High` - a core requirement is missing, contradicted, or impossible under the proposed design.
- `Medium` - a requirement is only partially supported or ownership/integration is too ambiguous to trust.
- `Low` - wording, traceability, or minor design clarity issue that should be tightened before task planning.

For secret policy findings:

- `High` - design would commit unsafe plaintext secrets, rely on mock security for real environments, or let agents generate credentials with real account/customer/billing/funds authority.
- `Medium` - design omits project posture, omits secret storage/handling, or unnecessarily escalates side-project secrets that agents should generate.
- `Low` - wording around generated secret handling is unclear but the posture and owner are otherwise safe.

## Self-Review

Before delivering the review:

- Confirm every requirement unit appears in the traceability table.
- Confirm every `Covered` row names a concrete design location.
- Confirm every `Partially Covered`, `Missing`, or `Inconsistent` row has a recommended design edit.
- Confirm you did not demand task-level detail when a high-level design decision is enough.
- Confirm secret/environment posture is reviewed when relevant.
