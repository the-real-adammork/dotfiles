#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

export HOME="$FIXTURE_ROOT/home"
export CARGO_HOME="$FIXTURE_ROOT/cargo"
FAKE_BIN="$FIXTURE_ROOT/bin"
FAKE_CARGO="$FIXTURE_ROOT/cargo-fixture"
CALL_LOG="$FIXTURE_ROOT/calls.log"
mkdir -p "$HOME/.cargo" "$FAKE_BIN"
export CALL_LOG FAKE_CARGO

cat >"$FAKE_CARGO" <<'SH'
#!/usr/bin/env bash
printf 'cargo %s\n' "$*" >>"$CALL_LOG"
SH

cat >"$FAKE_BIN/rustup-init" <<'SH'
#!/usr/bin/env bash
printf 'rustup-init %s\n' "$*" >>"$CALL_LOG"
mkdir -p "$CARGO_HOME/bin"
cp "$FAKE_CARGO" "$CARGO_HOME/bin/cargo"
SH

chmod +x "$FAKE_BIN/rustup-init" "$FAKE_CARGO"
RG="$(command -v rg)"
export PATH="$FAKE_BIN:/usr/bin:/bin"

info() { :; }
warn() { :; }

rust_block="$(sed -n '/^# --- Rust /,/^# --- Bat /p' "$REPO/install.sh" | sed '$d')"
set +e
eval "$rust_block"
rust_status=$?
set -e
[[ "$rust_status" -eq 0 ]] || {
    echo "Rust bootstrap block failed when rustup-init omitted the Cargo env file" >&2
    exit 1
}

"$RG" -qx --fixed-strings 'rustup-init -y --no-modify-path' "$CALL_LOG" || {
    echo "Rust initialization was skipped when ~/.cargo existed without ~/.cargo/env" >&2
    exit 1
}
"$RG" -qx --fixed-strings 'cargo install tree-sitter-cli' "$CALL_LOG" || {
    echo "tree-sitter CLI was not installed after Rust initialization" >&2
    exit 1
}

[[ ! -e "$CARGO_HOME/env" ]] || {
    echo "Rust bootstrap fixture unexpectedly created a Cargo env file" >&2
    exit 1
}
CARGO_HOME="$CARGO_HOME" PATH="/usr/bin:/bin" /bin/zsh -c '
    source "$1"
    [[ "$PATH" == "$CARGO_HOME/bin:"* ]]
' _ "$REPO/chezmoi/dot_zshenv" || {
    echo "canonical .zshenv did not add CARGO_HOME/bin without an env file" >&2
    exit 1
}

# Current Homebrew packages rustup as keg-only and exposes cargo from its
# formula bin directory rather than through a Cargo env file.
rm "$FAKE_BIN/rustup-init"
rm -rf "$CARGO_HOME"
: >"$CALL_LOG"
HOMEBREW_RUSTUP="$FIXTURE_ROOT/homebrew-rustup"
mkdir -p "$HOMEBREW_RUSTUP/bin"
cp "$FAKE_CARGO" "$HOMEBREW_RUSTUP/bin/cargo"
cat >"$HOMEBREW_RUSTUP/bin/rustup" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat >"$FAKE_BIN/brew" <<SH
#!/usr/bin/env bash
[[ "\$*" == "--prefix rustup" ]] || exit 1
printf '%s\n' "$HOMEBREW_RUSTUP"
SH
chmod +x "$HOMEBREW_RUSTUP/bin/rustup" "$FAKE_BIN/brew"

set +e
eval "$rust_block"
rust_status=$?
set -e
[[ "$rust_status" -eq 0 ]] || {
    echo "Rust bootstrap block failed with Homebrew's keg-only rustup layout" >&2
    exit 1
}
"$RG" -qx --fixed-strings 'cargo install tree-sitter-cli' "$CALL_LOG" || {
    echo "Homebrew's keg-only cargo proxy was not used" >&2
    exit 1
}
CARGO_HOME="$CARGO_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" /bin/zsh -c '
    source "$1"
    [[ "$PATH" == "$CARGO_HOME/bin:$2/bin:"* ]]
' _ "$REPO/chezmoi/dot_zshenv" "$HOMEBREW_RUSTUP" || {
    echo "canonical .zshenv did not add Homebrew's keg-only rustup bin" >&2
    exit 1
}

printf 'Rust bootstrap portability test passed.\n'
