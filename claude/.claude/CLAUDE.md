## Worktree Branch Placement

Keep a repo's root checkout (the root worktree) on the main branch at all times. Never switch the root checkout to a feature branch. When work needs its own branch, create it in a new worktree under `.worktrees/` (e.g. `.worktrees/<branch-name>`) rather than checking the branch out at the root.

## Git Worktree Isolation

When working inside a git worktree, never create symlinks that point to paths in the main repo or sibling worktrees (including `node_modules`, `.env`, `venv`, data dirs, config files, build artifacts). Worktrees exist to isolate state — symlinking defeats that and causes mutations in one worktree to silently affect others.

- Copy files, re-install dependencies, or regenerate artifacts instead.
- If isolation is inconvenient (slow install, large dataset), surface the tradeoff to the user and ask — don't route around it with a symlink.
- Symlinks to genuinely shared, read-only locations outside any repo (e.g. `~/.cache`, system tool dirs, global model/data stores) are fine.

## Local Port Isolation

Treat local ports as project- and worktree-local resources. Do not assume default ports are free across projects, branches, or git worktrees.

Before starting any local server or service, check for port conflicts. If the default port is unavailable, use an unused high port via env vars, CLI flags, or existing project config, and tell the user the final URL.

Never kill unrelated processes or share a running service from another repo/worktree unless the user explicitly approves it.

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
