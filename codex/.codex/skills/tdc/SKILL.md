---
name: tdc
description: Use when the user invokes $tdc with a requirements, PRD, spec, issue, or brief path to start a guarded technical-design-cycle run.
---

# TDC

`$tdc <requirements-doc>` is a short alias for the technical design cycle with the human framing brainstorm and strict pre-draft technical decision gate enabled.

## Required Behavior

When invoked:

1. Treat the text after `$tdc` as the requirements source path or issue reference.
2. If no requirements source is provided, ask for it before proceeding.
3. Use `$technical-design-cycle` for that requirements source.
4. Save the technical design to:

   ```text
   docs/architecture/TECHNICAL_DESIGN.md
   ```

5. Run the `$technical-design-cycle` human framing brainstorm before technical decision gates.
6. Identify material technical design decision gates from the requirements, repo context, and human framing notes before spawning the design drafter.
7. Ask the user any material architecture, data, security/privacy, operations, integration, validation, or requirement-completeness questions one at a time.
8. Do not spawn the design drafter until the brainstorm and decision-gate questions are resolved or explicitly recorded as safely inferred/skipped.

## Expanded Prompt Shape

Use this intent:

```text
Use $technical-design-cycle for <requirements-doc>.

Save the technical design to docs/architecture/TECHNICAL_DESIGN.md.

Before drafting, run the human framing brainstorm: summarize the apparent product goal, target user, success signal, likely non-goals, and highest-risk assumptions in 3-5 bullets, then ask me to confirm, correct, or add missing goals, constraints, preferences, non-goals, or risks. Use that framing plus the requirements and repo context to identify material technical design decision gates. Ask me any architecture, data, security/privacy, operations, integration, validation, or requirement-completeness questions one at a time. Do not spawn the design drafter until the brainstorm and decision-gate questions are resolved or explicitly recorded as safely inferred/skipped.
```

## Notes

- This is an alias skill, not a separate workflow.
- Follow `$technical-design-cycle` for the actual lifecycle, subagents, review, specialist implementation-agent gate, and implementation-planning handoff.
- `$poe` is a separate PRD critique workflow. Run `$poe <requirements-doc>` explicitly before or beside `$tdc` only when the user asks for a panel of experts.
