#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
new_fixture

legacy_stow="$(mktemp -d "$REPO/.legacy-stow-test.XXXXXX")"
trap 'rm -rf "$legacy_stow" "$FIXTURE_ROOT"' EXIT
mkdir -p "$legacy_stow/zsh" "$legacy_stow/tmux" "$legacy_stow/bat/.config/bat" "$legacy_stow/codex/.codex"
cp "$REPO/chezmoi/dot_zshrc.tmpl" "$legacy_stow/zsh/.zshrc"
cp "$REPO/chezmoi/dot_tmux.conf" "$legacy_stow/tmux/.tmux.conf"
cp "$REPO/chezmoi/dot_config/bat/config" "$legacy_stow/bat/.config/bat/config"
cp "$REPO/config/portable/codex.toml" "$legacy_stow/codex/.codex/config.toml"

ln -s "$legacy_stow/zsh/.zshrc" "$HOME/.zshrc"
ln -s "$legacy_stow/tmux/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config"
ln -s "$legacy_stow/bat/.config/bat" "$HOME/.config/bat"
# Source validation is lexical and must permit the legacy symlink topology
# that preview/adopt are responsible for replacing.
"$REPO/scripts/dotfiles-state" validate >/dev/null
if "$REPO/scripts/dotfiles-state" apply --home "$HOME" --only zsh >/dev/null 2>&1; then
    echo "legacy Stow target was overwritten without adoption" >&2
    exit 1
fi

mkdir -p "$HOME/.config/gh"
chmod 751 "$HOME/.config/gh"
printf 'credential-sentinel\n' > "$HOME/.config/gh/hosts.yml"
sentinel="$(shasum -a 256 "$HOME/.config/gh/hosts.yml")"
printf '[user]\n\tname = Fixture User\n\temail = fixture@example.invalid\n' > "$HOME/.gitconfig"

"$REPO/scripts/dotfiles-state" adopt --home "$HOME" --only zsh,git,bat,gh --yes >/dev/null
[[ ! -L "$HOME/.zshrc" ]] || { echo "adoption left Stow symlink" >&2; exit 1; }
[[ -d "$HOME/.config/bat" && ! -L "$HOME/.config/bat" ]] || { echo "adoption left directory Stow symlink" >&2; exit 1; }
[[ -L "$HOME/.tmux.conf" ]] || { echo "bounded adoption changed unrelated tmux target" >&2; exit 1; }
assert_contains "$HOME/.config/git/local" 'fixture@example.invalid'
[[ "$(/usr/bin/stat -f '%Lp' "$HOME/.config/git/local")" == "600" ]] || { echo "local Git identity permissions are not private" >&2; exit 1; }
[[ "$sentinel" == "$(shasum -a 256 "$HOME/.config/gh/hosts.yml")" ]] || { echo "auth sentinel changed" >&2; exit 1; }
[[ "$(/usr/bin/stat -f '%Lp' "$HOME/.config/gh")" == "751" ]] || { echo "auth parent permissions changed" >&2; exit 1; }
jq -e '.status == "complete" and .groups == ["bat", "gh", "git", "zsh"]' "$XDG_STATE_HOME/dots/adoption.json" >/dev/null

