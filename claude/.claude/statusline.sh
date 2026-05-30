#!/usr/bin/env bash

set -euo pipefail

input="$(cat)"

model="$(
  printf '%s' "$input" | jq -r '.model.display_name // .model.id // "Claude"'
)"

current_dir="$(
  printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""'
)"

if [[ -n "$current_dir" && "$current_dir" == "$HOME"* ]]; then
  current_dir="~${current_dir#"$HOME"}"
fi

if [[ -n "$current_dir" ]]; then
  printf '%s | %s\n' "$model" "$current_dir"
else
  printf '%s\n' "$model"
fi
