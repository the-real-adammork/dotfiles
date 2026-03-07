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
