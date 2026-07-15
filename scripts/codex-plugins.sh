#!/usr/bin/env bash

codex_marketplace_listing() {
    codex plugin marketplace list --json
}

codex_plugin_listing() {
    codex plugin list --available --json
}

codex_git_sparse_clone() {
    local source="$1"
    local destination="$2"
    local sha_destination="$3"
    local temporary="${destination}.tmp.$$"
    local temporary_sha="${sha_destination}.tmp.$$"
    local revision
    shift 3

    mkdir -p "$(dirname "$destination")" "$(dirname "$sha_destination")"
    if ! /usr/bin/git clone --filter=blob:none --sparse "$source" "$temporary" >/dev/null; then
        rm -rf "$temporary"
        return 1
    fi
    if ! /usr/bin/git -C "$temporary" sparse-checkout set "$@"; then
        rm -rf "$temporary"
        return 1
    fi
    revision="$(/usr/bin/git -C "$temporary" rev-parse HEAD)" || {
        rm -rf "$temporary"
        return 1
    }
    printf '%s\n' "$revision" >"$temporary_sha"
    if ! mv "$temporary" "$destination" || ! mv "$temporary_sha" "$sha_destination"; then
        rm -rf "$temporary" "$temporary_sha" "$destination" "$sha_destination"
        return 1
    fi
}

