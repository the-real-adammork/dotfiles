# Dotfiles Management System Design

## Overview

A GNU Stow-based dotfiles repo with a bootstrap script that can set up a new macOS machine (or mostly set up a Linux one) from a single command: `./install.sh`.

## Structure

```
dots/
├── install.sh                # Bootstrap entry point (idempotent)
├── Brewfile                  # Cross-platform CLI tools
├── Brewfile.macos            # macOS-only (casks, GUI apps)
├── tmux/.tmux.conf
├── nvim/.config/nvim/init.lua
├── zsh/.zshrc
├── zsh/.zshenv
├── tig/.tigrc
├── scm_breeze/.scmbrc
├── claude/.claude/settings.json
├── ranger/.config/ranger/rc.conf
├── git/.gitconfig
├── git/.gitignore_global
└── docs/plans/
```

## Stow Convention

Each top-level directory (except `docs/`, `.git/`) is a stow package. Its contents mirror the home directory structure. Running `stow <package>` from `~/dots` creates symlinks in `~`.

## Install Script (install.sh)

Idempotent bash script that:

1. Detects OS (macOS vs Linux)
2. Installs Homebrew if missing (macOS), or warns about manual package installation (Linux)
3. Installs stow if missing (via brew or system package manager)
4. Runs `brew bundle --file=Brewfile` (shared tools)
5. Runs `brew bundle --file=Brewfile.macos` if on macOS
6. Stows all packages by default (auto-discovers directories that aren't `docs/` or `.git/`)
7. Accepts `--only pkg1,pkg2` flag to selectively stow
8. Prints a summary

## Brewfiles

- **Brewfile**: tmux, neovim, tig, ranger, stow, scm-breeze, and other cross-platform CLI tools
- **Brewfile.macos**: macOS casks and Mac-only formulae

## Portability

- Stow works on any unix system
- Config files are inherently portable
- The install script gracefully degrades on Linux (skips Homebrew casks, warns about missing package manager support)
- Platform-specific config can use conditionals within dotfiles themselves (e.g., `if-shell` in tmux, `has()` in vim)

## Excluded by Design

- No macOS defaults/preferences automation
- No secrets management
- No templating (plain config files only)
- No auto-commit or sync mechanism
