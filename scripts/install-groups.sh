#!/usr/bin/env bash

# Return success when a logical install group is selected. An empty selection
# means a full install, so every group is selected.
install_group_selected() {
    local wanted="$1"
    local selection="${2-${ONLY:-}}"
    local group
    local -a groups

    [[ -z "$selection" ]] && return 0

    IFS=',' read -r -a groups <<<"$selection"
    for group in "${groups[@]}"; do
        group="${group#"${group%%[![:space:]]*}"}"
        group="${group%"${group##*[![:space:]]}"}"
        [[ "$group" == "$wanted" ]] && return 0
    done
    return 1
}

install_any_group_selected() {
    local group
    for group in "$@"; do
        install_group_selected "$group" && return 0
    done
    return 1
}
