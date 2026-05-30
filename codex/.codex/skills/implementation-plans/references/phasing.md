# Implementation Phase Planning Reference

Turn an approved technical design into a sequence of smoke-testable implementation phase plans. Each generated implementation plan is one long-running phase task owned by a phase agent. Phases build on each other so the app comes to life over time, instead of building isolated horizontal stack layers. Prefer a foundation-first phase that creates shared scaffolding and stable contracts, then split later work into parallelizable phase waves whenever the design and repo can support safe concurrent execution.

## Start

Inputs:

- approved technical design path, default `docs/architecture/TECHNICAL_DESIGN.md`;
- optional requirements path;
- optional plan output directory, default `docs/plans/`;
- optional review output directory, default `<plan output directory>/reviews/`;
- optional SLICES document path, default `docs/plans/SLICES.md`.

Implementation plans may use repo-approved specialist worker agents when current repo instructions, installed local skills, or the approved technical design explicitly define them for specific lanes. Use `general-purpose worker` as the default/fallback worker type when no approved specialist is named. Keep reviewer and fix-worker roles for downstream review/remediation loops, but do not define, preserve, invent, request, or route work through unapproved repo-specific implementation agents during planning. If the technical design handoff includes a custom implementation-agent roster, treat it as non-binding until confirmed by current repo instructions or installed local skills.

`docs/plans/SLICES.md` is the canonical phase/slices index for every repo. Do not create feature-dated `*-implementation-phases.md` files unless the user explicitly overrides the path. This stable path lets `$implementation-execution` discover the approved phase order without the human passing a slices document path.

If the technical design path is missing from the request, look for `docs/architecture/TECHNICAL_DESIGN.md` first. If that file does not exist and the path cannot be inferred, ask for it.

## Context Budget Rules

Keep files as the source of truth. Do not paste full technical designs, phases documents, implementation plans, or review artifacts into the parent conversation unless the user asks.

- Pass file paths to planning agents whenever possible.
- Plan-writing agents return only path, phase name, 3-5 bullet summary, escalation count, blockers, and phase-boundary deviations.
- Reviewer agents write reviews to the review output directory and return only path, top findings, severity counts, and blocking status.
- Parent reads targeted file sections only when patching, resolving a finding, or answering a user question.
- If there are more than 5 phases, or any plan exceeds roughly 500 lines, require a file-based consolidated review.

## Dispatch Efficiency

Keep plan generation bounded and idempotent.

- Treat the user's request to run this phase-planning workflow as authorization to dispatch planning agents. Do not ask for a separate delegated-agent approval before dispatching plan writers or reviewers.
- This authorization does not bypass the phase-document approval checkpoint. Generate and review the phases document first, create and serve an HTML preview, then pause for explicit human approval before writing individual phase plan documents.
- If planning-agent dispatch is unavailable in the current runtime, generate the phases document and review artifact locally, pause for approval, and only then generate individual phase plans locally.
- Maintain a small dispatch table in the SLICES document before starting plan writers: phase name, output path, stable `agent_name`, host agent id/nickname, dependency frontier, status, and result path.
- Do not dispatch a plan-writing agent when its output plan already exists and matches the ready phase unless the user explicitly requests regeneration.
- Do not dispatch a replacement for an active or recently completed phase writer until you have checked the dispatch table, output path, and any handoff path.
- Use stable agent names in the format `phase-plan-writer: <feature-slug> / <phase-slug>` and `phase-plan-reviewer: <feature-slug> / consolidated`.
- In Codex, use `tool_search` to discover available multi-agent dispatch tools before deciding planning-agent dispatch is unavailable.
- After SLICES approval, build a dependency frontier from each ready phase's `Builds On`, explicit sequencing notes, service-wiring dependencies, and planned output assumptions.
- Dispatch all currently unblocked phase-plan writers in parallel. A phase is unblocked when every prerequisite phase plan it must inherit from already exists or is not required for its plan details.
- Serialize only phases that need exact APIs, file paths, smoke-test commands, acceptance packet assumptions, service-wiring decisions, or other concrete outputs from an earlier phase plan. When a prerequisite plan returns, recompute the frontier and dispatch the next unblocked batch.

## Planning Agent Context Handoff

Planning agents must self-monitor context pressure. If an agent estimates it is at or above roughly 70% context usage, or it cannot confidently finish within the remaining context, it must stop normal work, save a handoff document under `docs/handoffs/`, and return only the handoff path plus current artifact paths.

Handoff documents must include:

- original agent goal and assigned phase/review scope;
- progress made;
- in-progress documents and their current status;
- remaining work;
- blockers or decisions needed;
- exact completion criteria;
- recommended prompt for a replacement agent.

When this happens, the parent dispatches a replacement agent using the handoff document and the original source paths. Do not ask the replacement to infer state from chat history.

## Phase Criteria

