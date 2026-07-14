#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
new_fixture

"$REPO/scripts/dotfiles-state" apply --home "$HOME" >/dev/null
"$REPO/scripts/dotfiles-state" baseline >/dev/null
"$REPO/scripts/dotfiles-state" drift

# Fully owned targets participate in drift detection, not only mixed configs.
printf '\n# uncaptured local edit\n' >> "$HOME/.zshenv"
if "$REPO/scripts/dotfiles-state" drift >/dev/null 2>&1; then
    echo "uncaptured fully owned drift unexpectedly passed" >&2
    exit 1
fi
"$REPO/scripts/dotfiles-state" apply --home "$HOME" --only zsh >/dev/null
"$REPO/scripts/dotfiles-state" drift >/dev/null

sed -i '' 's/model_reasoning_effort = "medium"/model_reasoning_effort = "low"/' "$HOME/.codex/config.toml"
if "$REPO/scripts/dotfiles-state" drift >/dev/null 2>&1; then
    echo "uncaptured portable drift unexpectedly passed" >&2
    exit 1
fi

# Exercise the real staged-candidate path without touching the repository index.
index="$FIXTURE_ROOT/git-index"
export GIT_INDEX_FILE="$index"
/usr/bin/git -C "$REPO" read-tree HEAD
/usr/bin/git -C "$REPO" add -- chezmoi config scripts
if "$REPO/scripts/dotfiles-state" drift --staged >/dev/null 2>&1; then
    echo "uncaptured drift unexpectedly matched staged source" >&2
    exit 1
fi

candidate="$FIXTURE_ROOT/codex-candidate.toml"
sed 's/model_reasoning_effort = "medium"/model_reasoning_effort = "low"/' \
    "$REPO/config/portable/codex.toml" > "$candidate"
blob="$(/usr/bin/git -C "$REPO" hash-object -w "$candidate")"
/usr/bin/git -C "$REPO" update-index --add --cacheinfo \
    "100644,$blob,config/portable/codex.toml"
# Mixed directories may have stricter local permissions because they contain
# unmanaged authentication state; directory-only status must not mask clean
# managed leaf content.
chmod 751 "$HOME/.config/gh"
"$REPO/scripts/dotfiles-state" drift --staged >/dev/null

# Local-only drift passes against the unchanged staged portable source.
sed -i '' 's/model_reasoning_effort = "low"/model_reasoning_effort = "medium"/' "$HOME/.codex/config.toml"
printf '\n[projects."%s/local-only"]\ntrust_level = "trusted"\n' "$HOME" >> "$HOME/.codex/config.toml"
/usr/bin/git -C "$REPO" add -- config/portable/codex.toml
"$REPO/scripts/dotfiles-state" drift --staged >/dev/null

# A new working-tree source that is absent from the index cannot participate
# in the staged candidate, even when it would otherwise match live state.
unstaged_source="$REPO/chezmoi/dot_unstaged-drift-fixture"
trap 'rm -f "$unstaged_source"; rm -rf "$FIXTURE_ROOT"' EXIT
printf 'unstaged fixture\n' > "$unstaged_source"
error="$FIXTURE_ROOT/unstaged-error"
if "$REPO/scripts/dotfiles-state" drift --staged >/dev/null 2>"$error"; then
    echo "staged drift accepted an untracked chezmoi source" >&2
    exit 1
fi
assert_contains "$error" "untracked dotfiles source must be staged before drift checking"
rm "$unstaged_source"
unset GIT_INDEX_FILE

printf 'drift-gate: ok\n'
