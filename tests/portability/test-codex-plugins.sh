#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"
source "$REPO/scripts/codex-plugins.sh"

LOG="$(mktemp)"
TEST_CODEX_HOME="$(mktemp -d)"
trap 'rm -f "$LOG"; rm -rf "$TEST_CODEX_HOME"' EXIT
export CODEX_HOME="$TEST_CODEX_HOME"
codex_plugins='{"installed":[],"available":[]}'
codex_marketplaces='{"marketplaces":[]}'
bootstrap_exposes_marketplace=true
marketplace_add_exposes_marketplace=true
plugin_add_enables_plugin=true

codex_git_sparse_clone() {
    local source="$1"
    local destination="$2"
    local sha_destination="$3"
    shift 3
    printf 'git sparse clone %s %s %s %s\n' "$source" "$destination" "$sha_destination" "$*" >>"$LOG"
    mkdir -p "$destination"
    mkdir -p "$(dirname "$sha_destination")"
    printf 'test-revision\n' >"$sha_destination"
    if [[ "$bootstrap_exposes_marketplace" == true ]]; then
        codex_marketplaces="$(jq -c --arg root "$destination" '
            .marketplaces += [{name: "openai-curated", root: $root}]
        ' <<<"$codex_marketplaces")"
        codex_plugins="$(jq -c '
            .available += [
                {pluginId: "superpowers@openai-curated", installed: false, enabled: false},
                {pluginId: "figma@openai-curated", installed: false, enabled: false}
            ]
        ' <<<"$codex_plugins")"
    fi
}

codex() {
    case "$*" in
        "plugin marketplace list --json")
            printf '%s\n' "$codex_marketplaces"
            ;;
        "plugin list --available --json")
            printf '%s\n' "$codex_plugins"
            ;;
        "plugin marketplace add EveryInc/compound-engineering-plugin "*)
            printf '%s\n' "$*" >>"$LOG"
            if [[ "$marketplace_add_exposes_marketplace" == true ]]; then
                codex_marketplaces="$(jq -c '
                .marketplaces += [{
                    name: "compound-engineering-plugin",
                    root: "/snapshot/compound-engineering-plugin",
                    marketplaceSource: {
                        sourceType: "git",
                        source: "https://github.com/EveryInc/compound-engineering-plugin.git"
                    }
                }]
                ' <<<"$codex_marketplaces")"
                codex_plugins="$(jq -c '
                .available += [{
                    pluginId: "compound-engineering@compound-engineering-plugin",
                    installed: false,
                    enabled: false
                }]
                ' <<<"$codex_plugins")"
            fi
            ;;
        "plugin add "*)
            printf '%s\n' "$*" >>"$LOG"
            local plugin="$3"
            if [[ "$plugin_add_enables_plugin" == true ]]; then
                codex_plugins="$(jq -c --arg plugin "$plugin" '
                first((.installed + .available)[] | select(.pluginId == $plugin)) as $match
                | .available = [.available[] | select(.pluginId != $plugin)]
                | .installed = (
                    [.installed[] | select(.pluginId != $plugin)]
                    + [($match // {pluginId: $plugin}) | .installed = true | .enabled = true]
                )
                ' <<<"$codex_plugins")"
            fi
            printf '{"pluginId":"%s"}\n' "$plugin"
            ;;
        *)
            echo "unexpected Codex command: codex $*" >&2
            return 1
            ;;
    esac
}

INVENTORY="$REPO/config/portable/codex-plugins.json"
reconcile_codex_plugins "$INVENTORY" >/dev/null

for expected in \
    "git sparse clone https://github.com/openai/plugins.git $CODEX_HOME/.tmp/plugins $CODEX_HOME/.tmp/plugins.sha .agents/plugins plugins/figma plugins/superpowers" \
    'plugin marketplace add EveryInc/compound-engineering-plugin --json' \
    'plugin add superpowers@openai-curated --json' \
    'plugin add figma@openai-curated --json' \
    'plugin add compound-engineering@compound-engineering-plugin --json'; do
    rg -qx --fixed-strings "$expected" "$LOG" || {
        echo "missing Codex reconciliation command: $expected" >&2
        exit 1
    }
done

: >"$LOG"
reconcile_codex_plugins "$INVENTORY" >/dev/null
[[ ! -s "$LOG" ]] || {
    echo "second Codex plugin reconciliation was not idempotent" >&2
    exit 1
}

saved_marketplaces="$codex_marketplaces"
codex_marketplaces="$(jq -c '
    (.marketplaces[] | select(.name == "openai-curated") | .root) = "/managed/openai-curated"
' <<<"$codex_marketplaces")"
reconcile_codex_plugins "$INVENTORY" >/dev/null
[[ ! -s "$LOG" ]] || {
    echo "product-managed built-in Codex marketplace was not preserved" >&2
    exit 1
}
codex_marketplaces="$saved_marketplaces"

