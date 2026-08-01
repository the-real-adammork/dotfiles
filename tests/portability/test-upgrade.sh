#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"

UPGRADE="$REPO/upgrade.sh"

bash -n "$UPGRADE"
assert_contains "$UPGRADE" 'brew bundle upgrade --file="$DOTS_DIR/Brewfile"'
assert_contains "$UPGRADE" 'brew bundle upgrade --file="$DOTS_DIR/Brewfile.macos"'
assert_not_contains "$UPGRADE" 'Brewfile.macos.optional'
assert_contains "$UPGRADE" 'HOMEBREW_BUNDLE_CASK_SKIP="$macos_casks"'
assert_contains "$UPGRADE" 'homebrew_install_or_upgrade_cask "$cask"'
assert_contains "$UPGRADE" 'homebrew_restart_native "$0" "$@"'
assert_contains "$UPGRADE" 'brew trust --formula facebook/fb/idb-companion'
assert_contains "$UPGRADE" 'brew trust --formula getsentry/xcodebuildmcp/xcodebuildmcp'
assert_contains "$UPGRADE" 'rtk init --global --codex'
assert_contains "$UPGRADE" 'mise upgrade --yes node python ruby pnpm'
assert_contains "$UPGRADE" 'rustup update stable'
assert_contains "$UPGRADE" 'cargo install tree-sitter-cli'
assert_contains "$UPGRADE" 'pipx upgrade fb-idb'
assert_contains "$UPGRADE" 'npm install -g @anthropic-ai/claude-code@latest'
assert_contains "$UPGRADE" '/usr/bin/xcodebuild -runFirstLaunch'

printf 'upgrade: ok\n'
