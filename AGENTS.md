# Agent Instructions for dots

## Repeatability

Every change must be reproducible on a fresh machine via `./install.sh`.

When adding a tool or dependency:

- Add the formula/cask to `Brewfile` (or `Brewfile.macos` for macOS-only)
- If it needs setup beyond brew (e.g. cargo install, git clone), add a step to `install.sh`
- Portable config source goes under `chezmoi/` using chezmoi source-state names.
- Mixed application config must have a policy under `config/policies/` and a portable overlay under `config/portable/`.

When removing a tool:

- Remove it from `Brewfile`/`Brewfile.macos` and `install.sh`
- Remove its chezmoi source and any references in other configs (e.g. `.zshrc`).

Dependencies and configs must stay in sync. If a config references a binary, that binary must be tracked in `Brewfile` or `install.sh`.

## Dotfile Ownership

- `chezmoi/` is canonical portable source state.
- `config/managed-targets.toml` declares every managed or intentionally unmanaged target and its logical `--only` group.
- Legacy top-level Stow packages are migration-only rollback sources. Do not edit them for new portable changes.
- Never let Stow and chezmoi actively own the same target. Existing Stow symlinks must pass `scripts/dotfiles-state preview` and explicit transactional adoption before replacement.
- Machine-local state, backups, checkpoints, and portable baselines live under `${XDG_STATE_HOME:-$HOME/.local/state}/dots`, never in the repository.
- Authentication targets listed as unmanaged must not be opened, copied, projected, or logged.

## Configuration Changes and Drift

- When changing or encountering drift in managed config, classify it: track deliberate cross-machine behavior, keep machine/account/runtime state local, never track credentials, and discard accidental noise.
- Make obvious classifications and update the source or policy autonomously; ask only when a change represents a genuine user preference.
- Run staged drift checks before committing and fail closed on ambiguous or potentially sensitive drift.

## Repo Structure

- `chezmoi/` - canonical source state rendered into `$HOME`
- `config/portable/` and `config/policies/` - portable intent and mixed-file ownership rules
- `scripts/dotfiles-state` - validate, apply, preview, adopt, rollback, baseline, and drift interface
- `Brewfile` - cross-platform CLI tools
- `Brewfile.macos` - macOS-only tools and casks
- `install.sh` - full bootstrap: brew, cargo, chezmoi, and setup steps
- `tests/portability/` - isolated synthetic-home acceptance suite
- `ITEMS.md` - outstanding TODO items

## Git

Use `/usr/bin/git` instead of `git` to avoid SCM Breeze wrapper conflicts.

## Lessons

- Linear implementation workflows: prefer the two-layer supervisor-owned task loop; keep native sub-agent dispatch at the supervisor level and use task/review/fix/merge workers for bounded work. See [docs/lessons/2026-05-21-supervisor-mediated-subagents.md](docs/lessons/2026-05-21-supervisor-mediated-subagents.md).

## Secrets and Credentials

When an untracked file appears to contain secrets, credentials, tokens, or private keys, immediately add a narrowly scoped `.gitignore` rule for that path before continuing.

Prefer exact file paths or tool-specific runtime directories over broad patterns, and do not open or print the contents of suspected secret files.
