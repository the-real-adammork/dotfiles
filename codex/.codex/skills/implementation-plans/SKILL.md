---
name: implementation-plans
description: "Use when the user wants the implementation planning workflow: turn specs, requirements, issues, or approved technical designs into concrete implementation plan documents; decompose large work into sequential smoke-testable phase plans; or reconcile same-plan/cross-plan instructions after completed implementation work."
---

# Implementation Plans

Coordinate the complete implementation-planning workflow through one public skill. The source-of-truth instructions for each planning mode live in bundled references under this skill.

## Start

Announce: "I'm using the implementation-plans skill to coordinate the planning workflow."

Before writing or updating plans, inspect the repo enough to know existing patterns, commands, test setup, and relevant files. Use `/usr/bin/git` when git is needed.

## Bundled References

Load only the reference needed for the current planning mode:

- `references/plan-writing.md` - write one concrete implementation plan from a spec, requirements document, issue, approved design, or ready phase, including the long-running phase-owner and sub-agent execution contract.
- `references/phasing.md` - decompose an approved technical design into sequential smoke-testable phase plans, with phase proposal, long-running phase ownership, sub-agent lane planning, review, plan-writing agents, and consolidated review.
- `references/phases-document.md` - required format and lifecycle for the phase-planning workflow's phases document.
- `references/planning-agent-prompts.md` - required prompts and return contracts for phase plan-writer and consolidated-review planning agents.
- `references/task-consistency.md` - update future inactive tasks in one implementation plan after one or more completed tasks changed reality.
- `references/cross-plan-consistency.md` - update upcoming implementation plans after a completed plan changed APIs, schemas, behavior, ownership boundaries, verification commands, or sequencing assumptions.

## Mode Selection

Use `references/plan-writing.md` when:

- The user asks for a concrete implementation plan from a single spec, issue, requirements document, or approved design.
- The work is one coherent smoke-testable phase and does not need multiple plan documents.
- A phase-plan writer is assigned exactly one ready phase and one output plan document.

Use `references/phasing.md` when:

- The user has an approved technical design that needs decomposition into one or more detailed implementation plan documents.
- The project should come to life over time through sequential vertical increments that build on each other.
- The user asks to split, phase, decompose, or create multiple implementation plans from a design.

Use `references/task-consistency.md` when:

- One or more tasks in a single implementation plan completed and later inactive tasks may now be inaccurate, redundant, blocked, or missing follow-up work.
- A supervisor or orchestrated execution workflow asks to reconcile future tasks in the same plan.

Use `references/cross-plan-consistency.md` when:

- A completed implementation plan changed assumptions used by upcoming implementation plan documents.
- A supervisor asks to reconcile upcoming plans after a plan branch has merged.

## Planning Agent Prompts

When dispatching plan-writing agents from the phase workflow, prompt them to use this skill and load the plan-writing reference:

```text
Use $implementation-plans and load `references/plan-writing.md` to write a detailed implementation plan for this phase only.
```

When dispatching consolidated plan-review agents from the phase workflow, prompt them to use this skill and load the relevant phase references:

```text
Use $implementation-plans and load `references/phasing.md` plus `references/planning-agent-prompts.md` to review these implementation plan documents as a set.
```

Do not dispatch or invoke standalone implementation-plan phasing or consistency skills. Those are internal modes of this skill.

## Handoff

After creating or updating plans, report the artifact paths, unresolved escalations, and the next available execution or review options. Do not begin implementation unless the user explicitly chooses an execution option.