codex_plugins="$(jq -c '
    (.installed[] | select(.pluginId == "figma@openai-curated") | .enabled) = false
' <<<"$codex_plugins")"
reconcile_codex_plugins "$INVENTORY" >/dev/null
[[ "$(cat "$LOG")" == 'plugin add figma@openai-curated --json' ]] || {
    echo "disabled Codex plugin was not re-enabled" >&2
    exit 1
}

saved_marketplaces="$codex_marketplaces"
saved_plugins="$codex_plugins"
rm -rf "$CODEX_HOME/.tmp/plugins"
rm -f "$CODEX_HOME/.tmp/plugins.sha"
codex_marketplaces='{"marketplaces":[]}'
codex_plugins='{"installed":[],"available":[]}'
bootstrap_exposes_marketplace=false
if reconcile_codex_plugins "$INVENTORY" >/dev/null 2>&1; then
    echo "built-in Codex marketplace bootstrap postcondition was not checked" >&2
    exit 1
fi
bootstrap_exposes_marketplace=true
codex_marketplaces="$saved_marketplaces"
codex_plugins="$saved_plugins"

codex_plugins="$(jq -c '
    .installed = [.installed[] | select(.pluginId != "figma@openai-curated")]
    | .available = [.available[] | select(.pluginId != "figma@openai-curated")]
' <<<"$codex_plugins")"
if reconcile_codex_plugins "$INVENTORY" >/dev/null 2>&1; then
    echo "Codex marketplace without its probe plugin was not rejected" >&2
    exit 1
fi
codex_plugins="$saved_plugins"

saved_marketplaces="$codex_marketplaces"
saved_plugins="$codex_plugins"
codex_marketplaces="$(jq -c '.marketplaces = [.marketplaces[] | select(.name != "compound-engineering-plugin")]' <<<"$codex_marketplaces")"
codex_plugins="$(jq -c '
    .installed = [.installed[] | select(.pluginId != "compound-engineering@compound-engineering-plugin")]
    | .available = [.available[] | select(.pluginId != "compound-engineering@compound-engineering-plugin")]
' <<<"$codex_plugins")"
marketplace_add_exposes_marketplace=false
if reconcile_codex_plugins "$INVENTORY" >/dev/null 2>&1; then
    echo "added Codex marketplace postcondition was not checked" >&2
    exit 1
fi
marketplace_add_exposes_marketplace=true
codex_marketplaces="$saved_marketplaces"
codex_plugins="$saved_plugins"

codex_plugins="$(jq -c '
    (.installed[] | select(.pluginId == "figma@openai-curated") | .enabled) = false
' <<<"$codex_plugins")"
plugin_add_enables_plugin=false
if reconcile_codex_plugins "$INVENTORY" >/dev/null 2>&1; then
    echo "enabled Codex plugin postcondition was not checked" >&2
    exit 1
fi
plugin_add_enables_plugin=true
codex_plugins="$saved_plugins"

codex_marketplaces="$(jq -c '
    (.marketplaces[] | select(.name == "compound-engineering-plugin")
      | .marketplaceSource.source) = "https://github.com/example/wrong.git"
' <<<"$codex_marketplaces")"
if reconcile_codex_plugins "$INVENTORY" >/dev/null 2>&1; then
    echo "unexpected Codex marketplace source was not rejected" >&2
    exit 1
fi

while IFS= read -r plugin; do
    assert_contains "$REPO/config/portable/codex.toml" "[plugins.\"$plugin\"]"
done < <(jq -r '.enabledPlugins | to_entries[] | select(.value == true) | .key' "$INVENTORY")

assert_contains "$REPO/config/portable/codex.toml" '[mcp_servers.figma]'
assert_contains "$REPO/config/portable/codex.toml" 'url = "https://mcp.figma.com/mcp"'
assert_contains "$REPO/install.sh" 'source "$DOTS_DIR/scripts/codex-plugins.sh"'
assert_contains "$REPO/install.sh" 'reconcile_codex_plugins "$DOTS_DIR/config/portable/codex-plugins.json"'
reconcile_line="$(rg -n -F -m1 'reconcile_codex_plugins ' "$REPO/install.sh" | cut -d: -f1)"
apply_line="$(rg -n -F -m1 '"$DOTS_DIR/scripts/dotfiles-state" apply "${apply_args[@]}"' "$REPO/install.sh" | cut -d: -f1)"
[[ -n "$reconcile_line" && -n "$apply_line" && "$reconcile_line" -lt "$apply_line" ]] || {
    echo "Codex plugins must be reconciled before portable config is applied" >&2
    exit 1
}

printf 'Codex plugin reconciliation test passed.\n'
