# Supervisor-Owned Task Loops

## Problem

Second-level orchestrator agents may report that they cannot dispatch more sub-agents. A common workaround is to have the orchestrator call `codex exec`, but that creates a separate CLI process tree with weaker host-session visibility, cancellation, and lifecycle control. Even when the orchestrator bounces dispatch requests back to the supervisor, the extra layer adds context handoffs and duplicated resume logic.

## Correct Approach

Use a two-layer workflow by default. The top-level supervisor owns sequencing and the active plan task loop, while bounded sub-agents handle task implementation, task review, fixes, and mechanical merges.

Use a separate plan orchestrator only as a legacy or explicit opt-in mode. Use `codex exec` child runs only when explicitly configured or requested as an autonomous CLI fallback.

## When To Apply

Apply this lesson when designing or debugging multi-agent workflows with more than one delegation layer, especially workflows that look like supervisor -> orchestrator -> worker/reviewer.

## Steps

1. Keep the supervisor as the only agent that calls native sub-agent dispatch.
2. Let the supervisor own the active plan task loop directly.
3. Dispatch only bounded workers: `task-worker`, `task-reviewer`, `fix-worker`, and `merge-worker`.
4. Record stable agent names and host attachment targets in workflow state.
5. Treat `codex exec` as an opt-in fallback, not the preferred flow.

## Example

```markdown
Dispatch:
- kind: task-worker
- agent_name: task-worker: example-plan / ABC-123 - Wire service integration
- plan: docs/plans/example-implementation-plan.md
- task: Task 3 - Wire service integration
- worktree: .worktrees/example-plan
- branch: codex/example/example-plan
- linear_issue: ABC-123
- prompt: Implement only Task 3. Do not commit, merge, reset, clean, push, or revert unrelated changes.
- expected_return: changed files, verification, blockers, and how the task was satisfied
```

After spawning, the supervisor records the actual attachment target:

```markdown
## Agent Directory

| Stable Agent Name | Host Agent ID/Nickname | Role | Plan | Task/Issue | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| task-worker: example-plan / ABC-123 - Wire service integration | <returned host id or nickname> | task-worker | example-plan | ABC-123 | running | Attach user input to the host id/nickname. |
```

## Related Files

- `codex/.codex/skills/linear-implementation-supervisor/SKILL.md`
- `codex/.codex/skills/implementation-task-worker/SKILL.md`
- `codex/.codex/skills/task-implementation-review/SKILL.md`
