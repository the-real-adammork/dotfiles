#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
new_fixture

cp "$REPO/codex/.codex/config.toml" "$FIXTURE_ROOT/codex.toml"
sed -i '' "s#/Users/adam#$HOME#g" "$FIXTURE_ROOT/codex.toml"
"$REPO/scripts/dotfiles-state" merge-mixed codex < "$FIXTURE_ROOT/codex.toml" > "$FIXTURE_ROOT/merged.toml"
assert_contains "$FIXTURE_ROOT/merged.toml" 'model = "gpt-5.6-sol"'
assert_contains "$FIXTURE_ROOT/merged.toml" 'model_reasoning_effort = "medium"'
assert_contains "$FIXTURE_ROOT/merged.toml" "$HOME/dots"

cp "$FIXTURE_ROOT/codex.toml" "$FIXTURE_ROOT/unknown.toml"
sed -i '' '/\[features\]/a\
unexpected_portable_key = true' "$FIXTURE_ROOT/unknown.toml"
if "$REPO/scripts/dotfiles-state" merge-mixed codex < "$FIXTURE_ROOT/unknown.toml" >/dev/null 2>&1; then
    echo "unknown portable key unexpectedly passed" >&2
    exit 1
fi

printf '\n[application_metadata]\nnew_counter = 1\n' >> "$FIXTURE_ROOT/codex.toml"
"$REPO/scripts/dotfiles-state" merge-mixed codex < "$FIXTURE_ROOT/codex.toml" > "$FIXTURE_ROOT/local.toml" 2> "$FIXTURE_ROOT/warnings"
assert_contains "$FIXTURE_ROOT/local.toml" 'new_counter = 1'
assert_contains "$FIXTURE_ROOT/warnings" 'preserving unclassified local root: application_metadata'

mkdir -p "$HOME/.codex"
cat > "$HOME/.codex/config.toml" <<'EOF'
[mcp_servers.fixture]
url = "https://fixture-user:fixture-password@example.invalid/mcp"
EOF
if "$REPO/scripts/dotfiles-state" capture codex >/dev/null 2>&1; then
    echo "capture accepted credential-bearing URL" >&2
    exit 1
fi

cat > "$FIXTURE_ROOT/unsafe-args.toml" <<'EOF'
[mcp_servers.context7]
command = "fixture"
args = ["--api-key=fixture-secret"]
EOF
if "$REPO/scripts/dotfiles-state" merge-mixed codex < "$FIXTURE_ROOT/unsafe-args.toml" >/dev/null 2>&1; then
    echo "projection accepted inline credential argument" >&2
    exit 1
fi

cat > "$FIXTURE_ROOT/unsafe-authorization.toml" <<'EOF'
[mcp_servers.context7]
command = "fixture"
args = ["Authorization: Bearer fixture-secret"]
EOF
if "$REPO/scripts/dotfiles-state" merge-mixed codex < "$FIXTURE_ROOT/unsafe-authorization.toml" >/dev/null 2>&1; then
    echo "projection accepted inline authorization value" >&2
    exit 1
fi

cat > "$FIXTURE_ROOT/safe-env-reference.toml" <<'EOF'
[mcp_servers.adobe-illustrator]
url = "https://example.invalid/mcp"
bearer_token_env_var = "FIXTURE_BEARER_TOKEN"
enabled = false
EOF
"$REPO/scripts/dotfiles-state" merge-mixed codex < "$FIXTURE_ROOT/safe-env-reference.toml" >/dev/null

validation_repo="$FIXTURE_ROOT/validation-repo"
mkdir -p "$validation_repo/scripts" "$validation_repo/config" "$validation_repo/chezmoi/dot_codex"
cp "$REPO/scripts/dotfiles-state" "$validation_repo/scripts/dotfiles-state"
cat > "$validation_repo/config/managed-targets.toml" <<'EOF'
schema_version = 1

[[targets]]
group = "codex"
path = ".codex"
owner = "chezmoi"
platform = "any"

[[unmanaged]]
path = ".codex/auth.json"
reason = "fixture authentication state"
EOF
printf 'managed-config\n' > "$validation_repo/chezmoi/dot_codex/config.toml"
python3 "$validation_repo/scripts/dotfiles-state" validate >/dev/null
printf 'harmless-auth-fixture\n' > "$validation_repo/chezmoi/dot_codex/auth.json"
if python3 "$validation_repo/scripts/dotfiles-state" validate >/dev/null 2>&1; then
    echo "validation accepted a chezmoi source overlapping an unmanaged target" >&2
    exit 1
fi
rm "$validation_repo/chezmoi/dot_codex/auth.json"

printf 'unowned-source\n' > "$validation_repo/chezmoi/dot_unowned"
if python3 "$validation_repo/scripts/dotfiles-state" validate >/dev/null 2>&1; then
    echo "validation accepted a chezmoi source without a manifest owner" >&2
    exit 1
fi
rm "$validation_repo/chezmoi/dot_unowned"

cat >> "$validation_repo/config/managed-targets.toml" <<'EOF'

[[targets]]
group = "missing"
path = ".missing"
owner = "chezmoi"
platform = "any"
EOF
if python3 "$validation_repo/scripts/dotfiles-state" validate >/dev/null 2>&1; then
    echo "validation accepted a manifest target without chezmoi source" >&2
    exit 1
fi

printf 'policies: ok\n'
