#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
for test in "$ROOT"/test-*.sh; do
    printf '==> %s\n' "$(basename "$test")"
    "$test"
done
