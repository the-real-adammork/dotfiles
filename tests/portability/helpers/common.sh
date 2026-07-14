#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

new_fixture() {
    FIXTURE_ROOT="$(mktemp -d)"
    export HOME="$FIXTURE_ROOT/Users/alex"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CACHE_HOME="$HOME/.cache"
    export DOTFILES_REPO="$REPO"
    export DOTFILES_CODEX_RESOURCES="$FIXTURE_ROOT/CodexResources"
    mkdir -p "$HOME" "$DOTFILES_CODEX_RESOURCES/cua_node/bin" "$DOTFILES_CODEX_RESOURCES/cua_node/lib/node_modules"
    touch "$DOTFILES_CODEX_RESOURCES/cua_node/bin/node_repl" "$DOTFILES_CODEX_RESOURCES/cua_node/bin/node" "$DOTFILES_CODEX_RESOURCES/codex"
    chmod +x "$DOTFILES_CODEX_RESOURCES/cua_node/bin/node_repl" "$DOTFILES_CODEX_RESOURCES/cua_node/bin/node" "$DOTFILES_CODEX_RESOURCES/codex"
    mkdir -p "$HOME/.tmux/plugins/tmux-agent-sidebar"
    touch "$HOME/.tmux/plugins/tmux-agent-sidebar/hook.sh"
    chmod +x "$HOME/.tmux/plugins/tmux-agent-sidebar/hook.sh"
    trap 'rm -rf "$FIXTURE_ROOT"' EXIT
}

assert_file() { [[ -f "$1" ]] || { echo "missing file: $1" >&2; exit 1; }; }
assert_contains() { rg -q --fixed-strings "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }
assert_not_contains() { ! rg -q --fixed-strings "$2" "$1" || { echo "unexpected '$2' in $1" >&2; exit 1; }; }
