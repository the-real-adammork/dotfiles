# Handoff And Final Output

The supervisor should stop active work only for:

- full plan completion;
- true blocker, such as missing credentials, unavailable external dependency, or existing unrelated failing tests;
- event-driven human-review wait or human-review timeout after the full configured `human_review_timeout_minutes`;
- context handoff;
- explicit user stop.

In default `event_driven` mode, the human-review wait is the expected resume point.

If the supervisor cannot continue, write:

```text
docs/handoffs/YYYY-MM-DD-<feature>-linear-supervisor-handoff.md
```

Include completed plans, active plan, worktree paths, branches, Linear project/issue state, commits, blocked tasks, pending human reviews, and exact restart instructions.

Update SQLite first, set `status` and `restart_action`, append an event with the handoff path, and link the handoff from the run row. The handoff is a detailed snapshot; SQLite remains the entry point for restart.

Final output:

```markdown
Linear implementation supervision complete.

Completed plans:
- `<plan>` - <branch> - <commits> - merged: <merge sha or "not merged">

Updated upcoming plans:
- `<plan>` - <summary or "none">

Blocked or waiting:
- <issue/task or "None">

Handoffs:
- <path or "None">
```
