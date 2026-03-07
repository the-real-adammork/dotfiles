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
| act         | `.actrc`                      |
| alacritty   | `.alacritty.yml`              |
| bash        | `.bash_profile`               |
| claude      | `.claude/{settings,hooks,commands,skills,agents}` |
| coc         | `.config/coc/memos.json`      |
| gh          | `.config/gh/{config,hosts}.yml` |
| git         | `.gitconfig`, `.config/git/ignore` |
| lvim        | `.config/lvim/{config.lua,ftplugin/}` |
| nvim        | `.config/nvim/init.vim`       |
| ranger      | `.config/ranger/rc.conf`      |
| scm_breeze  | `.scmbrc`                     |
| tig         | `.tigrc`                      |
| tmux        | `.tmux.conf`                  |
| vim         | `.vimrc`                      |
| yarn        | `.yarnrc`                     |
| zsh         | `.zshrc`, `.zshenv`, `.zprofile`, `.p10k.zsh` |

## Single Package on Another Machine

To sync just one package (e.g., claude) to another computer without running the full install:

```bash
git clone git@github.com:<username>/dotfiles.git ~/dots
cd ~/dots
stow claude
```

The only dependency is `stow` (`brew install stow` / `apt install stow` / `dnf install stow`).

## Adding a New Package

1. Create a directory: `mkdir -p newpkg/.config/newpkg`
2. Add config files mirroring their home directory path
3. Run `stow newpkg` or re-run `./install.sh`