Each phase should become its own implementation plan when it delivers a substantial logical increment that can be smoke tested after completion and used as the foundation for later phases. A phase should be large enough to justify a supervisor-launched phase orchestrator, but bounded enough that one orchestrator can maintain coherent context and integrate a small number of worker lanes efficiently.

Prefer fewer coherent phase plans over many thin plans. Do not split just because the design has multiple sections.

Do not split phases as horizontal stack layers like data model, backend/API, UI, jobs, and cleanup. Instead, combine the needed parts of those layers into each phase so a real workflow or capability exists at the end of the phase.

## Foundation-First Parallelization

During phasing, intentionally design Phase 1 as the shared foundation whenever the project has more than one substantial product area, integration, or workflow.

Phase 1 should establish enough common scaffolding for later phases to branch safely:

- repo setup, app shell, routing/navigation skeleton, auth/test-account seed path, design-system hooks, env/config shape, and smoke/E2E harness when relevant;
- shared schemas, migrations, domain contracts, API/client boundaries, job/event contracts, fixtures, and typed interfaces needed by multiple later phases;
- minimal vertical proof that the foundation works through the real runtime boundary, such as a simple read/write path, CLI run, or authenticated page flow;
- durable setup commands and acceptance artifacts later phase agents can reuse.

Phase 1 must not become a purely horizontal backend-only or infrastructure-only layer unless the product genuinely has no user/runtime surface yet. It should be a thin, smoke-testable foundation slice that proves the shared layers connect.

After Phase 1, look for parallel waves:

- phases with the same `Builds On` value and no shared write conflicts should be grouped into the same dependency frontier;
- split independent product areas, integrations, pages, workflows, reports, import/export paths, or runtime adapters into shorter parallel phases when each can be smoke tested independently;
- serialize phases that need exact APIs, schemas, migrations, generated types, acceptance packet outputs, or service-wiring decisions from another phase;
- when parallel phases touch a shared contract, move the stable contract into Phase 1 or create a short contract-setting phase before the parallel wave;
- after a parallel wave merges back to main, allow the next wave of phases to build on that merged frontier.

The SLICES document should make these waves explicit through `Builds On`, `Execution Order`, and the plan-writer dependency frontier. If parallelism is unsafe, state why in the phase breakup review instead of silently serializing everything.

## Phase Planning Committee

Always include this standing committee member during phase proposal and phase breakup review:

| Committee Member | Lens | Pushes Back On | Required Output |
| --- | --- | --- | --- |
| Ari Chen - Phase Architecture Engineer | Foundation-first sequencing, dependency frontiers, safe parallel workstreams, and merge-back waves | Over-serial phase plans, weak Phase 1 foundations, unsafe parallelism, and phase boundaries that block later agents | A Phase Breakup Review finding or explicit pass on foundation strength and parallel-wave safety |

Ari's review must answer:

- Does Phase 1 establish the shared contracts, setup, test data, E2E harness, schemas, app shell, and runtime proof later phases need?
- Which phases can run in the same dependency frontier after Phase 1 or a later wave merges?
- Which phases must serialize because of shared schemas, contracts, generated files, migrations, runtime resources, or acceptance assumptions?
- Would splitting one large phase into shorter parallel phases increase speed without adding dangerous merge conflicts?

Record Ari's recommendation in the SLICES document even when the answer is "phase sequence approved as serial."

Good phase boundaries include:

- the smallest end-to-end read path that proves the model, API/service, and UI/CLI can talk to each other;
- a first write path with validation, persistence, and visible confirmation;
- a meaningful workflow expansion that builds on the earlier read/write paths;
- real integration replacement after a mocked/local path, with smoke testing against the best available real environment;
- hardening, observability, and rollout work once the main workflow exists.

Every phase must state:

- what app behavior works at the end;
- what earlier phase behavior it builds on;
- what smoke test proves it;
- what seeded local admin/demo users, credentials path, and deterministic test data are needed for auth-gated smoke tests;
- what the phase orchestrator is responsible for, limited to orchestration, integration decisions, lifecycle state, and result validation;
- what worker lanes are safe or unsafe to run in parallel, including serial lanes for work that cannot parallelize;
- which worker lanes use repo-approved specialists or general-purpose workers, and which review/fix loops the execution workflow should expect;
- what service wiring rows must be proven across surface, service, persistence, jobs, and integrations;
- what E2E harness is needed early in the phase;
- what platform E2E automation will prove the smoke test through the phase acceptance gate;
- what acceptance packet must exist before phase completion;
- what later phases can safely assume.
- which dependency frontier or parallel wave it belongs to, and whether it can run concurrently with sibling phases after its prerequisites merge.

## Codex Efficiency Model

Optimize phase plans for Codex execution efficiency:

