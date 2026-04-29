## Git Worktree Isolation

When working inside a git worktree, never create symlinks that point to paths in the main repo or sibling worktrees (including `node_modules`, `.env`, `venv`, data dirs, config files, build artifacts). Worktrees exist to isolate state — symlinking defeats that and causes mutations in one worktree to silently affect others.

- Copy files, re-install dependencies, or regenerate artifacts instead.
- If isolation is inconvenient (slow install, large dataset), surface the tradeoff to the user and ask — don't route around it with a symlink.
- Symlinks to genuinely shared, read-only locations outside any repo (e.g. `~/.cache`, system tool dirs, global model/data stores) are fine.