codex_marketplace_source_matches() {
    local listing="$1"
    local name="$2"
    local source="$3"

    jq -e --arg name "$name" --arg source "$source" '
        def canonical_source:
            sub("^https://github\\.com/"; "") | sub("\\.git$"; "");
        first(.marketplaces[]? | select(.name == $name)) as $match
        | $match != null
          and ($source == ""
               or (($match.marketplaceSource.source // "") | canonical_source)
                  == ($source | canonical_source))
    ' <<<"$listing" &>/dev/null
}

reconcile_codex_plugins() {
    local inventory="$1"
    local inventory_json
    local marketplace_listing
    local plugin_listing
    local name
    local source
    local probe_plugin
    local sparse
    local bootstrap_source
    local bootstrap_path
    local bootstrap_sha_path
    local bootstrap_sparse
    local bootstrap_destination
    local bootstrap_sha_destination
    local bootstrap_candidate
    local path
    local plugin
    local state
    local marketplaces_changed=false
    local plugins_changed=false
    local -a command
    local -a sparse_paths

    inventory_json="$(jq -c . "$inventory")"
    marketplace_listing="$(codex_marketplace_listing)"

    while IFS=$'\t' read -r name source probe_plugin sparse bootstrap_source bootstrap_path bootstrap_sha_path bootstrap_sparse; do
        [[ -n "$name" && -n "$probe_plugin" ]] || continue
        [[ "$source" == "__builtin__" ]] && source=""
        [[ "$sparse" == "__none__" ]] && sparse=""
        [[ "$bootstrap_source" == "__none__" ]] && bootstrap_source=""
        [[ "$bootstrap_path" == "__none__" ]] && bootstrap_path=""
        [[ "$bootstrap_sha_path" == "__none__" ]] && bootstrap_sha_path=""
        [[ "$bootstrap_sparse" == "__none__" ]] && bootstrap_sparse=""
        if codex_marketplace_source_matches "$marketplace_listing" "$name" "$source"; then
            continue
        fi
        if jq -e --arg name "$name" 'any(.marketplaces[]?; .name == $name)' \
            <<<"$marketplace_listing" &>/dev/null; then
            echo "Codex marketplace '$name' is configured from an unexpected source" >&2
            return 1
        fi
        if [[ -z "$source" ]]; then
            if [[ -z "$bootstrap_source" || -z "$bootstrap_path" || -z "$bootstrap_sha_path" || -z "$bootstrap_sparse" ]]; then
                echo "Required built-in Codex marketplace '$name' is unavailable and has no bootstrap metadata" >&2
                return 1
            fi
            for bootstrap_candidate in "$bootstrap_path" "$bootstrap_sha_path"; do
                case "$bootstrap_candidate" in
                    .|/*|..|../*|*/..|*/../*)
                        echo "Codex marketplace '$name' has an unsafe bootstrap path" >&2
                        return 1
                        ;;
                esac
            done
            bootstrap_destination="${CODEX_HOME:-$HOME/.codex}/$bootstrap_path"
            bootstrap_sha_destination="${CODEX_HOME:-$HOME/.codex}/$bootstrap_sha_path"
            if [[ -e "$bootstrap_destination" || -e "$bootstrap_sha_destination" ]]; then
                echo "Codex marketplace '$name' bootstrap path already exists but is not recognized" >&2
                return 1
            fi
            IFS='|' read -r -a sparse_paths <<<"$bootstrap_sparse"
            codex_git_sparse_clone "$bootstrap_source" "$bootstrap_destination" \
                "$bootstrap_sha_destination" "${sparse_paths[@]}"
            marketplaces_changed=true
            continue
        fi

        command=(codex plugin marketplace add "$source")
        sparse_paths=()
        if [[ -n "$sparse" ]]; then
            IFS='|' read -r -a sparse_paths <<<"$sparse"
            for path in "${sparse_paths[@]}"; do
                command+=(--sparse "$path")
            done
        fi
        command+=(--json)
        "${command[@]}" >/dev/null
        marketplaces_changed=true
    done < <(jq -r '
        .marketplaces
        | to_entries[]
        | [.key, (.value.source // "__builtin__"), .value.probePlugin,
           (if (.value.sparsePaths // []) | length > 0
            then (.value.sparsePaths | join("|")) else "__none__" end),
           (.value.bootstrap.source // "__none__"),
           (.value.bootstrap.path // "__none__"),
           (.value.bootstrap.shaPath // "__none__"),
           (if (.value.bootstrap.sparsePaths // []) | length > 0
            then (.value.bootstrap.sparsePaths | join("|")) else "__none__" end)]
        | @tsv
    ' <<<"$inventory_json")

    if [[ "$marketplaces_changed" == true ]]; then
        marketplace_listing="$(codex_marketplace_listing)"
    fi
    while IFS=$'\t' read -r name source probe_plugin sparse; do
        [[ -n "$name" && -n "$probe_plugin" ]] || continue
        [[ "$source" == "__builtin__" ]] && source=""
        codex_marketplace_source_matches "$marketplace_listing" "$name" "$source" || {
            echo "Codex marketplace '$name' was not configured from the expected source" >&2
            return 1
        }
    done < <(jq -r '
        .marketplaces | to_entries[]
        | [.key, (.value.source // "__builtin__"), .value.probePlugin, "-"] | @tsv
    ' <<<"$inventory_json")

    plugin_listing="$(codex_plugin_listing)"
    while IFS= read -r probe_plugin; do
        jq -e --arg plugin "$probe_plugin" '
            any((.installed + .available)[]?; .pluginId == $plugin)
        ' <<<"$plugin_listing" &>/dev/null || {
            echo "Configured Codex marketplaces do not expose '$probe_plugin'" >&2
            return 1
        }
    done < <(jq -r '.marketplaces[].probePlugin' <<<"$inventory_json")

    while IFS= read -r plugin; do
        [[ -n "$plugin" ]] || continue
        state="$(jq -r --arg plugin "$plugin" '
            first((.installed + .available)[]? | select(.pluginId == $plugin)) as $match
            | if $match == null then "missing"
              elif $match.installed and $match.enabled then "enabled"
              elif $match.installed then "disabled"
              else "available"
              end
        ' <<<"$plugin_listing")"
        case "$state" in
            enabled) ;;
            disabled|available)
                codex plugin add "$plugin" --json >/dev/null
                plugins_changed=true
                ;;
            missing)
                echo "Codex plugin '$plugin' is absent from configured marketplaces" >&2
                return 1
                ;;
        esac
    done < <(jq -r '
        .enabledPlugins | to_entries[] | select(.value == true) | .key
    ' <<<"$inventory_json")

    if [[ "$plugins_changed" == true ]]; then
        plugin_listing="$(codex_plugin_listing)"
    fi
    while IFS= read -r plugin; do
        jq -e --arg plugin "$plugin" '
            any(.installed[]?; .pluginId == $plugin and .enabled == true)
        ' <<<"$plugin_listing" &>/dev/null || {
            echo "Codex plugin '$plugin' was not enabled after reconciliation" >&2
            return 1
        }
    done < <(jq -r '
        .enabledPlugins | to_entries[] | select(.value == true) | .key
    ' <<<"$inventory_json")
}
