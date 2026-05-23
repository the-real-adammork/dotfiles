# Delegation Model

Codex's native multi-agent dispatch is a capability of the active host session. The supervisor is the dispatcher and sequencing owner for all task workers, fix workers, task reviewers, merge workers, and replacement supervisors.

The default pattern is:

1. Supervisor owns the active plan task loop directly.
2. Supervisor decides when worker or reviewer help is needed.
3. Supervisor spawns the requested native sub-agent in the task worktree/branch for task workers, reviewers, and fix workers, putting `agent_name` at the top of the prompt.
4. Supervisor waits for the result, records it in SQLite, closes or retires the child agent when the host supports it, and continues the task loop.
5. Supervisor updates Linear, commits, handles human review according to `human_review_mode`, updates docs, and continues sequencing.

Use `codex exec` child runs only when `worker_dispatch = "codex_cli"` is explicitly configured or the user explicitly asks for autonomous CLI child agents. Treat CLI child runs as a workaround/advanced mode, not the default.

Use this prompt/return contract for worker and reviewer dispatch:

```markdown
Dispatch:
- kind: task-worker | fix-worker | task-reviewer | merge-worker
- agent_name: <role>: <plan-slug> / <task id> - <short task title>
- plan: <implementation-plan path>
- task: <task number and title>
- worktree: <task worktree path>
- branch: <task branch>
- base_worktree: <task base worktree path>
- base_branch: <task base branch>
- base_commit: <task base commit SHA>
- pr_target_branch: <task base branch>
- linear_issue: <issue id or url>
- state_db: <SQLite state DB path>
- run_id: <workflow run id>
- plan_id: <SQLite plan id>
- prompt: <bounded instructions for the requested agent>
- expected_return: <files changed, review path, findings, verification, blocker, or handoff>
```

The supervisor must preserve `agent_name` in SQLite and any handoff. The native host may return its own agent id or nickname instead of displaying the requested `agent_name`. Immediately after every spawn, record an `agents` row that maps `agent_name` to the returned host agent id/nickname, and tell the user that mapping if they may need to attach follow-up input.

Use this naming pattern:

```text
task-worker: <plan-slug> / <linear issue> - <short task title>
task-reviewer: <plan-slug> / <linear issue> - <short task title>
fix-worker: <plan-slug> / <linear issue> - <short task title>
merge-worker: <plan-slug> -> <target branch>
replacement-supervisor: <feature-slug> / resume
```

Worker and reviewer results go back to the supervisor. The supervisor is the only default owner of task advancement, Linear transitions, commits, human-review wait state, and SQLite state.

## Speed Defaults

- Use medium reasoning for the supervisor's active plan loop, task workers, fix workers, and reviewers by default. Use high reasoning only for broad refactors, hard production-debugging tasks, or replacement agents recovering ambiguous state.
- Use low reasoning for merge workers because their job is mechanical branch verification and merge reporting.
- Do not spawn separate commit-message agents inside this workflow. The supervisor should inspect the staged diff and write the commit message inline.
- Do not spawn a state-update sub-agent for routine per-event SQLite updates. The supervisor already has the current state and should update its own SQLite rows inline.
- After any task worker, fix worker, reviewer, merge worker, or commit helper returns, record its result in SQLite and close or retire the host agent when available. Do not keep completed child agents open as implicit memory.
- Keep spawned prompts bounded to file paths, exact task anchors, ownership boundaries, and return contracts. Do not paste full plans, run logs, or reviews into child prompts unless the child cannot read the files directly.
- Reuse verification evidence across worker, fix-worker, and reviewer loops. Reviewers should not rerun a slow full-suite command when the same command already passed for the same uncommitted diff and targeted inspection is enough.
- Keep worker, fix-worker, reviewer, and human-review Linear comments compact. Detailed findings, fix notes, verification output, PR/MR review notes, command logs, and human-review checklists belong in SQLite events or repo artifacts such as local review artifacts and human-review packets.
