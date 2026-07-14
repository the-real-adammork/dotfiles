#!/usr/bin/env bash
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DOTS_DIR/scripts/claude-plugins.sh"
source "$DOTS_DIR/scripts/install-groups.sh"
ONLY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)
            if [[ $# -lt 2 ]]; then
                echo "Error: --only requires a comma-separated list of packages"
                echo "Usage: ./install.sh [--only pkg1,pkg2,...]"
                exit 1
            fi
            ONLY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./install.sh [--only pkg1,pkg2,...]"
            exit 1
            ;;
    esac
done

info() { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m==> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m==> %s\033[0m\n" "$1"; }

OS="$(uname -s)"
info "Detected OS: $OS"

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
    if [[ "$OS" == "Darwin" ]]; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Ensure brew is on PATH for this session (Apple Silicon)
        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        warn "Homebrew not found. Install packages manually or install Linuxbrew."
    fi
fi

# --- Rosetta 2 (needed for Intel-only MAS apps: 3Hub, Color Picker) ---
if [[ "$OS" == "Darwin" ]] && [[ "$(uname -m)" == "arm64" ]]; then
    if ! /usr/bin/pgrep -q oahd; then
        info "Installing Rosetta 2..."
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    else
        ok "Rosetta 2 already installed"
    fi
fi

if command -v brew &>/dev/null; then
    info "Installing shared tools from Brewfile..."
    brew bundle --file="$DOTS_DIR/Brewfile"
    if [[ "$OS" == "Darwin" && -f "$DOTS_DIR/Brewfile.macos" ]]; then
        # Homebrew may require explicit trust for third-party taps before it
        # will load their formulae from a Brewfile.
        brew tap getsentry/xcodebuildmcp
        brew trust --formula getsentry/xcodebuildmcp/xcodebuildmcp
        info "Installing macOS tools from Brewfile.macos..."
        brew bundle --file="$DOTS_DIR/Brewfile.macos"
    fi
    for formula in ffmpeg-full imagemagick-full; do
        if brew list --formula "$formula" &>/dev/null; then
            info "Linking $formula..."
            brew link "$formula" -f --overwrite
        fi
    done
else
    warn "Homebrew not available, skipping package installation."
fi

# --- IDB client (required by ios-simulator-mcp) ---
if [[ "$OS" == "Darwin" ]]; then
    if command -v pipx &>/dev/null; then
        info "Installing IDB Python client..."
        if pipx list --short | awk '{print $1}' | grep -qx "fb-idb"; then
            pipx upgrade fb-idb
        else
            pipx install fb-idb
        fi
        pipx ensurepath
        ok "IDB Python client installed"
    else
        warn "pipx not found, skipping IDB Python client install."
    fi
fi

# --- Rust (via rustup from Brewfile) ---
if command -v rustup-init &>/dev/null || command -v rustup &>/dev/null; then
    if [ ! -d "$HOME/.cargo" ]; then
        info "Initializing Rust toolchain..."
        rustup-init -y --no-modify-path 2>/dev/null || rustup default stable
    fi
    source "$HOME/.cargo/env"
    info "Installing tree-sitter CLI via cargo..."
    cargo install tree-sitter-cli
else
    warn "rustup not found, skipping Rust setup."
fi

# --- Bat theme cache ---
if command -v bat &>/dev/null; then
    info "Rebuilding bat theme cache..."
    bat cache --build
else
    warn "bat not found, skipping theme cache build."
fi

# --- Mise (version manager for node, python, ruby) ---
if command -v mise &>/dev/null; then
    info "Setting up mise..."
    mise use --global node@lts python@3 ruby@latest
    mise install
    export PATH="$HOME/.local/share/mise/shims:$PATH"
else
    warn "mise not found, skipping language version setup."
fi

# --- PDF to Markdown converter dependencies ---
PDF_MD_VENV="$HOME/.local/share/dotfiles/pdf-to-markdown"
if command -v uv &>/dev/null; then
    info "Installing PDF to Markdown Python dependencies..."
    mkdir -p "$(dirname "$PDF_MD_VENV")"
    if [[ ! -x "$PDF_MD_VENV/bin/python" ]] || ! "$PDF_MD_VENV/bin/python" -c "import pymupdf4llm" &>/dev/null; then
        uv venv "$PDF_MD_VENV"
        uv pip install --python "$PDF_MD_VENV/bin/python" pymupdf4llm pymupdf
    else
        ok "PDF to Markdown dependencies already installed"
    fi
else
    warn "uv not found, skipping PDF to Markdown Python dependencies."
fi

# --- Serena MCP server (referenced by Codex config) ---
if install_group_selected codex; then
    if command -v uv &>/dev/null; then
        info "Installing Serena MCP server..."
        uv tool install --upgrade serena-agent
        ok "Serena MCP server installed"
    else
        warn "uv not found, skipping Serena MCP server install."
    fi
fi

# --- Claude Code (CLI) ---
if install_group_selected claude; then
    if command -v npm &>/dev/null; then
        info "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
        ok "Claude Code installed"
    else
        warn "npm not found, skipping Claude Code install."
    fi
fi

# --- SoulseekQt (no brew cask available) ---
if [[ "$OS" == "Darwin" ]] && ! [ -d "/Applications/SoulseekQt.app" ]; then
    info "Installing SoulseekQt..."
    SLSK_URL="https://f004.backblazeb2.com/file/SoulseekQt/SoulseekQt-2025-10-11.dmg"
    TMP_DMG="/tmp/SoulseekQt.dmg"
    curl -fsSL "$SLSK_URL" -o "$TMP_DMG"
    MOUNT=$(hdiutil attach "$TMP_DMG" -nobrowse | sed -n 's|.*\(/Volumes/.*\)|\1|p')
    cp -R "$MOUNT"/*.app /Applications/
    hdiutil detach "$MOUNT" -force 2>/dev/null
    rm "$TMP_DMG"
    ok "SoulseekQt installed"
else
    ok "SoulseekQt already installed"
fi

# --- Spek (no brew cask available) ---
if [[ "$OS" == "Darwin" ]] && ! [ -d "/Applications/Spek.app" ]; then
    info "Installing Spek..."
    SPEK_URL="https://github.com/alexkay/spek/releases/download/v0.8.5/spek-0.8.5-beta.dmg"
    TMP_DMG="/tmp/Spek.dmg"
    curl -fsSL "$SPEK_URL" -o "$TMP_DMG"
    MOUNT=$(hdiutil attach "$TMP_DMG" -nobrowse | sed -n 's|.*\(/Volumes/.*\)|\1|p')
    cp -R "$MOUNT"/*.app /Applications/
    hdiutil detach "$MOUNT" -force 2>/dev/null
    rm "$TMP_DMG"
    ok "Spek installed"
else
    ok "Spek already installed"
fi

# --- Rekordbox 6 (pinned version, not available via brew) ---
if [[ "$OS" == "Darwin" ]] && ! ls -d /Applications/rekordbox* &>/dev/null; then
    info "Installing Rekordbox 6..."
    RB_URL="https://cdn.rekordbox.com/files/20250610145702/Install_rekordbox_6_8_6.pkg_.zip"
    TMP_ZIP="/tmp/rekordbox6.zip"
    TMP_DIR="/tmp/rekordbox6"
    curl -fsSL "$RB_URL" -o "$TMP_ZIP"
    mkdir -p "$TMP_DIR"
    unzip -qo "$TMP_ZIP" -d "$TMP_DIR"
    PKG=$(find "$TMP_DIR" -name "*.pkg" -type f | head -1)
    if [ -n "$PKG" ]; then
        sudo installer -pkg "$PKG" -target /
        ok "Rekordbox 6 installed"
    else
        warn "No .pkg found in archive, skipping Rekordbox install"
    fi
    rm -rf "$TMP_ZIP" "$TMP_DIR"
else
    ok "Rekordbox already installed"
fi

# --- TPM (Tmux Plugin Manager) ---
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Installing TPM..."
    /usr/bin/git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    ok "TPM already installed"
fi
# Install/update tmux plugins declared in tmux.conf (runs after stow below
# would be ideal, but install_plugins only needs the config readable — we
# re-run it at the end to ensure stowed config is active).

# --- scm_breeze (git shortcuts, sourced from .zshrc) ---
if [ ! -d "$HOME/.scm_breeze" ]; then
    info "Installing scm_breeze..."
    /usr/bin/git clone https://github.com/scmbreeze/scm_breeze.git "$HOME/.scm_breeze"
    "$HOME/.scm_breeze/install.sh"
    # Upstream installer appends a hardcoded-path source line to .zshrc.
    # The stowed .zshrc already has an equivalent $HOME-based line, so
    # strip any duplicate scm_breeze source lines, keeping the first.
    ZSHRC="$DOTS_DIR/zsh/.zshrc"
    [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && ZSHRC="$HOME/.zshrc"
    if [ -f "$ZSHRC" ]; then
        awk '/scm_breeze\.sh/ { if (seen++) next } { print }' "$ZSHRC" > "$ZSHRC.tmp" \
            && mv "$ZSHRC.tmp" "$ZSHRC"
    fi
    ok "scm_breeze installed"
else
    ok "scm_breeze already installed"
fi

# --- Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    /usr/bin/git clone https://github.com/ohmyzsh/ohmyzsh "$HOME/.oh-my-zsh"
    ok "Oh My Zsh installed"
else
    ok "Oh My Zsh already installed"
fi

# Clone zsh plugins into Oh My Zsh custom plugins dir
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
        info "Installing $plugin..."
        /usr/bin/git clone "https://github.com/zsh-users/$plugin" "$ZSH_CUSTOM/plugins/$plugin"
    fi
done

# Codex and Claude hooks are managed fail-closed: provision the shared hook
# before chezmoi renders either integration.
if install_any_group_selected codex claude; then
    SIDEBAR_DIR="$HOME/.tmux/plugins/tmux-agent-sidebar"
    if [[ ! -d "$SIDEBAR_DIR" ]]; then
        info "Installing tmux agent sidebar source..."
        /usr/bin/git clone https://github.com/hiroppy/tmux-agent-sidebar "$SIDEBAR_DIR"
    fi

    if [[ -d "$SIDEBAR_DIR" && ! -x "$SIDEBAR_DIR/bin/tmux-agent-sidebar" ]]; then
        info "Installing tmux agent sidebar binary..."
        "$SIDEBAR_DIR/install-wizard.sh" download-binary
    fi

    if [[ ! -x "$SIDEBAR_DIR/hook.sh" ]]; then
        echo "Error: tmux agent sidebar hook is unavailable: $SIDEBAR_DIR/hook.sh"
        exit 1
    fi

    if install_group_selected claude && command -v claude &>/dev/null; then
        info "Reconciling Claude marketplaces and plugins from portable config..."
        reconcile_claude_plugins "$DOTS_DIR/config/portable/claude.json"
    fi
fi

# --- Chezmoi ---
if ! command -v chezmoi &>/dev/null; then
    echo "Error: chezmoi is not installed. Install it and re-run."
    exit 1
fi

info "Validating chezmoi ownership and source state..."
"$DOTS_DIR/scripts/dotfiles-state" validate

apply_args=()
if [[ -n "$ONLY" ]]; then
    apply_args+=(--only "$ONLY")
fi

info "Applying portable dotfiles with chezmoi..."
if ! "$DOTS_DIR/scripts/dotfiles-state" apply "${apply_args[@]}"; then
    warn "Existing Stow-owned targets require reviewed adoption."
    warn "Run: $DOTS_DIR/scripts/dotfiles-state preview"
    warn "Then, after reviewing the diff: $DOTS_DIR/scripts/dotfiles-state adopt --yes"
    exit 1
fi

# --- Tmux plugins (after stow so tmux.conf is in place) ---
if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    info "Installing tmux plugins via TPM..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

if install_any_group_selected codex claude; then
    info "Enabling tmux agent sidebar integrations..."
    integration_groups=()
    for group in codex claude; do
        install_group_selected "$group" && integration_groups+=("$group")
    done
    info "Initializing portable mixed-config baselines..."
    for group in "${integration_groups[@]}"; do
        "$DOTS_DIR/scripts/dotfiles-state" baseline "$group"
    done
    if command -v lefthook &>/dev/null; then
        lefthook install
    fi
fi

# --- Summary ---
echo ""
ok "Done! Portable dotfiles are managed by chezmoi."
