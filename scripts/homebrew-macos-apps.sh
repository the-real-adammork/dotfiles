#!/usr/bin/env bash

# List casks separately so one broken app cannot stop Homebrew Bundle from
# processing the rest of Brewfile.macos.
homebrew_macos_casks() {
    brew bundle list --file="$1" --cask
}

homebrew_install_or_upgrade_cask() {
    local cask="$1"

    if brew list --cask "$cask" &>/dev/null; then
        brew upgrade --cask "$cask"
    else
        brew install --cask "$cask"
    fi
}