- Use fewer, substantial phases rather than many thin phases that force repeated setup, sync, and review overhead.
- Keep each phase coherent enough for one phase orchestrator to hold the working context.
- Identify a small number of worker lanes only where parallelism, serial isolation, or bounded scope is valuable.
- Every task is a delegated worker lane. Keep only lifecycle routing, integration decisions, state, and result validation with the orchestrator. Runtime, service/API, persistence, schema/migration, parser, frontend, E2E/integration-test, shared-contract behavior, docs/config, setup, acceptance-prep, remediation, and final acceptance must become worker lanes even when serial.
- Prefer sequential phase execution unless phases are truly independent, because later phases should reuse verified behavior and acceptance packets from earlier phases.
- Prefer a foundation phase followed by parallel dependency frontiers when phases are truly independent. Do not force sequential execution after Phase 1 when sibling phases can safely branch from the same verified foundation and merge back independently.
- Make the phases document a routing map, not a second implementation plan.

Every generated phase plan must include a delegated phase acceptance gate with E2E or equivalent end-to-end automation and a required acceptance packet. This is a completion gate run by a general-purpose acceptance worker/agent, not an orchestrator-owned task. For web work, use Playwright unless the repo already standardizes on another browser automation framework. For mobile or app work, use simulator/emulator automation appropriate to the platform. For service, CLI, desktop, or worker-only phases, use the closest true end-to-end harness that exercises the phase through its real runtime boundary.

For auth-gated web work, Playwright readiness requires deterministic seeded local users. The phase must include or depend on a seed/setup path that creates a local admin or demo user before authenticated browser tests run. Missing seeded local admin/demo access is a phase-planning defect, not an execution-time escalation, unless the phase has no login-gated smoke path.

## Autonomy Model

The workflow is designed for long-running agent teams without routine operator oversight. External involvement is an exception path, not a task format.

Agents should proceed using repo evidence, requirements, technical designs, local tooling, containers, emulators, seed scripts, and dev/staging resources. Escalate only for:

- credentials, secrets, or private account access;
- paid account setup, billing, quota purchase, or vendor approval;
- product, legal, privacy, security, or compliance decisions not already answered by source docs;
- destructive production actions, real customer data access, or irreversible external side effects;
- unavailable physical devices, entitlements, or external services after a documented agent-owned attempt.

Record escalations in the phase plan's `Autonomy And Escalation` table. Do not add optional non-automated checks or manual verification gates.

## Workflow

1. Read the technical design and any referenced requirements.
2. Inspect enough repo context to understand ownership boundaries, test commands, E2E harnesses, and existing patterns.
3. Identify a foundation-first Phase 1 and then dependency frontiers: phases that can run in parallel after the foundation, phases that must wait for a prior wave, and phases that must remain serial because of shared contracts or resources.
4. Create or update the SLICES document at `docs/plans/SLICES.md`. Read `references/phases-document.md` for the required format and lifecycle.
5. Present the phase proposal summary when the user asks for a planning checkpoint; otherwise record planning assumptions in the phases document and proceed when the design is sufficient.
6. Run a phase breakup review against the technical design:
   - all major responsibilities, integration points, sequencing items, risk mitigations, and verification areas map to phases;
   - each phase has a coherent smoke-testable outcome;
   - each phase can be owned by one long-running phase agent without losing coherence;
   - each phase names a small number of likely worker lanes and shared-resource risks;
   - each worker lane uses a repo-approved specialist or general-purpose worker, with specialists justified by current repo instructions, installed local skills, or the approved technical design;
   - each phase avoids delegation churn from overly tiny tasks;
   - each phase names the service wiring that must be proven;
   - each phase names early E2E harness needs and phase acceptance automation;
   - each phase names the acceptance packet expected before phase completion;
   - dependencies, build-on assumptions, and deferred work are explicit;
   - Phase 1 provides the right shared foundation for later phases without becoming a horizontal stack-only phase;
   - safe post-foundation parallel waves are identified, and unsafe parallelism has a concrete reason;
   - Ari Chen's Phase Architecture Engineer committee review is recorded with either an explicit pass or actionable findings.
   Save detailed phase review artifacts under the review output directory. Keep only the summary/disposition table and review links in the phases document.
7. Patch the phases document for accepted or internally resolved findings. Do not generate plan docs until High/Medium phase issues are resolved, explicitly deferred with rationale, or recorded as allowed escalations.
8. Author an HTML approval preview from the reviewed phases document and serve it on localhost:
   - Do not use a deterministic markdown-to-HTML converter such as `pandoc`.
   - Read the current `docs/plans/SLICES.md` and create a standalone, hand-authored `docs/plans/SLICES.html` page that preserves every section, table row, link, path, and approval-relevant detail.
   - Use embedded CSS with a readable document layout, constrained content width, clear typography, high-contrast text, muted metadata, and horizontally scrollable wide tables.
   - Write the preview next to the SLICES document using the same basename and `.html`, normally `docs/plans/SLICES.html`.
   - Use a local server such as `python3 -m http.server <port> --bind 127.0.0.1 --directory <plan output directory>`.
   - Prefer port `4173`; if it is busy, choose the next available port.
   - Record the HTML path and localhost URL in the phases document's `HTML Approval Preview` section.
