# Agent Instructions for dots

## Repeatability

Every change must be reproducible on a fresh machine via `./install.sh`.

When adding a tool or dependency:
- Add the formula/cask to `Brewfile` (or `Brewfile.macos` for macOS-only)
- If it needs setup beyond brew (e.g. cargo install, git clone), add a step to `install.sh`
- Config files go in a stow package directory (e.g. `toolname/.config/toolname/`)

When removing a tool:
- Remove it from `Brewfile`/`Brewfile.macos` and `install.sh`
- Remove its stow package directory and any references in other configs (e.g. `.zshrc`)

Dependencies and configs must stay in sync. If a config references a binary, that binary must be tracked in `Brewfile` or `install.sh`.

## Repo Structure

- Each top-level directory is a GNU Stow package symlinked into `$HOME`
- `Brewfile` - cross-platform CLI tools
- `Brewfile.macos` - macOS-only tools and casks
- `install.sh` - full bootstrap: brew, cargo, stow, and setup steps
- `ITEMS.md` - outstanding TODO items

## Git

Use `/usr/bin/git` instead of `git` to avoid SCM Breeze wrapper conflicts.

## Lessons

- Linear implementation workflows: prefer the two-layer supervisor-owned task loop; keep native sub-agent dispatch at the supervisor level and use task/review/fix/merge workers for bounded work. See [docs/lessons/2026-05-21-supervisor-mediated-subagents.md](docs/lessons/2026-05-21-supervisor-mediated-subagents.md).

## Secrets and Credentials

When an untracked file appears to contain secrets, credentials, tokens, or private keys, immediately add a narrowly scoped `.gitignore` rule for that path before continuing.

Prefer exact file paths or tool-specific runtime directories over broad patterns, and do not open or print the contents of suspected secret files.
