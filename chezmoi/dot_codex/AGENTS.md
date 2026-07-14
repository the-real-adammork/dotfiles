## Worktree Branch Placement

Keep a repository's root checkout on its main branch. When work needs a separate branch, create it in a linked worktree under `.worktrees/<branch-name>/` instead of switching the root checkout away from main.

## Git Worktree Isolation

When working inside a git worktree, never create symlinks that point to paths in the main repo or sibling worktrees, including `node_modules`, `.env`, `venv`, data dirs, config files, or build artifacts. Worktrees exist to isolate state; symlinking defeats that and causes mutations in one worktree to silently affect others.

- Copy files, re-install dependencies, or regenerate artifacts instead.
- If isolation is inconvenient, such as a slow install or large dataset, surface the tradeoff to the user and ask.
- Symlinks to genuinely shared, read-only locations outside any repo, such as `~/.cache`, system tool dirs, and global model/data stores, are fine.

## Local Port Isolation

Agents must treat local ports as workspace-local resources. Do not assume default ports are free across projects, branches, or git worktrees.

Before starting any local server or service, check for port conflicts. If the default port is unavailable, use an unused high port via env vars, CLI flags, or existing project config, and tell the user the final URL. Never kill unrelated processes or share a running service from another repo/worktree unless the user explicitly approves it.

## Human-in-the-Loop Verification URLs

For a locally deployable project, never claim a task is done without giving the human a way to verify it. Return the worktree's local URL(s) — including the specific path to view the change (e.g. `http://localhost:5173/settings`). If it isn't running, give the command to start it and the URL it'll be at.

## Test & Smoke Test Presentation

Never return a test to run or flow to check unless the agent has already has run that test and its passing, or for UI testing, written a UI test - playwright for web - and verified it to be working as expected.

## Durable Local/Test Accounts

For apps that require login, prefer seeded durable local/test accounts so smoke tests and E2E tests can authenticate repeatably.

- Store local/test account credentials in `account.env`.
- Add a narrow `.gitignore` rule for `account.env`.
- Encrypt `account.env` with `git-secret` when available, producing `account.env.secret`.
- Commit encrypted credentials and git-secret metadata only; never commit plaintext `account.env`.
- Do not print passwords, tokens, or secret values in logs, docs, comments, or final responses.
- Verify seeded accounts can authenticate locally before claiming login, smoke, or E2E flows pass.

## Playbooks

Use this table to route recurring work to the right global skill. Read the skill only when the task matches the topic.

| Topic                                                          | Skill                                              |
| -------------------------------------------------------------- | -------------------------------------------------- |
| Web smoke testing and Playwright E2E                           | `~/.codex/skills/websmoketesting/SKILL.md`         |
| Playwright coverage gaps by user flow                          | `~/.codex/skills/playwright-coverage/SKILL.md`     |
| Design brief of app pages, functionality, and available data   | `~/.codex/skills/design-brief/SKILL.md`            |
| Durable local/test account seeding                             | `~/.codex/skills/account-seeding/SKILL.md`         |
| Researching a high-level idea into an implementation direction | `~/.codex/skills/implementation-research/SKILL.md` |
| Repo-specific expert researcher profiles                       | `~/.codex/skills/expert-researcher/SKILL.md`       |
| Repo-specific expert implementation or research agent profiles | `~/.codex/skills/expert-agent/SKILL.md`            |
| Secrets, credentials, env files, API keys                      | `~/.codex/skills/secrets/SKILL.md`                 |
| Git commits and commit messages                                | `~/.codex/skills/commit/SKILL.md`                  |

<!-- BEGIN COMPOUND CODEX TOOL MAP -->
## Compound Codex Tool Mapping (Claude Compatibility)

This section maps Claude Code plugin tool references to Codex behavior.
Only this block is managed automatically.

Tool mapping:
- Read: use shell reads (cat/sed) or rg
- Write: create files via shell redirection or apply_patch
- Edit/MultiEdit: use apply_patch
- Bash: use shell_command
- Grep: use rg (fallback: grep)
- Glob: use rg --files or find
- LS: use ls via shell_command
- WebFetch/WebSearch: use curl or Context7 for library docs
- AskUserQuestion/Question: present choices as a numbered list in chat and wait for a reply number. For multi-select (multiSelect: true), accept comma-separated numbers. Never skip or auto-configure — always wait for the user's response before proceeding.
- Task (subagent dispatch) / Subagent / Parallel: run sequentially in main thread; use multi_tool_use.parallel for tool calls
- TaskCreate/TaskUpdate/TaskList/TaskGet/TaskStop/TaskOutput (Claude Code task-tracking, current): use update_plan (Codex's task-tracking primitive)
- TodoWrite/TodoRead (Claude Code task-tracking, legacy — deprecated, replaced by Task* tools): use update_plan
- Skill: open the referenced SKILL.md and follow it
- ExitPlanMode: ignore
<!-- END COMPOUND CODEX TOOL MAP -->
