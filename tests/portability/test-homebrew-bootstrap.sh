#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE_ROOT="$(mktemp -d)"
CALL_LOG="$FIXTURE_ROOT/calls.log"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

source "$REPO/scripts/homebrew-bootstrap.sh"

# shellenv must update the current session and propagate command failures.
SHELLENV_BREW="$FIXTURE_ROOT/shellenv-brew"
cat >"$SHELLENV_BREW" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == "shellenv" ]]; then
    printf '%s\n' 'export HOMEBREW_PREFIX="/fixture/homebrew"'
    exit "${SHELLENV_EXIT:-0}"
fi
exit 1
SH
chmod +x "$SHELLENV_BREW"
unset HOMEBREW_PREFIX
homebrew_load_shellenv "$SHELLENV_BREW"
[[ "$HOMEBREW_PREFIX" == "/fixture/homebrew" ]] || {
    echo "Homebrew shellenv was not loaded into the installer session" >&2
    exit 1
}
if SHELLENV_EXIT=1 homebrew_load_shellenv "$SHELLENV_BREW"; then
    echo "failing Homebrew shellenv was masked" >&2
    exit 1
fi

fixture_os="Darwin"
fixture_translated="0"
fixture_arm64="1"
fixture_native_brew=false
fixture_path_brew=false
fixture_path_brew_bin="/custom/homebrew/bin/brew"
fixture_install_creates_native=false
fixture_install_creates_intel=false

homebrew_os() {
    printf '%s\n' "$fixture_os"
}

homebrew_sysctl_value() {
    case "$1" in
        sysctl.proc_translated) printf '%s\n' "$fixture_translated" ;;
        hw.optional.arm64) printf '%s\n' "$fixture_arm64" ;;
        *) return 1 ;;
    esac
}

homebrew_exec_native() {
    printf 'exec-native:%s\n' "$*" >>"$CALL_LOG"
}

homebrew_brew_is_executable() {
    case "$1" in
        /opt/homebrew/bin/brew) [[ "$fixture_native_brew" == true ]] ;;
        /usr/local/bin/brew) [[ "$fixture_install_creates_intel" == true ]] ;;
        *) return 1 ;;
    esac
}

homebrew_path_brew() {
    [[ "$fixture_path_brew" == true ]] || return 1
    printf '%s\n' "$fixture_path_brew_bin"
}

homebrew_install_official() {
    printf 'install\n' >>"$CALL_LOG"
    if [[ "$fixture_install_creates_native" == true ]]; then
        fixture_native_brew=true
    fi
}

homebrew_load_shellenv() {
    printf 'shellenv:%s\n' "$1" >>"$CALL_LOG"
}

info() {
    printf 'info:%s\n' "$1" >>"$CALL_LOG"
}

warn() {
    printf 'warn:%s\n' "$1" >>"$CALL_LOG"
}

assert_log() {
    local expected="$1"
    local actual
    actual="$(cat "$CALL_LOG" 2>/dev/null || true)"
    [[ "$actual" == "$expected" ]] || {
        printf 'unexpected Homebrew bootstrap log\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
        exit 1
    }
}

# A translated installer restarts natively and preserves its arguments.
: >"$CALL_LOG"
fixture_translated="1"
homebrew_restart_native "./install.sh" --only codex
assert_log 'exec-native:-arm64 /bin/bash ./install.sh --only codex'

# Native Apple Silicon uses an existing /opt/homebrew installation.
: >"$CALL_LOG"
fixture_translated="0"
fixture_native_brew=true
fixture_install_creates_native=false
homebrew_bootstrap "Darwin"
assert_log 'shellenv:/opt/homebrew/bin/brew'

# Missing native Homebrew is installed and then selected.
: >"$CALL_LOG"
fixture_native_brew=false
fixture_install_creates_native=true
homebrew_bootstrap "Darwin"
assert_log $'info:Installing native Apple Silicon Homebrew...\ninstall\nshellenv:/opt/homebrew/bin/brew'

# An existing custom ARM Homebrew is preserved instead of installing a second copy.
: >"$CALL_LOG"
fixture_native_brew=false
fixture_path_brew=true
fixture_install_creates_native=false
homebrew_bootstrap "Darwin"
assert_log 'shellenv:/custom/homebrew/bin/brew'

# The known Intel prefix is not accepted as native on Apple Silicon.
: >"$CALL_LOG"
fixture_path_brew_bin="/usr/local/bin/brew"
fixture_install_creates_native=true
homebrew_bootstrap "Darwin"
assert_log $'info:Installing native Apple Silicon Homebrew...\ninstall\nshellenv:/opt/homebrew/bin/brew'

# A failed native installation stops instead of falling through to Intel brew.
: >"$CALL_LOG"
fixture_native_brew=false
fixture_path_brew=false
fixture_path_brew_bin="/custom/homebrew/bin/brew"
fixture_install_creates_native=false
if homebrew_bootstrap "Darwin" 2>/dev/null; then
    echo "missing native Homebrew unexpectedly succeeded" >&2
    exit 1
fi
assert_log $'info:Installing native Apple Silicon Homebrew...\ninstall'

# Intel macOS preserves an existing brew and installs only when brew is absent.
: >"$CALL_LOG"
fixture_arm64="0"
fixture_path_brew=true
homebrew_bootstrap "Darwin"
assert_log ''

: >"$CALL_LOG"
fixture_path_brew=false
fixture_install_creates_intel=true
homebrew_bootstrap "Darwin"
assert_log $'info:Installing Homebrew...\ninstall\nshellenv:/usr/local/bin/brew'

# Linux never runs the macOS installer.
: >"$CALL_LOG"
fixture_os="Linux"
homebrew_bootstrap "Linux"
assert_log 'warn:Homebrew not found. Install packages manually or install Linuxbrew.'

printf 'Homebrew bootstrap portability test passed.\n'
