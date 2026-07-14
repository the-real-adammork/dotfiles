#!/usr/bin/env bash
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR=""
ACTIVE_MOUNT=""
PARTIAL_APP=""

info() { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m==> %s\033[0m\n" "$1"; }

cleanup() {
    if [[ -n "$ACTIVE_MOUNT" ]]; then
        hdiutil detach "$ACTIVE_MOUNT" -force &>/dev/null || true
    fi
    if [[ -n "$PARTIAL_APP" ]]; then
        rm -rf "$PARTIAL_APP"
    fi
    if [[ -n "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'Error: this optional installer only supports macOS.\n' >&2
    exit 1
fi

if ! command -v brew &>/dev/null; then
    printf 'Error: Homebrew is required. Run ./install.sh first.\n' >&2
    exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dots-optional-macos.XXXXXX")"

install_dmg_app() {
    local name="$1"
    local app_path="$2"
    local url="$3"
    local dmg="$WORK_DIR/$name.dmg"
    local mount="$WORK_DIR/mount-$name"

    if [[ -d "$app_path" ]]; then
        ok "$name already installed"
        return
    fi

    info "Installing $name..."
    mkdir -p "$mount"
    curl -fsSL --connect-timeout 20 --max-time 1800 --retry 3 "$url" -o "$dmg"
    ACTIVE_MOUNT="$mount"
    hdiutil attach "$dmg" -nobrowse -mountpoint "$mount" >/dev/null
    PARTIAL_APP="/Applications/.$name.installing.$$"
    cp -R "$mount"/*.app "$PARTIAL_APP"
    mv "$PARTIAL_APP" "$app_path"
    PARTIAL_APP=""
    hdiutil detach "$mount" -force >/dev/null
    ACTIVE_MOUNT=""
    ok "$name installed"
}

# Rosetta is needed by the Intel-only 3Hub and Color Picker App Store apps.
if [[ "$(uname -m)" == "arm64" ]]; then
    if ! /usr/bin/pgrep -q oahd; then
        info "Installing Rosetta 2..."
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    else
        ok "Rosetta 2 already installed"
    fi
fi

info "Installing optional apps from Brewfile.macos.optional..."
brew bundle --file="$DOTS_DIR/Brewfile.macos.optional"

# Vendor apps without brew casks
install_dmg_app \
    "SoulseekQt" \
    "/Applications/SoulseekQt.app" \
    "https://f004.backblazeb2.com/file/SoulseekQt/SoulseekQt-2025-10-11.dmg"
install_dmg_app \
    "Spek" \
    "/Applications/Spek.app" \
    "https://github.com/alexkay/spek/releases/download/v0.8.5/spek-0.8.5-beta.dmg"

# Rekordbox 6 (pinned version, not available via brew)
if ! compgen -G '/Applications/rekordbox*' >/dev/null; then
    info "Installing Rekordbox 6..."
    RB_URL="https://cdn.rekordbox.com/files/20250610145702/Install_rekordbox_6_8_6.pkg_.zip"
    TMP_ZIP="$WORK_DIR/rekordbox6.zip"
    TMP_DIR="$WORK_DIR/rekordbox6"
    curl -fsSL --connect-timeout 20 --max-time 1800 --retry 3 "$RB_URL" -o "$TMP_ZIP"
    mkdir -p "$TMP_DIR"
    unzip -qo "$TMP_ZIP" -d "$TMP_DIR"
    PKG=$(find "$TMP_DIR" -type f -name "*.pkg" -print -quit)
    if [[ -n "$PKG" ]]; then
        sudo installer -pkg "$PKG" -target /
        ok "Rekordbox 6 installed"
    else
        printf 'Error: no .pkg found in the Rekordbox archive.\n' >&2
        exit 1
    fi
else
    ok "Rekordbox already installed"
fi

ok "Optional macOS apps installed"
