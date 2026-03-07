#!/usr/bin/env bash
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_DIRS="docs .git"
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

if command -v brew &>/dev/null; then
    info "Installing shared tools from Brewfile..."
    brew bundle --file="$DOTS_DIR/Brewfile"
    if [[ "$OS" == "Darwin" && -f "$DOTS_DIR/Brewfile.macos" ]]; then
        info "Installing macOS tools from Brewfile.macos..."
        brew bundle --file="$DOTS_DIR/Brewfile.macos"
    fi
else
    warn "Homebrew not available, skipping package installation."
fi

# --- TPM (Tmux Plugin Manager) ---
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    ok "TPM already installed"
fi

# --- Stow ---
if ! command -v stow &>/dev/null; then
    echo "Error: stow is not installed. Install it and re-run."
    exit 1
fi

# Discover packages (top-level dirs, excluding SKIP_DIRS)
packages=()
for dir in "$DOTS_DIR"/*/; do
    pkg="$(basename "$dir")"
    skip=false
    for s in $SKIP_DIRS; do
        [[ "$pkg" == "$s" ]] && skip=true
    done
    $skip && continue
    packages+=("$pkg")
done

# Filter to --only if provided
if [[ -n "$ONLY" ]]; then
    IFS=',' read -ra selected <<< "$ONLY"
    filtered=()
    for pkg in "${selected[@]}"; do
        pkg="$(echo "$pkg" | xargs)"  # trim whitespace
        if [[ -d "$DOTS_DIR/$pkg" ]]; then
            filtered+=("$pkg")
        else
            warn "Package not found: $pkg"
        fi
    done
    packages=("${filtered[@]}")
fi

# Stow each package
info "Stowing packages..."
for pkg in "${packages[@]}"; do
    info "  Stowing $pkg"
    stow -d "$DOTS_DIR" -t "$HOME" --restow "$pkg"
done

# --- Summary ---
echo ""
ok "Done! Stowed ${#packages[@]} packages:"
for pkg in "${packages[@]}"; do
    echo "  - $pkg"
done
