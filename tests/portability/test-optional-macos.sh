#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"

BASE="$REPO/Brewfile.macos"
OPTIONAL="$REPO/Brewfile.macos.optional"
BASE_INSTALLER="$REPO/install.sh"
OPTIONAL_INSTALLER="$REPO/install-optional-macos.sh"

assert_active() {
    local file="$1" entry="$2"
    rg -q -- "^${entry}$" "$file" || {
        echo "missing active '$entry' in $file" >&2
        exit 1
    }
}

assert_not_active() {
    local file="$1" entry="$2"
    ! rg -q -- "^${entry}$" "$file" || {
        echo "unexpected active '$entry' in $file" >&2
        exit 1
    }
}

active_inventory() {
    rg '^(cask|mas) "' "$1" | LC_ALL=C sort
}

[[ -x "$OPTIONAL_INSTALLER" ]] || {
    echo "install-optional-macos.sh is not executable" >&2
    exit 1
}
bash -n "$BASE_INSTALLER"
bash -n "$OPTIONAL_INSTALLER"

optional_casks=(
    adobe-creative-cloud discord postico backblaze daisydisk hazel switchresx
    ableton-live-suite audacity blackhole-16ch obs optimus-player qbittorrent soundsource
    transmission vlc
)
optional_mas=(
    'mas "Shazam", id: 897118787'
    'mas "3Hub", id: 427515976'
    'mas "Color Picker", id: 641027709'
)

expected_inventory="$({
    for cask in "${optional_casks[@]}"; do
        printf 'cask "%s"\n' "$cask"
    done
    printf '%s\n' "${optional_mas[@]}"
} | LC_ALL=C sort)"
actual_inventory="$(active_inventory "$OPTIONAL")"
if [[ "$actual_inventory" != "$expected_inventory" ]]; then
    diff -u \
        <(printf '%s\n' "$expected_inventory") \
        <(printf '%s\n' "$actual_inventory") || true
    echo "optional Brewfile inventory differs from the requested list" >&2
    exit 1
fi

for cask in "${optional_casks[@]}"; do
    assert_not_active "$BASE" "cask \"$cask\""
done
for entry in "${optional_mas[@]}"; do
    assert_not_active "$BASE" "$entry"
done

basic_casks=(brave-browser signal slack chatgpt 1password moom)
for cask in "${basic_casks[@]}"; do
    entry="cask \"$cask\""
    assert_active "$BASE" "$entry"
    assert_not_active "$OPTIONAL" "$entry"
done
assert_not_active "$BASE" 'cask "hive-app"'

# Unmentioned macOS packages remain part of the day-one setup.
for cask in telegram docker-desktop gpg-suite postgres-app; do
    assert_active "$BASE" "cask \"$cask\""
done
assert_active "$BASE" 'mas "Xcode", id: 497799835'

# Rosetta and manual media-app downloads belong only to the optional installer.
assert_contains "$OPTIONAL_INSTALLER" 'brew bundle --file="$DOTS_DIR/Brewfile.macos.optional"'
assert_contains "$OPTIONAL_INSTALLER" 'softwareupdate --install-rosetta --agree-to-license'
assert_not_contains "$BASE_INSTALLER" 'softwareupdate --install-rosetta --agree-to-license'
for marker in \
    'SoulseekQt-2025-10-11.dmg' \
    'spek-0.8.5-beta.dmg' \
    'Install_rekordbox_6_8_6.pkg_.zip'; do
    assert_contains "$OPTIONAL_INSTALLER" "$marker"
    assert_not_contains "$BASE_INSTALLER" "$marker"
done
assert_contains "$OPTIONAL_INSTALLER" 'curl -fsSL --connect-timeout 20 --max-time 1800 --retry 3'
assert_contains "$OPTIONAL_INSTALLER" 'PARTIAL_APP="/Applications/.$name.installing.$$"'
assert_contains "$OPTIONAL_INSTALLER" 'mv "$PARTIAL_APP" "$app_path"'

printf 'Optional macOS installer tests passed.\n'
