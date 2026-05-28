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

The supervisor transition handler owns phase-transition handoffs and final user-facing run status. The phase orchestrator must not write a handoff merely because phase acceptance passed; it should write `request.type: phase_completion` to the supervisor inbox and let the watchdog wake the supervisor.

Write a markdown handoff only when:

- context pressure is high;
- the run is blocked;
- the user stops the workflow;
- a different agent must resume.

Do not write a final-style handoff merely because one phase completed when execution scope is `run` and another phase remains. In that case, the supervisor transition handler fast-forwards the accepted phase branch into the run base branch, updates `run.yaml`, records the completed phase evidence and resulting base commit, runs post-merge local verification setup, closes or replaces the completed orchestrator pane, and continues with the next phase orchestrator from the updated base branch.

Default path:

```text
docs/implementation-runs/<run-id>/handoffs/YYYY-MM-DD-HHMM-<phase>.md
```

Required contents:

- run id and current phase;
- `run.yaml` and `phase.yaml` paths;
- execution manifest path;
- orchestrator pane id or inline fallback reason;
- supervisor inbox path;
- watchdog script, PID, trigger path, and wake method;
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
- pane: `<tmux pane id or inline fallback>`
- inbox: `<supervisor inbox path>`

Watchdog:
- pid: `<pid or disabled>`
- trigger: `<watchdog trigger path>`

Next action:
- <continuing to next phase | stopped because single-phase scope | blocked | complete>

Human smoke test:
- URL: `<localhost URL or unavailable>`
- Checks: `<brief checklist or artifact path>`

Blocked or escalated:
- <item or "None">
```
