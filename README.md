# dotfiles

Portable personal configuration and system setup, rendered with chezmoi while preserving machine-local and account-local state.

## Quick Start

```bash
git clone git@github.com:<username>/dotfiles.git ~/dots
cd ~/dots
./install.sh
```

On macOS, the bootstrap may request an administrator password to select the
full Xcode installation and complete its first-launch setup. This accepts the
Xcode license and installs required components automatically.

This installs the required day-one macOS apps and development tools. Install the
nonessential creative, media, utility, and App Store apps later with:

```bash
./install-optional-macos.sh
```

## Selective Install

```bash
./install.sh --only tmux,nvim,zsh
```

## Preview and Apply

```bash
scripts/dotfiles-state validate
scripts/dotfiles-state preview
scripts/dotfiles-state apply --only tmux
```

## Structure

Portable source lives under `chezmoi/`. Logical groups and platform constraints are declared in `config/managed-targets.toml`; physical source layout is no longer the `--only` interface.

Codex and Claude settings are mixed files. Tracked overlays contain portable choices; modifiers preserve project trust, hook trust, app metadata, marketplace revisions, and other declared local state. Authentication files are unmanaged.

## Existing-machine Adoption

Legacy Stow symlinks are never overwritten by an ordinary apply. Review the complete dry run, then explicitly adopt:

```bash
scripts/dotfiles-state preview
scripts/dotfiles-state adopt --yes
```

For a bounded migration, preview and adopt the same logical groups:

```bash
scripts/dotfiles-state preview --only zsh,git
scripts/dotfiles-state adopt --only zsh,git --yes
```

Private backups and transaction checkpoints are stored under `${XDG_STATE_HOME:-$HOME/.local/state}/dots`. Restore the latest adoption backup with `scripts/dotfiles-state rollback`.

## Capturing and Checking Drift

After a verified apply/adoption, initialize semantic baselines with `scripts/dotfiles-state baseline`. Review a live portable change with `scripts/dotfiles-state capture codex` (or `claude`), then persist it with `--write` and stage the resulting portable overlay. Run `scripts/dotfiles-state drift` manually; Lefthook runs `scripts/dotfiles-state drift --staged` before commits. Portable changes must be represented by staged source, while declared local-only drift is allowed.

## Adding a New Package

1. Add the formula/cask to the appropriate Brewfile when the config references a new binary.
2. Add the target under `chezmoi/` using chezmoi source-state naming.
3. Declare its logical group and platform in `config/managed-targets.toml`.
4. Add a semantic policy before managing any application-mutated file.
5. Run `tests/portability/run.sh` and re-run `./install.sh`.

Apps that no tracked configuration or tool depends on may instead go in
`Brewfile.macos.optional`; any additional setup belongs in
`install-optional-macos.sh`.
