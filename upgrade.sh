#!/usr/bin/env bash
set -uo pipefail

DOTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DOTS_DIR/scripts/homebrew-bootstrap.sh"
source "$DOTS_DIR/scripts/homebrew-macos-apps.sh"

# Match install.sh when invoked from a translated shell on Apple Silicon.
homebrew_restart_native "$0" "$@"

OS="$(uname -s)"
failures=()

info() { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m==> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m==> %s\033[0m\n" "$1"; }

run_step() {
    local label="$1"
    shift
    info "$label..."
    if "$@"; then
        ok "$label complete"
    else
        warn "$label failed"
        failures+=("$label")
    fi
}

if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew is required. Run ./install.sh first." >&2
    exit 1
fi

run_step "Updating Homebrew metadata" brew update
run_step "Upgrading shared Brewfile dependencies" \
    brew bundle upgrade --file="$DOTS_DIR/Brewfile"

if [[ "$OS" == "Darwin" ]]; then
    # Homebrew requires explicit trust before loading these third-party
    # formulae from Brewfile.macos.
    run_step "Trusting the IDB companion formula" \
        brew trust --formula facebook/fb/idb-companion
    run_step "Trusting the XcodeBuildMCP formula" \
        brew trust --formula getsentry/xcodebuildmcp/xcodebuildmcp
    if macos_casks="$(homebrew_macos_casks "$DOTS_DIR/Brewfile.macos")"; then
        run_step "Upgrading required macOS formulae and App Store dependencies" \
            env HOMEBREW_BUNDLE_CASK_SKIP="$macos_casks" \
            brew bundle upgrade --file="$DOTS_DIR/Brewfile.macos"

        while IFS= read -r cask; do
            [[ -n "$cask" ]] || continue
            run_step "Upgrading macOS app: $cask" \
                homebrew_install_or_upgrade_cask "$cask"
        done <<<"$macos_casks"
    else
        warn "Could not list casks from Brewfile.macos"
        failures+=("Brewfile.macos cask inventory")
    fi
fi

if command -v rtk &>/dev/null; then
    run_step "Refreshing RTK Codex integration" rtk init --global --codex
fi

if command -v mise &>/dev/null; then
    run_step "Upgrading Mise-managed runtimes" \
        mise upgrade --yes node python ruby pnpm
fi

if command -v rustup &>/dev/null; then
    run_step "Upgrading the Rust toolchain" rustup update stable
fi

if command -v cargo &>/dev/null; then
    run_step "Upgrading tree-sitter CLI" cargo install tree-sitter-cli
fi

if [[ "$OS" == "Darwin" ]] && command -v pipx &>/dev/null; then
    if pipx list --short | awk '{print $1}' | grep -qx "fb-idb"; then
        run_step "Upgrading IDB Python client" pipx upgrade fb-idb
    fi
fi

if command -v npm &>/dev/null && npm list -g @anthropic-ai/claude-code --depth=0 &>/dev/null; then
    run_step "Upgrading Claude Code" \
        npm install -g @anthropic-ai/claude-code@latest
fi

if command -v bat &>/dev/null; then
    run_step "Rebuilding bat theme cache" bat cache --build
fi

if [[ "$OS" == "Darwin" ]]; then
    xcode_developer_dir="/Applications/Xcode.app/Contents/Developer"
    if [[ -d "$xcode_developer_dir" ]] && ! /usr/bin/xcodebuild -checkFirstLaunchStatus &>/dev/null; then
        run_step "Completing Xcode upgrade setup" \
            sudo /usr/bin/xcodebuild -runFirstLaunch
    fi
fi

if (( ${#failures[@]} > 0 )); then
    printf '\nUpgrade completed with %d failure(s):\n' "${#failures[@]}" >&2
    printf '  - %s\n' "${failures[@]}" >&2
    exit 1
fi

ok "Required CLI and macOS dependencies are up to date"