printf 'changed\n' > "$HOME/.zshrc"
"$REPO/scripts/dotfiles-state" rollback >/dev/null
assert_not_contains "$HOME/.zshrc" 'changed'
[[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$legacy_stow/zsh/.zshrc" ]] || { echo "rollback did not restore file symlink topology" >&2; exit 1; }
[[ -L "$HOME/.config/bat" && "$(readlink "$HOME/.config/bat")" == "$legacy_stow/bat/.config/bat" ]] || { echo "rollback did not restore directory symlink topology" >&2; exit 1; }
[[ -L "$HOME/.tmux.conf" ]] || { echo "rollback changed unrelated tmux target" >&2; exit 1; }

mkdir -p "$HOME/.codex"
printf 'nested-auth-sentinel\n' > "$HOME/.codex/auth.json"
nested_auth_sentinel="$(shasum -a 256 "$HOME/.codex/auth.json" | awk '{print $1}')"
ln -s "$legacy_stow/codex/.codex/config.toml" "$HOME/.codex/config.toml"
if "$REPO/scripts/dotfiles-state" apply --home "$HOME" --only codex >/dev/null 2>&1; then
    echo "nested legacy Stow target was overwritten without adoption" >&2
    exit 1
fi
[[ "$nested_auth_sentinel" == "$(shasum -a 256 "$HOME/.codex/auth.json" | awk '{print $1}')" ]] || { echo "failed nested adoption guard changed auth sentinel" >&2; exit 1; }
rm -rf "$HOME/.codex"

legacy_codex="$FIXTURE_ROOT/legacy-codex"
mkdir -p "$legacy_codex/sessions" "$legacy_codex/runtime" "$HOME/.claude"
printf 'harmless-auth-sentinel\n' > "$legacy_codex/auth.json"
printf 'runtime-sentinel\n' > "$legacy_codex/sessions/session.jsonl"
printf 'local-sentinel\n' > "$legacy_codex/runtime/local-state"
printf 'claude-sentinel\n' > "$HOME/.claude/local-state"
auth_sentinel="$(shasum -a 256 "$legacy_codex/auth.json" | awk '{print $1}')"
claude_sentinel="$(shasum -a 256 "$HOME/.claude/local-state" | awk '{print $1}')"
ln -s "$legacy_codex" "$HOME/.codex"

"$REPO/scripts/dotfiles-state" adopt --home "$HOME" --only codex --yes >/dev/null
[[ -d "$HOME/.codex" && ! -L "$HOME/.codex" ]] || { echo "folded Codex directory was not materialized" >&2; exit 1; }
[[ "$auth_sentinel" == "$(shasum -a 256 "$HOME/.codex/auth.json" | awk '{print $1}')" ]] || { echo "folded Codex auth sentinel changed" >&2; exit 1; }
assert_contains "$HOME/.codex/sessions/session.jsonl" 'runtime-sentinel'
assert_contains "$HOME/.codex/runtime/local-state" 'local-sentinel'
[[ "$claude_sentinel" == "$(shasum -a 256 "$HOME/.claude/local-state" | awk '{print $1}')" ]] || { echo "Codex adoption changed Claude state" >&2; exit 1; }
jq -e '.status == "complete" and .groups == ["codex"] and .folded_directories == [{"target":".codex","link":$link,"referent":$referent,"unmanaged":["auth.json"]}]' \
    --arg link "$legacy_codex" --arg referent "$(cd "$legacy_codex" && pwd -P)" \
    "$XDG_STATE_HOME/dots/adoption.json" >/dev/null
[[ ! -e "$legacy_codex/auth.json" && ! -L "$legacy_codex/auth.json" ]] || { echo "folded adoption left auth inside legacy source" >&2; exit 1; }

printf 'managed-change\n' > "$HOME/.codex/config.toml"
"$REPO/scripts/dotfiles-state" rollback >/dev/null
[[ -L "$HOME/.codex" ]] || { echo "rollback did not restore folded Codex symlink" >&2; exit 1; }
[[ "$(readlink "$HOME/.codex")" == "$legacy_codex" ]] || { echo "rollback changed folded Codex symlink topology" >&2; exit 1; }
[[ -f "$legacy_codex/auth.json" ]] || { echo "rollback did not return auth to legacy referent" >&2; exit 1; }
[[ "$auth_sentinel" == "$(shasum -a 256 "$HOME/.codex/auth.json" | awk '{print $1}')" ]] || { echo "rollback changed folded Codex auth sentinel" >&2; exit 1; }
assert_contains "$HOME/.codex/sessions/session.jsonl" 'runtime-sentinel'
[[ "$claude_sentinel" == "$(shasum -a 256 "$HOME/.claude/local-state" | awk '{print $1}')" ]] || { echo "rollback changed Claude state" >&2; exit 1; }

rm "$HOME/.codex"
"$REPO/scripts/dotfiles-state" adopt --home "$HOME" --only codex --yes >/dev/null
[[ -d "$HOME/.codex" ]] || { echo "adoption did not create missing Codex target" >&2; exit 1; }
"$REPO/scripts/dotfiles-state" rollback >/dev/null
[[ ! -e "$HOME/.codex" && ! -L "$HOME/.codex" ]] || { echo "rollback retained target created by adoption" >&2; exit 1; }

# A failed chezmoi apply restores the original topology automatically.
ln -sf "$legacy_stow/zsh/.zshrc" "$HOME/.zshrc"
if DOTFILES_TEST_FAIL_ADOPTION_APPLY=1 "$REPO/scripts/dotfiles-state" adopt --home "$HOME" --only zsh --yes >/dev/null 2>&1; then
    echo "injected adoption apply failure unexpectedly succeeded" >&2
    exit 1
fi
[[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$legacy_stow/zsh/.zshrc" ]] || { echo "failed adoption did not restore original symlink" >&2; exit 1; }
[[ ! -e "$HOME/.zprofile" && ! -L "$HOME/.zprofile" ]] || { echo "failed adoption retained newly created target" >&2; exit 1; }
jq -e '.status == "failed_rolled_back" and .groups == ["zsh"]' "$XDG_STATE_HOME/dots/adoption.json" >/dev/null

printf 'adoption: ok\n'
