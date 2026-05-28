# Planning Agent Prompts

Use this reference when dispatching phase plan-writing or consolidated-review agents during planning. These prompts are for planning artifacts only; execution handoff should use the orchestrated implementation workflow with one supervisor-launched phase orchestrator per phase and bounded worker delegation inside that phase.

## Context Handoff Protocol

Every agent must self-monitor context pressure. If it estimates it is at or above roughly 70% context usage, or cannot confidently finish within remaining context, it must:

1. Stop normal work at a coherent boundary.
2. Save a handoff document under:

   ```text
   docs/handoffs/YYYY-MM-DD-<feature>-<phase-or-review>-handoff.md
   ```

3. Return only the handoff path and current artifact paths to the parent.

Handoff document template:

````markdown
# <Feature> <Phase Or Review> Handoff

**Original Goal:** <assigned agent task>
**Scope:** <phase/review scope>
**Source Documents:**
- Technical design: `<path>`
- SLICES document: `<path>`
- Requirements: `<path or "not provided">`

## Progress Made

- <completed work>

## In-Progress Documents

| Document | Status | Notes |
| --- | --- | --- |
| `<path>` | <not started/in progress/needs review> | <notes> |

## Remaining Work

1. <next concrete step>
2. <next concrete step>

## Blockers Or Decisions Needed

- <blocker or "None">

## Completion Criteria

- <what done looks like>

## Replacement Agent Prompt

```text
Continue this task from the handoff document:
<handoff path>

Use the listed source documents and artifact paths as the source of truth. Do not rely on prior chat context. Follow the original phase/review scope and finish the remaining work only.
```
````

## Plan-Writing Agent

Dispatch one planning agent per ready phase in the current unblocked dependency frontier that lacks a valid output plan. Prefer parallel dispatch within that frontier. Serialize only phases that need exact APIs, file paths, smoke-test commands, acceptance packet assumptions, service-wiring decisions, or other concrete outputs from an earlier phase plan.

After the reviewed phases document has explicit user approval, the parent workflow does not need separate approval to dispatch plan-writing agents for those approved phases. In Codex, use `tool_search` to discover available multi-agent dispatch tools before deciding dispatch tools are unavailable. If dispatch tools are unavailable, the parent should write the approved phase plans locally instead.

Each agent owns exactly one phase and one output plan document. Agents must not edit other phases' plan files, modify the technical design, or implement code.

Prompt:

```text
agent_name: phase-plan-writer: <feature-slug> / <phase-slug>

Use $implementation-plans and load `references/plan-writing.md` to write a detailed implementation plan for this phase only.

Technical design:
<path>

Implementation SLICES document:
<path>

Phase:
<phase name, goal, builds on, orchestrator scope, worker lanes, app surface included, smoke test, service wiring, E2E readiness, phase acceptance automation, acceptance packet, output path>

Requirements source:
<path or "not provided">

Constraints:
- Stay within this phase boundary.
- Carry forward the approved specialist implementation-agent roster from the design handoff or SLICES document. General-purpose implementation workers are always available.
- Do not invent or propose specialist agents. Use a specialist only when the lane clearly matches an approved roster entry; otherwise use `general-purpose worker`.
- Include the UI/API/CLI/jobs/data work needed for this phase's smoke-testable outcome.
- Include a `Phase Execution Contract` for a supervisor-launched phase orchestrator, a small worker delegation map, integration checkpoints, and handoff path.
- Include an `Implementation Execution Handoff` section that points to `$implementation-execution` state and evidence locations: `run.yaml`, `phase.yaml`, execution manifest, worker result YAML, event JSONL, acceptance packet, and QA artifact paths.
- Include a compact `Execution` line for every task so the execution workflow can distinguish orchestrator-owned orchestration/glue from bounded worker lanes without extra analysis.
- Include `Worker Agent` for every worker-owned task, naming either `general-purpose worker` or an approved specialist agent from the roster.
- Do not use ambiguous task ownership such as `orchestrator or worker`, `orchestrator or one worker`, or `orchestrator unless delegated`; choose one owner.
- Use orchestrator ownership only for orchestration, tiny glue, state, acceptance, and plan consistency work. Every orchestrator-owned task must include `Owner-Only Justification`.
- Assign substantial runtime, service/API, persistence, schema/migration, parser, frontend, E2E/integration-test, or shared-contract behavior to a worker lane even when the lane must run serially.
- Keep `Execution` parallelism consistent with `Depends On`: a task cannot be parallel with a task it depends on or with a task that depends on it. Parallel lanes that share a required sequential contract must name the handoff point in both the task and delegation map.
- Optimize for Codex efficiency: avoid tiny delegated tasks, minimize repeated context, and group related implementation work when splitting would add coordination cost without parallelism.
- When substantial work is integration-heavy, context-heavy, or unsafe to parallelize, mark it as a serial worker lane rather than orchestrator-owned work.
- For delegated behavior work, include a `TDD Approval Gate`: worker writes tests first, runs the focused test to record expected failure, returns test intent/evidence to the orchestrator, waits for orchestrator approval that tests satisfy requirements, then implements and makes the approved tests pass.
- Include `Autonomy And Escalation` and escalate only for credentials/secrets, paid/vendor setup, product/legal/security decisions, destructive production actions, real customer data access, or unavailable devices/services after an agent-owned attempt.
- Include a `Service Wiring Matrix` that names the phase flows across surface, service, persistence, jobs, and integrations.
- Include `Service Wiring Rows Covered` for every task that touches surface/service/persistence/jobs/integrations.
- Bring E2E automation in early enough to verify integrations during phase development; create a minimal harness early if none exists.
- Include a `Phase Acceptance Gate` with commands, required service-wiring coverage, acceptance packet path, and completion rule.
- Do not create a late QA-only E2E task as the enforcement point; E2E coverage should be added or extended as wiring lands.
- For web phases, use Playwright to verify browser behavior and API/service wiring unless the repo has an explicit different browser E2E standard.
- For app phases, use simulator/emulator automation appropriate to the platform.
- Use `Agent-Run Acceptance` fields for every task; do not add optional non-automated checks or manual smoke-test gates.
- Mention dependencies on earlier phases, but do not plan their tasks.
- Do not turn the phase into a horizontal backend-only or frontend-only layer unless the ready phase explicitly says the whole product increment is that layer.
- Use exact file paths and verification commands.
- Save the plan to the specified output path.
- Do not implement code.
- Do not modify other plan files.
- If the output plan already exists and appears to match this ready phase, inspect it and return its path plus a summary instead of regenerating it.
- Return only output path, phase name, 3-5 bullet summary, escalation count, blockers, and deviations from the phase boundary.
- If context pressure reaches roughly 70%, save a handoff document under `docs/handoffs/` using the Context Handoff Protocol and return only the handoff path plus current artifact paths.
```

