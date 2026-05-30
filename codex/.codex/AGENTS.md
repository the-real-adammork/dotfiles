## Git Worktree Isolation

When working inside a git worktree, never create symlinks that point to paths in the main repo or sibling worktrees, including `node_modules`, `.env`, `venv`, data dirs, config files, or build artifacts. Worktrees exist to isolate state; symlinking defeats that and causes mutations in one worktree to silently affect others.

- Copy files, re-install dependencies, or regenerate artifacts instead.
- If isolation is inconvenient, such as a slow install or large dataset, surface the tradeoff to the user and ask.
- Symlinks to genuinely shared, read-only locations outside any repo, such as `~/.cache`, system tool dirs, and global model/data stores, are fine.

## Local Port Isolation

Agents must treat local ports as workspace-local resources. Do not assume default ports are free across projects, branches, or git worktrees.

Before starting any local server or service, check for port conflicts. If the default port is unavailable, use an unused high port via env vars, CLI flags, or existing project config, and tell the user the final URL. Never kill unrelated processes or share a running service from another repo/worktree unless the user explicitly approves it.

## Playbooks

Use this table to route recurring work to the right global skill. Read the skill only when the task matches the topic.

| Topic | Skill |
| --- | --- |
| Web smoke testing and Playwright E2E | `~/.codex/skills/websmoketesting/SKILL.md` |
| Playwright coverage gaps by user flow | `~/.codex/skills/playwright-coverage/SKILL.md` |
| Design brief of app pages, functionality, and available data | `~/.codex/skills/design-brief/SKILL.md` |
| Durable local/test account seeding | `~/.codex/skills/account-seeding/SKILL.md` |
| Researching a high-level idea into an implementation direction | `~/.codex/skills/implementation-research/SKILL.md` |
| Repo-specific expert researcher profiles | `~/.codex/skills/expert-researcher/SKILL.md` |
| Repo-specific expert implementation or research agent profiles | `~/.codex/skills/expert-agent/SKILL.md` |
| Secrets, credentials, env files, API keys | `~/.codex/skills/secrets/SKILL.md` |
| Git commits and commit messages | `~/.codex/skills/commit/SKILL.md` |
