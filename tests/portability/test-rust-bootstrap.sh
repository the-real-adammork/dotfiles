#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

export HOME="$FIXTURE_ROOT/home"
FAKE_BIN="$FIXTURE_ROOT/bin"
CALL_LOG="$FIXTURE_ROOT/calls.log"
mkdir -p "$HOME/.cargo" "$FAKE_BIN"
export CALL_LOG

cat >"$FAKE_BIN/rustup-init" <<'SH'
#!/usr/bin/env bash
printf 'rustup-init %s\n' "$*" >>"$CALL_LOG"
touch "$HOME/.cargo/env"
SH

cat >"$FAKE_BIN/cargo" <<'SH'
#!/usr/bin/env bash
printf 'cargo %s\n' "$*" >>"$CALL_LOG"
SH

chmod +x "$FAKE_BIN/rustup-init" "$FAKE_BIN/cargo"
export PATH="$FAKE_BIN:$PATH"

info() { :; }
warn() { :; }

rust_block="$(sed -n '/^# --- Rust /,/^# --- Bat /p' "$REPO/install.sh" | sed '$d')"
eval "$rust_block"

rg -qx --fixed-strings 'rustup-init -y --no-modify-path' "$CALL_LOG" || {
    echo "Rust initialization was skipped when ~/.cargo existed without ~/.cargo/env" >&2
    exit 1
}
rg -qx --fixed-strings 'cargo install tree-sitter-cli' "$CALL_LOG" || {
    echo "tree-sitter CLI was not installed after Rust initialization" >&2
    exit 1
}

printf 'Rust bootstrap portability test passed.\n'
