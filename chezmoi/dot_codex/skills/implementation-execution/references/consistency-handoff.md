# Consistency And Handoff

Keep state and docs current without creating context bloat.

## Batched Consistency

Batch consistency updates instead of rewriting plans after every small task.

Run consistency when:

- a worker result changes a future task assumption;
- a task completes and unblocks dependent work;
- a phase is about to be accepted;
- the orchestrator is about to request supervisor action because it is blocked, must restart, or cannot safely continue;
- the supervisor is about to move to the next phase.

Update only future inactive task instructions. Do not rewrite completed task history except for compact actual-vs-planned notes when useful.

When a consistency update changes future inactive tasks, update the compact execution manifest for those tasks in the same batch. Record only routing/index fields in the manifest and append a compact `manifest_patched` event.

## Actual-Vs-Planned Notes

Use compact notes only when implementation reality matters for future work:

```markdown
> Actual-vs-planned: Task 4 shipped `/api/v2/records` instead of `/api/records`; downstream tasks should use the v2 path.
```

Do not add notes for routine successful implementation that does not affect future tasks.

## Handoff

The delegated acceptance worker/agent owns the phase-transition handoff/report after phase acceptance passes. The orchestrator validates that result and routes phase completion. The native phase-merge sub-agent uses that handoff/report for merge-back. After the supervisor has stopped the completed orchestrator and started the next phase from the merged base branch, the native phase-transition sub-agent uses that same handoff/report for local verification setup. The original supervisor owns final user-facing smoke-report printing when the transition sub-agent reports ready.

The phase-transition handoff/report is required for normal phase completion. The acceptance worker writes it before the orchestrator sends `request.type: phase_completion` under:

```text
docs/implementation-runs/<run-id>/handoffs/<phase-slug>-transition.md
```

It must include:

- phase slug, run id, accepted commit, acceptance packet, phase state, and artifact directory;
- what new behavior should now work;
- exact local setup/run instructions from the merged base worktree;
- expected localhost URL/ports or how the supervisor should choose safe alternates;
- smoke-test checklist with expected outcomes for newly delivered behavior;
- required demo/test data, accounts, fixtures, or safe placeholder env values;
- seeded local admin access details for login-gated smoke tests. Include harmless local/demo credentials directly only when classified safe by `$secrets`; otherwise list the exact ignored plaintext file path and account/variable names where the credentials are stored, without printing secret values. If no seeded admin user exists, the phase-transition handoff/report is incomplete and the orchestrator must not request `phase_completion`;
- local caveats, blockers, and allowed escalation details;
- verification artifacts and residual risks.

The handoff/report is the correct place for smoke-test and reviewer instructions. Do not copy these instructions into the app itself. Product UI, API responses, seed user-facing content, generated demo content, and runtime assets must contain only product-facing copy that is part of the requirements; workflow-only setup, smoke, acceptance, or reviewer guidance stays in handoffs, QA artifacts, acceptance packets, transition YAML, or developer docs.

Write additional markdown handoffs only when:

- context pressure is high;
- the run is blocked;
- the user stops the workflow;
- a different agent must resume.

Do not write a final-style handoff merely because one phase completed when execution scope is `run` and another phase remains. In that case, the orchestrator writes the phase-transition handoff/report above, then the supervisor routes `phase_completion` to a native phase-merge sub-agent. The merge sub-agent merges or reconciles the accepted phase branch into the run base branch, updates merge-owned `transitions/<phase>.yaml` fields, records completed phase evidence, resulting base commit, and merge decisions, then returns a compact result to the supervisor. The supervisor stops the completed orchestrator pane/session, marks the trigger handled, updates only minimal `run.yaml` pointers/status, starts the next phase orchestrator from the updated base branch, and then spawns the post-advance phase-transition sub-agent for local verification and smoke reporting. When the smoke report is ready, the supervisor prints it while leaving the next phase running.

Default path for additional context/blocker/resume handoffs:

```text
docs/implementation-runs/<run-id>/handoffs/YYYY-MM-DD-HHMM-<phase>.md
```

Required contents:

- run id and current phase;
- `run.yaml`, `phase.yaml`, and `transitions/<phase>.yaml` paths;
- execution manifest path;
- orchestrator pane id or blocked launch reason;
- supervisor inbox path;
- watchdog script, PID, same-session window/pane, trigger path, wake method, and wake blocker if any;
- branch/worktree;
- active lanes and worker result paths;
- completed tasks and commits;
- verification artifact paths;
- event log paths;
- service-wiring coverage status;
- acceptance packet status;
- promoted lesson paths and pending lesson candidates;
- blockers/escalations;
- exact restart instructions.

## Final Output

Report compactly:

```markdown
Implementation execution status: <running|blocked|complete>

Run state:
- `<run.yaml>`

Completed phases:
- `<phase>` - <acceptance packet> - local verification: `<localhost URL or blocked reason>`
- Merge reconciliation: `<none | preserved local changes | decisions artifact | critical blocker>`

Current phase:
- `<phase>` - <status> - `<phase.yaml>`

Orchestrator:
- pane: `<tmux pane id or unavailable>`
- inbox: `<supervisor inbox path>`

Watchdog:
- pid: `<pid or disabled>`
- trigger: `<watchdog trigger path>`

Next action:
- <continuing to next phase | stopped because single-phase scope | blocked | complete>

Human smoke test:
- URL: `<localhost URL or unavailable>`
- Transition handoff: `<path or unavailable>`
- Smoke report: `<brief checklist or artifact path>`

Blocked or escalated:
- <item or "None">
```
