#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
new_fixture

"$REPO/scripts/dotfiles-state" apply --home "$HOME" --only zsh
assert_file "$HOME/.zshrc"
[[ ! -e "$HOME/.tmux.conf" ]] || { echo "--only zsh touched tmux" >&2; exit 1; }
[[ ! -e "$HOME/.codex/config.toml" ]] || { echo "--only zsh touched codex" >&2; exit 1; }

if "$REPO/scripts/dotfiles-state" apply --home "$HOME" --only does-not-exist >/dev/null 2>&1; then
    echo "unknown group unexpectedly passed" >&2
    exit 1
fi

# A known group that has no targets on this platform must never degrade into
# a targetless chezmoi invocation (which would operate on every target).
fake_python="$FIXTURE_ROOT/fake-python"
mkdir -p "$fake_python"
cat > "$fake_python/platform.py" <<'PY'
def system():
    return "Linux"
PY
for command in preview apply; do
    error="$FIXTURE_ROOT/$command-error"
    if PYTHONPATH="$fake_python" "$REPO/scripts/dotfiles-state" "$command" \
        --home "$HOME" --only codex > /dev/null 2>"$error"; then
        echo "$command accepted a group unavailable on the current platform" >&2
        exit 1
    fi
    assert_contains "$error" "selected logical group(s) are unavailable on linux: codex"
done
error="$FIXTURE_ROOT/adopt-error"
if PYTHONPATH="$fake_python" "$REPO/scripts/dotfiles-state" adopt \
    --home "$HOME" --only codex --yes > /dev/null 2>"$error"; then
    echo "adopt accepted a group unavailable on the current platform" >&2
    exit 1
fi
assert_contains "$error" "selected logical group(s) are unavailable on linux: codex"
[[ ! -e "$XDG_STATE_HOME/dots/adoption.json" ]] || {
    echo "unavailable-platform adoption created a checkpoint" >&2
    exit 1
}

printf 'ownership: ok\n'
