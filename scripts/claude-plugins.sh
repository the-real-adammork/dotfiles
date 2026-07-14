#!/usr/bin/env bash

ensure_claude_marketplace() {
    local name="$1"
    local source="$2"
    local marketplaces
    local marketplace
    marketplaces="$(claude plugin marketplace list --json)"
    marketplace="$(jq -c --arg name "$name" 'first(.[] | select(.name == $name)) // empty' \
        <<<"$marketplaces")"

    if [[ -z "$marketplace" ]]; then
        claude plugin marketplace add "$source"
        return
    elif [[ "$source" == /* ]]; then
        jq -e --arg source "$source" \
            '.source == "directory" and .path == $source' \
            <<<"$marketplace" &>/dev/null && return
    else
        jq -e --arg source "$source" \
            '.source == "github" and .repo == $source' \
            <<<"$marketplace" &>/dev/null && return
    fi

    echo "Claude marketplace '$name' exists with a different source; refusing to replace it automatically" >&2
    return 1
}

ensure_claude_plugin() {
    local plugin="$1"
    local enabled
    enabled="$(claude plugin list --json | jq -r --arg plugin "$plugin" \
        'first(.[] | select(.id == $plugin) | (.enabled | tostring)) // "missing"')"
    case "$enabled" in
        true) ;;
        false) claude plugin enable "$plugin" ;;
        missing) claude plugin install "$plugin" ;;
    esac
}

reconcile_claude_plugins() {
    local portable_config="$1"
    local name
    local source_type
    local source
    while IFS=$'\t' read -r name source_type source; do
        [[ -n "$name" && -n "$source" ]] || continue
        if [[ "$source_type" == "directory" ]]; then
            source="${source/__HOME__/$HOME}"
        fi
        ensure_claude_marketplace "$name" "$source"
    done < <(jq -r '
        .extraKnownMarketplaces
        | to_entries[]
        | [.key, .value.source.source, (.value.source.repo // .value.source.path)]
        | @tsv
    ' "$portable_config")

    while IFS= read -r plugin; do
        [[ -n "$plugin" ]] && ensure_claude_plugin "$plugin"
    done < <(jq -r '.enabledPlugins | to_entries[] | select(.value == true) | .key' "$portable_config")
}
