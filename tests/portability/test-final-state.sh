#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers/common.sh"

while IFS= read -r package; do
    [[ ! -e "$REPO/$package" && ! -L "$REPO/$package" ]] || {
        echo "legacy Stow package remains: $package" >&2
        exit 1
    }
done < <(python3 - "$REPO/config/managed-targets.toml" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as source:
    manifest = tomllib.load(source)

for group in sorted({target["group"] for target in manifest["targets"]}):
    print(group)
PY
)

if rg -q '^brew "(?:stow|pre-commit)"' "$REPO/Brewfile"; then
    echo "retired Stow dependency remains in Brewfile" >&2
    exit 1
fi

[[ ! -e "$REPO/stow-conflicts.sh" ]] || {
    echo "retired Stow conflict helper remains" >&2
    exit 1
}

[[ ! -e "$REPO/.stow-local-ignore" ]] || {
    echo "retired root Stow control file remains" >&2
    exit 1
}

python3 - "$REPO/config/managed-targets.toml" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as source:
    manifest = tomllib.load(source)

assert manifest["targets"]
assert all(target["owner"] == "chezmoi" for target in manifest["targets"])
PY

"$REPO/scripts/dotfiles-state" validate >/dev/null
printf 'final-state: ok\n'
