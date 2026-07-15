#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
new_fixture

# macOS may expose mktemp paths through /var while Path.resolve() uses
# /private/var. Normalize this fixture so absolute managed paths compare
# consistently during validation.
export HOME="$(cd "$HOME" && pwd -P)"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export DOTFILES_CODEX_RESOURCES="$(cd "$DOTFILES_CODEX_RESOURCES" && pwd -P)"

source "$REPO/scripts/claude-plugins.sh"
source "$REPO/scripts/install-groups.sh"

claude_log="$(mktemp)"
trap 'rm -f "$claude_log"; rm -rf "$FIXTURE_ROOT"' EXIT
claude_marketplaces='[]'
claude_plugins='[]'
claude_add_failure=''
claude_marketplace_add_name='official'

claude() {
  case "$*" in
    "plugin marketplace list --json") printf '%s\n' "$claude_marketplaces" ;;
    "plugin list --json") printf '%s\n' "$claude_plugins" ;;
    "plugin marketplace add "*)
      printf '%s\n' "$*" >>"$claude_log"
      local source="$4"
      if [[ "$source" == "$claude_add_failure" && -n "$claude_add_failure" ]]; then
        return 1
      fi
      if [[ "$source" == /* ]]; then
        claude_marketplaces="$(jq -c --arg name "$claude_marketplace_add_name" --arg path "$source" \
          '. + [{name: $name, source: "directory", path: $path}]' <<<"$claude_marketplaces")"
      else
        claude_marketplaces="$(jq -c --arg name "$claude_marketplace_add_name" --arg repo "$source" \
          '. + [{name: $name, source: "github", repo: $repo}]' <<<"$claude_marketplaces")"
      fi
      ;;
    "plugin enable "*)
      printf '%s\n' "$*" >>"$claude_log"
      local plugin="$3"
      claude_plugins="$(jq -c --arg plugin "$plugin" \
        'map(if .id == $plugin then .enabled = true else . end)' <<<"$claude_plugins")"
      ;;
    "plugin install "*)
      printf '%s\n' "$*" >>"$claude_log"
      local plugin="$3"
      claude_plugins="$(jq -c --arg plugin "$plugin" \
        '. + [{id: $plugin, enabled: true}]' <<<"$claude_plugins")"
      ;;
  esac
}

assert_claude_log() {
  local expected="$1"
  local actual
  actual="$(cat "$claude_log")"
  [[ "$actual" == "$expected" ]] || {
    echo "unexpected Claude reconciliation command: $actual" >&2
    exit 1
  }
}

ensure_claude_marketplace "official" "owner/repo"
assert_claude_log "plugin marketplace add owner/repo"

: >"$claude_log"
claude_marketplaces='[{"name":"official","source":"github","repo":"owner/repo"}]'
ensure_claude_marketplace "official" "owner/repo"
assert_claude_log ""

claude_marketplaces='[{"name":"official","source":"github","repo":"old/repo"}]'
if ensure_claude_marketplace "official" "owner/repo" 2>/dev/null; then
  echo "mismatched GitHub marketplace unexpectedly succeeded" >&2
  exit 1
fi
assert_claude_log ""
jq -e 'any(.[]; .name == "official" and .repo == "old/repo")' <<<"$claude_marketplaces" >/dev/null

: >"$claude_log"
claude_marketplace_add_name='local'
claude_marketplaces='[{"name":"local","source":"directory","path":"/tmp/local-marketplace"}]'
ensure_claude_marketplace "local" "/tmp/local-marketplace"
assert_claude_log ""

claude_marketplaces='[{"name":"local","source":"directory","path":"/tmp/old-marketplace"}]'
if ensure_claude_marketplace "local" "/tmp/local-marketplace" 2>/dev/null; then
  echo "mismatched local marketplace unexpectedly succeeded" >&2
  exit 1
fi
assert_claude_log ""
jq -e 'any(.[]; .name == "local" and .path == "/tmp/old-marketplace")' <<<"$claude_marketplaces" >/dev/null

: >"$claude_log"
claude_marketplace_add_name='official'
claude_marketplaces='[]'
claude_add_failure='owner/repo'
if ensure_claude_marketplace "official" "owner/repo" 2>/dev/null; then
  echo "failed marketplace addition unexpectedly succeeded" >&2
  exit 1
fi
assert_claude_log 'plugin marketplace add owner/repo'
jq -e 'length == 0' <<<"$claude_marketplaces" >/dev/null

: >"$claude_log"
claude_marketplace_add_name='local'
claude_marketplaces='[]'
claude_add_failure='/tmp/local-marketplace'
if ensure_claude_marketplace "local" "/tmp/local-marketplace" 2>/dev/null; then
  echo "failed local marketplace addition unexpectedly succeeded" >&2
  exit 1
fi
assert_claude_log 'plugin marketplace add /tmp/local-marketplace'
jq -e 'length == 0' <<<"$claude_marketplaces" >/dev/null

: >"$claude_log"
claude_add_failure=''
claude_plugins='[{"id":"example@official","enabled":true}]'
ensure_claude_plugin "example@official"
ensure_claude_plugin "example@official"
assert_claude_log ""

claude_plugins='[{"id":"example@official","enabled":false}]'
ensure_claude_plugin "example@official"
assert_claude_log "plugin enable example@official"
ensure_claude_plugin "example@official"
assert_claude_log "plugin enable example@official"

: >"$claude_log"
claude_plugins='[]'
ensure_claude_plugin "example@official"
assert_claude_log "plugin install example@official"
ensure_claude_plugin "example@official"
assert_claude_log "plugin install example@official"

: >"$claude_log"
claude_marketplaces='[]'
claude_plugins='[]'
claude_add_failure=''
reconcile_claude_plugins "$REPO/config/portable/claude.json"
while IFS= read -r plugin; do
  rg -Fq "plugin install $plugin" "$claude_log" || {
    echo "portable enabled Claude plugin was not reconciled: $plugin" >&2
    exit 1
  }
done < <(jq -r '.enabledPlugins | to_entries[] | select(.value == true) | .key' "$REPO/config/portable/claude.json")
assert_contains "$claude_log" "$HOME/.tmux/plugins/tmux-agent-sidebar"

ONLY=""
install_group_selected claude || { echo "full install did not select Claude" >&2; exit 1; }
install_group_selected codex || { echo "full install did not select Codex" >&2; exit 1; }

ONLY="codex"
install_group_selected codex || { echo "Codex-only install did not select Codex" >&2; exit 1; }
if install_group_selected claude; then
  echo "Codex-only install unexpectedly selected Claude" >&2
  exit 1
fi

ONLY=" zsh , codex , claude "
install_group_selected codex || { echo "whitespace-wrapped Codex group was not selected" >&2; exit 1; }
install_group_selected claude || { echo "whitespace-wrapped Claude group was not selected" >&2; exit 1; }
if install_group_selected tmux; then
  echo "unlisted group was unexpectedly selected" >&2
  exit 1
fi

ONLY="codex"
install_any_group_selected codex claude || { echo "Codex did not select shared sidebar setup" >&2; exit 1; }
if install_any_group_selected claude tmux; then
  echo "Codex-only install unexpectedly selected Claude or tmux" >&2
  exit 1
fi

ONLY=""
mkdir -p "$HOME/.tmux/plugins/tmux-agent-sidebar"
touch "$HOME/.tmux/plugins/tmux-agent-sidebar/hook.sh"
chmod +x "$HOME/.tmux/plugins/tmux-agent-sidebar/hook.sh"

# Alternate-home rendering derives fail-closed sidebar state from the
# destination, not from the invoking account's HOME.
alternate_home="$FIXTURE_ROOT/Users/alternate"
mkdir -p "$alternate_home"
if "$REPO/scripts/dotfiles-state" preview --home "$alternate_home" --only codex >/dev/null 2>&1; then
  echo "Codex preview used invoking HOME's sidebar for an alternate destination" >&2
  exit 1
fi
mkdir -p "$alternate_home/.tmux/plugins/tmux-agent-sidebar"
touch "$alternate_home/.tmux/plugins/tmux-agent-sidebar/hook.sh"
chmod +x "$alternate_home/.tmux/plugins/tmux-agent-sidebar/hook.sh"
"$REPO/scripts/dotfiles-state" preview --home "$alternate_home" --only codex >/dev/null

"$REPO/scripts/dotfiles-state" validate >/dev/null
"$REPO/scripts/dotfiles-state" apply --home "$HOME"

assert_file "$HOME/.zshrc"
assert_file "$HOME/.gitconfig"
assert_file "$HOME/.codex/config.toml"
assert_file "$HOME/.claude/settings.json"
assert_not_contains "$HOME/.zshrc" "/Users/adam"
assert_not_contains "$HOME/.gitconfig" "adammork@gmail.com"
assert_contains "$HOME/.codex/config.toml" "$DOTFILES_CODEX_RESOURCES/cua_node/bin/node_repl"
assert_contains "$HOME/.claude/settings.json" "$HOME/.tmux/plugins/tmux-agent-sidebar"
assert_not_contains "$HOME/.codex/config.toml" "__HOME__"
assert_not_contains "$HOME/.codex/config.toml" "__CODEX_"
assert_not_contains "$REPO/install.sh" 'apply --only codex,claude'
assert_contains "$REPO/install.sh" 'uv tool install --upgrade serena-agent'
assert_contains "$REPO/Brewfile" 'brew "git-secret"'
assert_contains "$REPO/install.sh" 'mise use --global node@lts python@3 ruby@latest pnpm@latest'
assert_not_contains "$REPO/Brewfile" 'brew "pnpm"'
mason_tool_installer_block="$(sed -n '/WhoIsSethDaniel\/mason-tool-installer.nvim/,/^  },$/p' "$REPO/chezmoi/dot_config/nvim/init.lua")"
[[ "$mason_tool_installer_block" == *'"goimports"'* ]] || {
  echo "Neovim uses goimports but Mason does not install it" >&2
  exit 1
}
if rg -n '^[[:space:]]*git clone ' "$REPO/install.sh" >/dev/null; then
  echo "install.sh must use /usr/bin/git for clones" >&2
  exit 1
fi

python3 - "$HOME/.codex/config.toml" "$DOTFILES_CODEX_RESOURCES" "$HOME" <<'PY'
import pathlib
import sys
import tomllib

config_path = pathlib.Path(sys.argv[1])
resources = pathlib.Path(sys.argv[2])
home = pathlib.Path(sys.argv[3])
with config_path.open("rb") as handle:
    config = tomllib.load(handle)

assert config["model"] == "gpt-5.6-sol"
assert config["model_reasoning_effort"] == "medium"

node_repl = config["mcp_servers"]["node_repl"]
assert node_repl["command"] == str(resources / "cua_node/bin/node_repl")
assert node_repl["args"] == []
assert node_repl["startup_timeout_sec"] == 120
env = node_repl["env"]
assert env["NODE_REPL_NODE_PATH"] == str(resources / "cua_node/bin/node")
assert env["NODE_REPL_NODE_MODULE_DIRS"] == str(resources / "cua_node/lib/node_modules")
assert env["NODE_REPL_TRUSTED_CODE_PATHS"] == str(home / ".codex")
assert env["CODEX_HOME"] == str(home / ".codex")
assert env["CODEX_CLI_PATH"] == str(resources / "codex")
xcodebuild_mcp = config["mcp_servers"]["XcodeBuildMCP"]
assert xcodebuild_mcp["command"] == "xcodebuildmcp"
assert xcodebuild_mcp["args"] == ["mcp"]
assert config["mcp_servers"]["ios-simulator"]["env"]["IOS_SIMULATOR_MCP_IDB_PATH"] == str(home / ".local/bin/idb")
PY

assert_contains "$REPO/Brewfile.macos" 'tap "getsentry/xcodebuildmcp"'
assert_contains "$REPO/Brewfile.macos" 'brew "xcodebuildmcp"'
assert_contains "$REPO/Brewfile.macos" 'tap "facebook/fb"'
assert_contains "$REPO/Brewfile.macos" 'brew "idb-companion"'
idb_tap_line="$(rg -n -F -m1 'brew tap facebook/fb' "$REPO/install.sh" | cut -d: -f1)"
idb_trust_line="$(rg -n -F -m1 'brew trust --formula facebook/fb/idb-companion' "$REPO/install.sh" | cut -d: -f1)"
xbmcp_tap_line="$(rg -n -F -m1 'brew tap getsentry/xcodebuildmcp' "$REPO/install.sh" | cut -d: -f1)"
xbmcp_trust_line="$(rg -n -F -m1 'brew trust --formula getsentry/xcodebuildmcp/xcodebuildmcp' "$REPO/install.sh" | cut -d: -f1)"
macos_bundle_line="$(rg -n -F -m1 'brew bundle --file="$DOTS_DIR/Brewfile.macos"' "$REPO/install.sh" | cut -d: -f1)"
[[ -n "$idb_tap_line" && -n "$idb_trust_line" && "$idb_tap_line" -lt "$idb_trust_line" && "$idb_trust_line" -lt "$macos_bundle_line" ]] || {
  echo "IDB companion tap must be trusted before the macOS Brewfile is loaded" >&2
  exit 1
}
[[ -n "$xbmcp_tap_line" && -n "$xbmcp_trust_line" && "$xbmcp_tap_line" -lt "$xbmcp_trust_line" && "$xbmcp_trust_line" -lt "$macos_bundle_line" ]] || {
  echo "XcodeBuildMCP tap must be trusted before the macOS Brewfile is loaded" >&2
  exit 1
}
xcode_select_line="$(rg -n -F -m1 'sudo /usr/bin/xcode-select --switch "$XCODE_DEVELOPER_DIR"' "$REPO/install.sh" | cut -d: -f1)"
xcode_first_launch_line="$(rg -n -F -m1 'sudo /usr/bin/xcodebuild -runFirstLaunch' "$REPO/install.sh" | cut -d: -f1)"
assert_contains "$REPO/install.sh" '/usr/bin/xcodebuild -checkFirstLaunchStatus'
[[ -n "$xcode_select_line" && -n "$xcode_first_launch_line" && "$macos_bundle_line" -lt "$xcode_select_line" && "$xcode_select_line" -lt "$xcode_first_launch_line" ]] || {
  echo "Xcode first-launch setup must run after the macOS Brewfile installs Xcode" >&2
  exit 1
}

jq -e --arg sidebar "$HOME/.tmux/plugins/tmux-agent-sidebar/hook.sh" '
  (.hooks | keys | sort) == ["PostToolUse", "SessionStart", "Stop", "UserPromptSubmit"] and
  ([.hooks | to_entries[].value[] | .hooks[] | .command] | sort) == ([
    "bash " + $sidebar + " codex activity-log",
    "bash " + $sidebar + " codex session-start",
    "bash " + $sidebar + " codex stop",
    "bash " + $sidebar + " codex user-prompt-submit"
  ] | sort)
' "$HOME/.codex/hooks.json" >/dev/null || {
  echo "rendered Codex sidebar hooks are incomplete" >&2
  exit 1
}

assert_contains "$REPO/install.sh" 'reconcile_claude_plugins "$DOTS_DIR/config/portable/claude.json"'

tpm_clone_line="$(rg -n -F -m1 '/usr/bin/git clone https://github.com/tmux-plugins/tpm' "$REPO/install.sh" | cut -d: -f1)"
sidebar_clone_line="$(rg -n -F -m1 '/usr/bin/git clone https://github.com/hiroppy/tmux-agent-sidebar' "$REPO/install.sh" | cut -d: -f1)"
apply_line="$(rg -n -F -m1 '"$DOTS_DIR/scripts/dotfiles-state" apply "${apply_args[@]}"' "$REPO/install.sh" | cut -d: -f1)"
tpm_plugins_line="$(rg -n -F -m1 '    "$HOME/.tmux/plugins/tpm/bin/install_plugins"' "$REPO/install.sh" | cut -d: -f1)"
claude_reconcile_line="$(rg -n -m1 'reconcile_claude_plugins ' "$REPO/install.sh" | cut -d: -f1)"
[[ "$tpm_clone_line" -lt "$sidebar_clone_line" && "$sidebar_clone_line" -lt "$claude_reconcile_line" && "$claude_reconcile_line" -lt "$apply_line" && "$apply_line" -lt "$tpm_plugins_line" ]] || {
  echo "Sidebar and Claude plugins must be ready before chezmoi apply; TPM plugins follow rendered tmux config" >&2
  exit 1
}

before="$(find "$HOME" -type f -exec shasum -a 256 {} + | sort | shasum -a 256)"
"$REPO/scripts/dotfiles-state" apply --home "$HOME" >/dev/null
after="$(find "$HOME" -type f -exec shasum -a 256 {} + | sort | shasum -a 256)"
[[ "$before" == "$after" ]] || { echo "second apply changed target state" >&2; exit 1; }

codex_preview="$("$REPO/scripts/dotfiles-state" preview --home "$HOME" --only codex)"
[[ -z "$codex_preview" ]] || {
  echo "Codex preview was not empty after convergence: $codex_preview" >&2
  exit 1
}

printf 'bootstrap: ok\n'
