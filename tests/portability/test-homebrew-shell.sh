#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE_ROOT="$(mktemp -d)"
CALL_LOG="$FIXTURE_ROOT/calls.log"
ARM_PREFIX="$FIXTURE_ROOT/opt/homebrew"
LINUX_PREFIX="$FIXTURE_ROOT/home/linuxbrew/.linuxbrew"
INTEL_PREFIX="$FIXTURE_ROOT/usr/local"
CUSTOM_PREFIX="$FIXTURE_ROOT/custom"
PROFILE_FIXTURE="$FIXTURE_ROOT/zprofile"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

make_fake_brew() {
    local prefix="$1"
    local name="$2"
    mkdir -p "$prefix/bin" "$prefix/share/zsh/site-functions" "$prefix/opt/rustup/bin"
    cat >"$prefix/bin/brew" <<SH
#!/usr/bin/env bash
printf '%s %s\n' "$name" "\$*" >>"$CALL_LOG"
case "\$*" in
    shellenv)
        cat <<'ENV'
export HOMEBREW_PREFIX="$prefix"
export HOMEBREW_CELLAR="$prefix/Cellar"
export HOMEBREW_REPOSITORY="$prefix"
path=("$prefix/bin" "$prefix/sbin" \$path)
fpath=("$prefix/share/zsh/site-functions" \$fpath)
ENV
        ;;
    "--prefix rustup")
        printf '%s\n' "$prefix/opt/rustup"
        ;;
    *) exit 1 ;;
esac
SH
    chmod +x "$prefix/bin/brew"
}

render_profile_fixture() {
    sed \
        -e "s#/opt/homebrew#$ARM_PREFIX#g" \
        -e "s#/home/linuxbrew/.linuxbrew#$LINUX_PREFIX#g" \
        -e "s#/usr/local#$INTEL_PREFIX#g" \
        "$REPO/chezmoi/dot_zprofile" >"$PROFILE_FIXTURE"
}

assert_profile_selects() {
    local expected_prefix="$1"
    local path_value="${2:-/usr/bin:/bin}"
    HOME="$FIXTURE_ROOT/home" PATH="$path_value" /bin/zsh -f -c '
        source "$1"
        [[ "$HOMEBREW_PREFIX" == "$2" ]]
        [[ "$HOMEBREW_REPOSITORY" == "$2" ]]
        [[ " ${fpath[*]} " == *" $2/share/zsh/site-functions "* ]]
    ' _ "$PROFILE_FIXTURE" "$expected_prefix"
}

make_fake_brew "$ARM_PREFIX" arm
make_fake_brew "$LINUX_PREFIX" linux
make_fake_brew "$INTEL_PREFIX" intel
make_fake_brew "$CUSTOM_PREFIX" custom
render_profile_fixture

# Standard locations are preferred native Apple Silicon, Linux, then Intel.
: >"$CALL_LOG"
assert_profile_selects "$ARM_PREFIX"
[[ "$(cat "$CALL_LOG")" == "arm shellenv" ]]

rm "$ARM_PREFIX/bin/brew"
: >"$CALL_LOG"
assert_profile_selects "$LINUX_PREFIX"
[[ "$(cat "$CALL_LOG")" == "linux shellenv" ]]

rm "$LINUX_PREFIX/bin/brew"
: >"$CALL_LOG"
assert_profile_selects "$INTEL_PREFIX"
[[ "$(cat "$CALL_LOG")" == "intel shellenv" ]]

# A nonstandard installation remains available as a last-resort fallback.
rm "$INTEL_PREFIX/bin/brew"
: >"$CALL_LOG"
assert_profile_selects "$CUSTOM_PREFIX" "$CUSTOM_PREFIX/bin:/usr/bin:/bin"
[[ "$(cat "$CALL_LOG")" == "custom shellenv" ]]

printf 'Homebrew shell startup portability test passed.\n'
