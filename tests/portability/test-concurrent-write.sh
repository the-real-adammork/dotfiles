#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
new_fixture

cp "$REPO/chezmoi/dot_zshrc.tmpl" "$HOME/.zshrc"
gate="$FIXTURE_ROOT/concurrent-gate"
DOTFILES_TEST_CONCURRENT_GATE="$gate" \
    "$REPO/scripts/dotfiles-state" adopt --home "$HOME" --only zsh --yes \
    >"$FIXTURE_ROOT/adopt.out" 2>"$FIXTURE_ROOT/adopt.err" &
pid=$!
for _ in {1..100}; do
    [[ -e "$gate.ready" ]] && break
    sleep 0.05
done
[[ -e "$gate.ready" ]] || { echo "adoption did not reach concurrency gate" >&2; kill "$pid" 2>/dev/null || true; exit 1; }
printf '\n# newer application write\n' >> "$HOME/.zshrc"
touch "$gate.release"
if wait "$pid"; then
    echo "concurrent write unexpectedly passed adoption" >&2
    exit 1
fi
assert_contains "$HOME/.zshrc" '# newer application write'
assert_contains "$FIXTURE_ROOT/adopt.err" 'concurrent write detected'

printf 'concurrent-write: ok\n'
