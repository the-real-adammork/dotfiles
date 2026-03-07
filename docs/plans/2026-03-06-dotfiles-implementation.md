# Dotfiles Management System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a GNU Stow-based dotfiles repo with a bootstrap script that sets up a new machine from `./install.sh`.

**Architecture:** Stow packages as top-level directories mirroring `~`. A single `install.sh` handles Homebrew installation, brew bundle, and stowing. Brewfiles split into shared and macOS-only.

**Tech Stack:** Bash, GNU Stow, Homebrew, Brewfile

---

### Task 1: Create Brewfiles

**Files:**
- Create: `Brewfile`
- Create: `Brewfile.macos`

**Step 1: Create the shared Brewfile**

```ruby
# Brewfile - cross-platform CLI tools
brew "stow"
brew "tmux"
brew "neovim"
brew "tig"
brew "ranger"
brew "scm_breeze"
```

**Step 2: Create the macOS Brewfile**

```ruby
# Brewfile.macos - macOS-only tools and casks
# Add casks and macOS-specific formulae here, e.g.:
# cask "iterm2"
# cask "rectangle"
```

**Step 3: Commit**

```bash
git add Brewfile Brewfile.macos
git commit -m "feat: add Brewfiles for cross-platform and macOS tools"
```

---

### Task 2: Create stow package directories with placeholder configs

**Files:**
- Create: `tmux/.tmux.conf`
- Create: `nvim/.config/nvim/init.lua`
- Create: `zsh/.zshrc`
- Create: `zsh/.zshenv`
- Create: `tig/.tigrc`
- Create: `scm_breeze/.scmbrc`
- Create: `claude/.claude/settings.json`
- Create: `ranger/.config/ranger/rc.conf`
- Create: `git/.gitconfig`
- Create: `git/.gitignore_global`

**Step 1: Create all directories**

```bash
mkdir -p tmux
mkdir -p nvim/.config/nvim
mkdir -p zsh
mkdir -p tig
mkdir -p scm_breeze
mkdir -p claude/.claude
mkdir -p ranger/.config/ranger
mkdir -p git
```

**Step 2: Create placeholder config files**

Each file gets a minimal comment header so it's not empty. The user will fill in their actual config later.

`tmux/.tmux.conf`:
```conf
# tmux configuration
```

`nvim/.config/nvim/init.lua`:
```lua
-- neovim configuration
```

`zsh/.zshrc`:
```zsh
# zsh interactive shell configuration
```

`zsh/.zshenv`:
```zsh
# zsh environment variables (loaded for all shell types)
```

`tig/.tigrc`:
```conf
# tig configuration
```

`scm_breeze/.scmbrc`:
```bash
# scm_breeze configuration
```

`claude/.claude/settings.json`:
```json
{}
```

`ranger/.config/ranger/rc.conf`:
```conf
# ranger configuration
```

`git/.gitconfig`:
```gitconfig
# git configuration
```

`git/.gitignore_global`:
```gitignore
# global gitignore patterns
.DS_Store
*.swp
*.swo
*~
```

**Step 3: Commit**

```bash
git add tmux/ nvim/ zsh/ tig/ scm_breeze/ claude/ ranger/ git/
git commit -m "feat: add stow package directories with placeholder configs"
```

---

### Task 3: Create install.sh

**Files:**
- Create: `install.sh`

**Step 1: Write the install script**