Dispatch later phase plans after prerequisite phase plan drafts return when later phases need their exact APIs, files, smoke tests, acceptance packet assumptions, or service wiring decisions. When a prerequisite returns, recompute the unblocked dependency frontier and dispatch every now-unblocked phase-plan writer in parallel.

## Consolidated Reviewer Agent

Dispatch one reviewer after all plan-writing agents return.

Prompt:

```text
agent_name: phase-plan-reviewer: <feature-slug> / consolidated

Use $implementation-plans and load `references/phasing.md` plus this `references/planning-agent-prompts.md` reference to review these implementation plan documents as a set.

Original technical design:
<path>

Implementation SLICES document:
<path>

Plan documents:
<paths>

Requirements source:
<path or "not provided">

Review output directory:
<plan output directory>/reviews/

Check for:
- gaps between the technical design and the plan set;
- gaps between ready phases and their generated plans;
- phase boundary mismatches or duplicate work across plans;
- horizontal backend-first/frontend-later splits that prevent the app from coming to life phase by phase;
- phases too large or too vague for one phase orchestrator to maintain coherent context;
- missing or weak `Phase Execution Contract`;
- missing `Implementation Execution Handoff` for `$implementation-execution` state/manifest/event/evidence paths;
- missing task-level `Execution` lines;
- missing or invalid `Worker Agent` lines for worker-owned tasks;
- worker lanes that name specialist agents not present in the approved roster;
- ambiguous task ownership such as `orchestrator or worker`, `orchestrator or one worker`, or `orchestrator unless delegated`;
- orchestrator-owned tasks without `Owner-Only Justification`;
- orchestrator-owned tasks that contain substantial runtime, service/API, persistence, schema/migration, parser, frontend, E2E/integration-test, or shared-contract behavior;
- too many tiny delegated tasks that create coordination overhead without parallelism;
- repeated context pasted into many tasks instead of captured once in phase-level sections;
- unsafe parallelism or missing shared-resource/collision risks in worker scopes;
- `Execution` lines that mark a task parallel with a task it depends on or with a task that depends on it;
- parallel lanes that share a required sequential contract without naming the handoff point;
- missing integration checkpoints after delegated work;
- delegated behavior tasks that lack a TDD test proposal/approval gate before implementation;
- missing or unclear cross-plan dependencies;
- verification gaps;
- missing `Autonomy And Escalation` sections or escalation categories outside the allowed exception list;
- optional non-automated checks, manual smoke-test gates, or routine setup assigned outside the agent workflow;
- missing or weak `Service Wiring Matrix` coverage;
- tasks that touch service wiring but lack `Service Wiring Rows Covered`;
- missing or late E2E harness setup when integrations need E2E verification during phase development;
- late QA-only E2E tasks that defer integration proof until the end of the phase;
- missing or weak `Phase Acceptance Gate`;
- phase acceptance gates that do not cover every applicable service-wiring row;
- web phase plans that do not use Playwright or an explicitly established browser E2E equivalent;
- app phase plans that do not use simulator/emulator automation or an explicitly established app E2E equivalent;
- plan tasks that escaped their phase boundary.

Return Findings, Coverage Matrix, Phase Boundary Review, and Recommended Plan Edits. Do not modify files. Do not implement code.

Write the detailed review to `<plan output directory>/reviews/YYYY-MM-DD-<feature>-implementation-plan-review.md` and return only the review path, top findings, severity counts, and blocking status. For review reruns, create a new file such as `<plan output directory>/reviews/YYYY-MM-DD-<feature>-implementation-plan-review-rerun-2.md`; do not overwrite prior review artifacts.

If context pressure reaches roughly 70%, save a handoff document under `docs/handoffs/` using the Context Handoff Protocol and return only the handoff path plus current artifact paths.
```

## Parent Review Disposition Format

For each reviewer finding, the parent records:

```text
Plan review finding N: <severity> - <short issue>
Affected plan(s): <paths>
Design/phase source: <technical design section or phase>
Recommended edit: <specific plan or phase proposal change>
Disposition: accepted, revised, rejected as non-issue, deferred with rationale, or escalated
```

Patch plan documents and/or the phases document for accepted or revised findings. Escalate only allowed exception categories; do not wait for external approval on ordinary plan-quality fixes when the user has delegated autonomous planning.
