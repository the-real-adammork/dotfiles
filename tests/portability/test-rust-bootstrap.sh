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

# The installer must also find rustup when Homebrew exposes it only through its
# keg prefix; shell startup tests below exercise a separate code path.
KEG_PREFIX="$FIXTURE_ROOT/keg-only-rustup"
mkdir -p "$KEG_PREFIX/bin"
cp "$FAKE_CARGO" "$KEG_PREFIX/bin/cargo"
cat >"$KEG_PREFIX/bin/rustup" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat >"$FAKE_BIN/brew" <<SH
#!/usr/bin/env bash
[[ "\$*" == "--prefix rustup" ]] || exit 1
printf '%s\n' "$KEG_PREFIX"
SH
chmod +x "$KEG_PREFIX/bin/rustup" "$FAKE_BIN/brew"
rm -f "$FAKE_BIN/rustup-init"
rm -rf "$CARGO_HOME/bin"
: >"$CALL_LOG"
eval "$rust_block"
"$RG" -qx --fixed-strings 'cargo install tree-sitter-cli' "$CALL_LOG" || {
    echo "installer did not use Homebrew's keg-only rustup prefix" >&2
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

# Shell startup must prefer native Apple Silicon, Linux, then Intel rustup.
ARM_PREFIX="$FIXTURE_ROOT/opt/homebrew"
LINUX_PREFIX="$FIXTURE_ROOT/home/linuxbrew/.linuxbrew"
INTEL_PREFIX="$FIXTURE_ROOT/usr/local"
CUSTOM_PREFIX="$FIXTURE_ROOT/custom"
ZSHENV_FIXTURE="$FIXTURE_ROOT/zshenv"
sed \
    -e "s#/opt/homebrew#$ARM_PREFIX#g" \
    -e "s#/home/linuxbrew/.linuxbrew#$LINUX_PREFIX#g" \
    -e "s#/usr/local#$INTEL_PREFIX#g" \
    "$REPO/chezmoi/dot_zshenv" >"$ZSHENV_FIXTURE"
mkdir -p \
    "$ARM_PREFIX/opt/rustup/bin" \
    "$LINUX_PREFIX/opt/rustup/bin" \
    "$INTEL_PREFIX/opt/rustup/bin" \
    "$CUSTOM_PREFIX/opt/rustup/bin" \
    "$CUSTOM_PREFIX/bin"
cat >"$CUSTOM_PREFIX/bin/brew" <<SH
#!/usr/bin/env bash
printf 'brew %s\n' "\$*" >>"$CALL_LOG"
[[ "\$*" == "--prefix rustup" ]] || exit 1
printf '%s\n' "$CUSTOM_PREFIX/opt/rustup"
SH
chmod +x "$CUSTOM_PREFIX/bin/brew"

assert_rustup_path() {
    local expected="$1"
    local path_value="$2"
    CARGO_HOME="$CARGO_HOME" PATH="$path_value" /bin/zsh -f -c '
        source "$1"
        [[ "$path[1]" == "$CARGO_HOME/bin" ]]
        [[ "$path[2]" == "$2" ]]
    ' _ "$ZSHENV_FIXTURE" "$expected"
}

: >"$CALL_LOG"
assert_rustup_path "$ARM_PREFIX/opt/rustup/bin" "$CUSTOM_PREFIX/bin:/usr/bin:/bin"
[[ ! -s "$CALL_LOG" ]] || {
    echo "standard rustup selection unexpectedly spawned Homebrew" >&2
    exit 1
}

rm -rf "$ARM_PREFIX/opt/rustup/bin"
assert_rustup_path "$LINUX_PREFIX/opt/rustup/bin" "/usr/bin:/bin"

rm -rf "$LINUX_PREFIX/opt/rustup/bin"
assert_rustup_path "$INTEL_PREFIX/opt/rustup/bin" "/usr/bin:/bin"

# Nonstandard Homebrew remains a fallback when no standard rustup exists.
rm -rf "$INTEL_PREFIX/opt/rustup/bin"
: >"$CALL_LOG"
assert_rustup_path "$CUSTOM_PREFIX/opt/rustup/bin" "$CUSTOM_PREFIX/bin:/usr/bin:/bin"
"$RG" -qx --fixed-strings 'brew --prefix rustup' "$CALL_LOG" || {
    echo "custom Homebrew rustup fallback was not used" >&2
    exit 1
}

printf 'Rust bootstrap portability test passed.\n'
