#!/bin/bash
# Notify when Codex needs input or finishes a turn.

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // .type // "unknown"' 2>/dev/null)

if [ "$EVENT" = "PermissionRequest" ]; then
  SOUND="Funk"
  MESSAGE="Codex needs your approval"
else
  SOUND="Glass"
  MESSAGE="Codex needs your attention"
fi

TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
TMUX_WINDOW=$(tmux display-message -p '#{window_index}' 2>/dev/null)
TITLE="${TMUX_SESSION}:${TMUX_WINDOW}"
PANE=$TMUX_PANE

if [ -z "$TMUX_SESSION" ] || [ -z "$TMUX_WINDOW" ]; then
  TITLE="Codex"
fi

CLIENT_VIEW=$(tmux list-clients -F '#{session_name}:#{window_index}' 2>/dev/null | head -1)
CLIENT_SESSION="${CLIENT_VIEW%%:*}"
CLIENT_WINDOW="${CLIENT_VIEW##*:}"

SAME_VIEW=false
if [ "$TMUX_SESSION" = "$CLIENT_SESSION" ] && [ "$TMUX_WINDOW" = "$CLIENT_WINDOW" ]; then
  SAME_VIEW=true
fi

NOTIFY="$HOME/.local/bin/claude-notify.app/Contents/MacOS/claude-notify"

if [ -x "$NOTIFY" ]; then
  SWITCH_CMD="open -a Ghostty"
  if [ -n "$TMUX_SESSION" ] && [ -n "$TMUX_WINDOW" ] && [ -n "$PANE" ]; then
    SWITCH_CMD="$SWITCH_CMD && tmux switch-client -t '${TMUX_SESSION}' && tmux select-window -t '${TMUX_SESSION}:${TMUX_WINDOW}' && tmux select-pane -t '${PANE}'"
  fi

  if [ "$SAME_VIEW" = "true" ]; then
    nohup "$NOTIFY" --title "$TITLE" --message "$MESSAGE" --on-click "$SWITCH_CMD" &>/dev/null &
  else
    nohup "$NOTIFY" --title "$TITLE" --message "$MESSAGE" --sound "$SOUND" --on-click "$SWITCH_CMD" &>/dev/null &
  fi
  disown
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\"" >/dev/null 2>&1
fi