```bash
#!/usr/bin/env bash
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_DIRS="docs .git"
ONLY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)
            ONLY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./install.sh [--only pkg1,pkg2,...]"
            exit 1
            ;;
    esac
done

info() { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m==> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m==> %s\033[0m\n" "$1"; }

OS="$(uname -s)"
info "Detected OS: $OS"

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
    if [[ "$OS" == "Darwin" ]]; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        warn "Homebrew not found. Install packages manually or install Linuxbrew."
    fi
fi

if command -v brew &>/dev/null; then
    info "Installing shared tools from Brewfile..."
    brew bundle --file="$DOTS_DIR/Brewfile" --no-lock

    if [[ "$OS" == "Darwin" && -f "$DOTS_DIR/Brewfile.macos" ]]; then
        info "Installing macOS tools from Brewfile.macos..."
        brew bundle --file="$DOTS_DIR/Brewfile.macos" --no-lock
    fi
else
    warn "Homebrew not available, skipping package installation."
fi

# --- Stow ---
if ! command -v stow &>/dev/null; then
    echo "Error: stow is not installed. Install it and re-run."
    exit 1
fi

# Discover packages (top-level dirs, excluding SKIP_DIRS)
packages=()
for dir in "$DOTS_DIR"/*/; do
    pkg="$(basename "$dir")"
    skip=false
    for s in $SKIP_DIRS; do
        [[ "$pkg" == "$s" ]] && skip=true
    done
    $skip && continue
    packages+=("$pkg")
done

# Filter to --only if provided
if [[ -n "$ONLY" ]]; then
    IFS=',' read -ra selected <<< "$ONLY"
    filtered=()
    for pkg in "${selected[@]}"; do
        pkg="$(echo "$pkg" | xargs)"  # trim whitespace
        if [[ -d "$DOTS_DIR/$pkg" ]]; then
            filtered+=("$pkg")
        else
            warn "Package not found: $pkg"
        fi
    done
    packages=("${filtered[@]}")
fi

# Stow each package
info "Stowing packages..."
for pkg in "${packages[@]}"; do
    info "  Stowing $pkg"
    stow -d "$DOTS_DIR" -t "$HOME" --restow "$pkg"
done

# --- Summary ---
echo ""
ok "Done! Stowed ${#packages[@]} packages:"
for pkg in "${packages[@]}"; do
    echo "  - $pkg"
done
```

**Step 2: Make it executable**

```bash
chmod +x install.sh
```

**Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: add idempotent bootstrap install script"
```

---

### Task 4: Add .stow-local-ignore

**Files:**
- Create: `.stow-local-ignore`

**Step 1: Create ignore file**

This prevents stow from symlinking repo metadata and docs into `~`.

```
\.git
docs
README\.md
Brewfile.*
install\.sh
LICENSE
\.stow-local-ignore
```

**Step 2: Commit**

```bash
git add .stow-local-ignore
git commit -m "feat: add stow ignore file to exclude repo metadata"
```

---

### Task 5: Update README

**Files:**
- Modify: `README.md`

**Step 1: Update README with usage instructions**

```markdown
# dotfiles

Personal configuration files and system setup.

## Quick Start

```bash
git clone git@github.com:<username>/dotfiles.git ~/dots
cd ~/dots
./install.sh
```

## Selective Install

```bash
./install.sh --only tmux,nvim,zsh
```

## Manual Stow

```bash
cd ~/dots
stow tmux      # symlinks tmux config
stow -D tmux   # removes tmux symlinks
```

## Structure

Each top-level directory is a stow package mirroring `~`:

| Package     | Config files                  |
|-------------|-------------------------------|
| tmux        | `.tmux.conf`                  |
| nvim        | `.config/nvim/init.lua`       |
| zsh         | `.zshrc`, `.zshenv`           |
| tig         | `.tigrc`                      |
| scm_breeze  | `.scmbrc`                     |
| claude      | `.claude/settings.json`       |
| ranger      | `.config/ranger/rc.conf`      |
| git         | `.gitconfig`, `.gitignore_global` |

## Adding a New Package

1. Create a directory: `mkdir -p newpkg/.config/newpkg`
2. Add config files mirroring their home directory path
3. Run `stow newpkg` or re-run `./install.sh`
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with usage instructions"
```

---

### Task 6: Test the full flow

**Step 1: Verify stow works with a dry run**

```bash
cd ~/dots
stow -n -v tmux 2>&1
```

Expected: shows what symlinks would be created, no errors.

**Step 2: Run install.sh with --only on one package**

```bash
./install.sh --only tmux
```

Expected: stows tmux successfully, prints summary.

**Step 3: Verify the symlink was created**

```bash
ls -la ~/.tmux.conf
```

Expected: symlink pointing to `~/dots/tmux/.tmux.conf`.

**Step 4: Run install.sh again (idempotency check)**

```bash
./install.sh --only tmux
```

Expected: completes without errors (restow is idempotent).

**Step 5: Clean up test symlink**

```bash
stow -d ~/dots -t ~ -D tmux
```
