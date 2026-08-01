#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
source "$REPO/scripts/homebrew-macos-apps.sh"

FIXTURE_ROOT="$(mktemp -d)"
CALL_LOG="$FIXTURE_ROOT/calls.log"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

brew() {
    printf '%s\n' "$*" >>"$CALL_LOG"
    case "$*" in
        "bundle list --file="*" --cask")
            printf '%s\n' google-chrome slack
            ;;
        "list --cask google-chrome")
            return 0
            ;;
        "upgrade --cask google-chrome")
            return 1
            ;;
        "list --cask slack")
            return 1
            ;;
        "install --cask slack")
            return 0
            ;;
    esac
}

casks="$(homebrew_macos_casks "$REPO/Brewfile.macos")"
[[ "$casks" == $'google-chrome\nslack' ]]

if homebrew_install_or_upgrade_cask google-chrome; then
    echo "failing Chrome upgrade was masked" >&2
    exit 1
fi
homebrew_install_or_upgrade_cask slack

assert_contains "$CALL_LOG" 'upgrade --cask google-chrome'
assert_contains "$CALL_LOG" 'install --cask slack'
assert_contains "$REPO/install.sh" 'continuing with the remaining macOS apps'
assert_contains "$REPO/install.sh" 'macOS dependency failure(s)'
assert_contains "$REPO/upgrade.sh" 'Upgrading macOS app: $cask'

printf 'Homebrew macOS app resilience test passed.\n'
