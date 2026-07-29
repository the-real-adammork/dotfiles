#!/usr/bin/env bash

homebrew_os() {
    uname -s
}

homebrew_sysctl_value() {
    /usr/sbin/sysctl -in "$1" 2>/dev/null || true
}

homebrew_exec_native() {
    exec /usr/bin/arch "$@"
}

homebrew_brew_is_executable() {
    [[ -x "$1" ]]
}

homebrew_path_brew() {
    command -v brew
}

homebrew_install_official() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

homebrew_load_shellenv() {
    local brew_bin="$1"
    local shellenv

    shellenv="$("$brew_bin" shellenv)" || return 1
    eval "$shellenv"
    hash -r
}

homebrew_restart_native() {
    local script="$1"
    shift

    if [[ "$(homebrew_os)" == "Darwin" ]] \
        && [[ "$(homebrew_sysctl_value sysctl.proc_translated)" == "1" ]]; then
        homebrew_exec_native -arm64 /bin/bash "$script" "$@"
        return $?
    fi
}

homebrew_bootstrap() {
    local os="$1"
    local native_brew="/opt/homebrew/bin/brew"
    local intel_brew="/usr/local/bin/brew"
    local path_brew=""

    if [[ "$os" == "Darwin" ]] \
        && [[ "$(homebrew_sysctl_value hw.optional.arm64)" == "1" ]]; then
        if homebrew_brew_is_executable "$native_brew"; then
            homebrew_load_shellenv "$native_brew"
            return
        fi
        if path_brew="$(homebrew_path_brew 2>/dev/null)" \
            && [[ "$path_brew" != "$intel_brew" ]]; then
            homebrew_load_shellenv "$path_brew"
            return
        fi

        if ! homebrew_brew_is_executable "$native_brew"; then
            info "Installing native Apple Silicon Homebrew..."
            homebrew_install_official
        fi
        if ! homebrew_brew_is_executable "$native_brew"; then
            echo "Error: native Homebrew was not installed at /opt/homebrew" >&2
            return 1
        fi
        homebrew_load_shellenv "$native_brew"
    elif path_brew="$(homebrew_path_brew 2>/dev/null)"; then
        :
    elif [[ "$os" == "Darwin" ]]; then
        info "Installing Homebrew..."
        homebrew_install_official
        if ! homebrew_brew_is_executable "$intel_brew"; then
            echo "Error: Homebrew was not installed at /usr/local" >&2
            return 1
        fi
        homebrew_load_shellenv "$intel_brew"
    else
        warn "Homebrew not found. Install packages manually or install Linuxbrew."
    fi
}
