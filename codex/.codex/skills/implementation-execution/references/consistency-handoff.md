# Consistency And Handoff

Keep state and docs current without creating context bloat.

## Batched Consistency

Batch consistency updates instead of rewriting plans after every small task.

Run consistency when:

- a worker result changes a future task assumption;
- a task completes and unblocks dependent work;
- a phase is about to be accepted;
- the phase owner is about to hand off;
- the supervisor is about to move to the next phase.

Update only future inactive task instructions. Do not rewrite completed task history except for compact actual-vs-planned notes when useful.

## Actual-Vs-Planned Notes

Use compact notes only when implementation reality matters for future work:

```markdown
> Actual-vs-planned: Task 4 shipped `/api/v2/records` instead of `/api/records`; downstream tasks should use the v2 path.
```

Do not add notes for routine successful implementation that does not affect future tasks.

## Handoff

Write a markdown handoff only when:

- context pressure is high;
- the run is blocked;
- the user stops the workflow;
- a different agent must resume.

Default path:

```text
docs/implementation-runs/<run-id>/handoffs/YYYY-MM-DD-HHMM-<phase>.md
```

Required contents:

- run id and current phase;
- `run.yaml` and `phase.yaml` paths;
- branch/worktree;
- active lanes and worker result paths;
- completed tasks and commits;
- verification artifact paths;
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
- `<phase>` - <acceptance packet>

Current phase:
- `<phase>` - <status> - `<phase.yaml>`

Blocked or escalated:
- <item or "None">
```
