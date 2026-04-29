## Git Worktree Isolation

When working inside a git worktree, never create symlinks that point to paths in the main repo or sibling worktrees, including `node_modules`, `.env`, `venv`, data dirs, config files, or build artifacts. Worktrees exist to isolate state; symlinking defeats that and causes mutations in one worktree to silently affect others.

- Copy files, re-install dependencies, or regenerate artifacts instead.
- If isolation is inconvenient, such as a slow install or large dataset, surface the tradeoff to the user and ask.
- Symlinks to genuinely shared, read-only locations outside any repo, such as `~/.cache`, system tool dirs, and global model/data stores, are fine.