9. Present the reviewed phases document, HTML preview link, and pause. Do not dispatch plan-writing agents or create individual phase plan documents until the user explicitly approves the phase sequence and boundaries.
10. After approval, set the phases document to `Ready`, create or update the plan-writer dispatch table, discover available planning-agent dispatch tooling, compute the current unblocked dependency frontier, and dispatch one plan-writing agent per unblocked ready phase that does not already have a valid plan output. Read `references/planning-agent-prompts.md` for the required prompt and return contract.
11. Update the phases document after each plan is created. Recompute and dispatch the next unblocked dependency frontier until all ready phase plans exist, then set status to `Plans Generated`.
12. Dispatch one consolidated reviewer agent. Use `references/planning-agent-prompts.md`.
13. Patch plan docs and/or the phases document for accepted or internally resolved reviewer findings.
14. Rerun consolidated review when High/Medium findings were patched, phase boundaries changed, or the user asks. Save each rerun as a separate artifact in the review output directory; do not overwrite prior review files.
15. Final local check and handoff.

Do not begin implementation unless the user chooses an execution option. Do not generate individual phase plan documents before the phases document has explicit user approval, even when the user has delegated the broader planning workflow.

## Final Checks

Before handoff:

- SLICES document exists at `docs/plans/SLICES.md`, links back to the technical design, and links forward to every generated plan;
- SLICES document has an HTML approval preview generated from the current markdown and served on localhost before requesting approval;
- individual phase plan documents were generated only after explicit approval of the reviewed phases document;
- every ready phase has a plan file at the reported path;
- every phase has a smoke-testable outcome, auth/test-data readiness note, orchestrator responsibility, worker lane summary, service wiring summary, E2E harness readiness note, phase acceptance automation, and expected acceptance packet;
- every phase plan includes `Autonomy And Escalation` with only allowed exception categories;
- every phase plan includes a `Phase Execution Contract` for supervisor-launched phase orchestration, worker delegation, integration checkpoints, and handoff;
- every phase plan includes an `Implementation Execution Handoff` with `$implementation-execution` state, manifest, event, and evidence paths;
- every phase plan includes a `Service Wiring Matrix`;
- every phase plan brings E2E automation in early enough to verify integrations during phase development;
- every phase plan includes a `Phase Acceptance Gate` and does not reserve E2E work for a late QA-only task;
- review artifacts are stored under the review output directory, not mixed with implementation plan files;
- coverage check maps technical design sections to phases;
- phase breakup review ran before plan generation;
- Phase Architecture Engineer committee review is recorded in the SLICES document;
- consolidated plan review ran after all plan docs returned;
- accepted/revised findings were applied;
- every technical design responsibility maps to one or more phases;
- horizontal stack splits have been rejected unless explicitly justified;
- Phase 1 establishes shared scaffolding/contracts/setup/E2E foundation for later phases when the design has multiple substantial work areas;
- safe parallel phase waves after the foundation are identified through dependency frontiers, or serialization is justified by concrete shared-resource/contract risks;
- phase and worker lane counts are efficient for Codex: substantial enough to amortize context setup, bounded enough to avoid context loss;
- task `Execution` parallelism is consistent with task dependencies and any shared sequential contract handoff points are named explicitly;
- every worker-owned task uses a repo-approved specialist or general-purpose worker, with no unapproved custom repo-specific implementation agent routing;
- no task uses ambiguous ownership such as `orchestrator`, `orchestrator or worker`, `orchestrator or one worker`, or `orchestrator unless delegated`, and no task is orchestrator-owned;
- substantial runtime, service/API, persistence, schema/migration, parser, frontend, E2E/integration-test, or shared-contract behavior is assigned to worker lanes even when serial;
- delegated behavior tasks include a TDD test proposal/approval gate before implementation;
- build-on dependencies, deferred work, verification gaps, and escalations are resolved or explicitly noted;
- no implementation work was performed.

## Handoff

Report:

```markdown
Created implementation plans:

- `<path>` - <phase goal>
- `<path>` - <phase goal>

SLICES document:
- `docs/plans/SLICES.md`

HTML approval preview:
- `<html path>`
- `<localhost URL>`

Execution order:
1. <foundation phase>
2. Parallel frontier: <phase>, <phase>
3. Next frontier: <phase>

Open coordination notes:
- <note or "None">
```

Then offer:

```text
Next options:
1. Run `$implementation-execution` in phase order, with the supervisor launching one phase orchestrator per phase.
```
