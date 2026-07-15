#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

export HOME="$FIXTURE_ROOT/home"
SIDEBAR_DIR="$HOME/.tmux/plugins/tmux-agent-sidebar"
STDERR_LOG="$FIXTURE_ROOT/sidebar.stderr"
mkdir -p "$SIDEBAR_DIR"
touch "$SIDEBAR_DIR/hook.sh"
chmod +x "$SIDEBAR_DIR/hook.sh"

cat >"$SIDEBAR_DIR/install-wizard.sh" <<'SH'
#!/usr/bin/env bash
mkdir -p "$(dirname "$0")/bin"
touch "$(dirname "$0")/bin/tmux-agent-sidebar"
chmod +x "$(dirname "$0")/bin/tmux-agent-sidebar"
echo "error connecting to /private/tmp/tmux-502/default (No such file or directory)" >&2
exit 1
SH
chmod +x "$SIDEBAR_DIR/install-wizard.sh"

info() { :; }
warn() { :; }
install_any_group_selected() { return 0; }
install_group_selected() { return 1; }
reconcile_claude_plugins() { :; }
export DOTS_DIR="$REPO"

sidebar_block="$(sed -n '/^# Codex and Claude hooks/,/^# --- Chezmoi ---/p' "$REPO/install.sh" | sed '$d')"
set +e
(set -e; eval "$sidebar_block") 2>"$STDERR_LOG"
sidebar_status=$?
set -e
[[ "$sidebar_status" -eq 0 ]] || {
    echo "sidebar bootstrap failed after the wizard installed a valid binary" >&2
    exit 1
}
[[ -x "$SIDEBAR_DIR/bin/tmux-agent-sidebar" ]] || {
    echo "sidebar wizard did not install its binary" >&2
    exit 1
}
! rg -q --fixed-strings 'error connecting to ' "$STDERR_LOG" || {
    echo "sidebar bootstrap leaked the expected missing-tmux-server error" >&2
    exit 1
}

# A wizard failure that does not produce a binary must remain fatal and retain
# its diagnostic output.
rm "$SIDEBAR_DIR/bin/tmux-agent-sidebar"
cat >"$SIDEBAR_DIR/install-wizard.sh" <<'SH'
#!/usr/bin/env bash
echo "sidebar download failed" >&2
exit 1
SH
chmod +x "$SIDEBAR_DIR/install-wizard.sh"

set +e
(set -e; eval "$sidebar_block") 2>"$STDERR_LOG"
sidebar_status=$?
set -e
[[ "$sidebar_status" -ne 0 ]] || {
    echo "sidebar bootstrap ignored a genuine binary download failure" >&2
    exit 1
}
rg -q --fixed-strings 'sidebar download failed' "$STDERR_LOG" || {
    echo "sidebar bootstrap hid a genuine download diagnostic" >&2
    exit 1
}

printf 'Tmux agent sidebar bootstrap test passed.\n'
