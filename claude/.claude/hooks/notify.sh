#!/bin/bash
# Notify when Claude Code needs input
# - Same window: silent notification
# - Different window/session: sound + click to switch tmux and focus Ghostty

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')

if [ "$EVENT" = "Notification" ]; then
  SOUND="Funk"
else
  SOUND="Glass"
fi

# This pane's location
TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
TMUX_WINDOW=$(tmux display-message -p '#{window_index}' 2>/dev/null)
TITLE="${TMUX_SESSION}:${TMUX_WINDOW}"
PANE=$TMUX_PANE

# What the client is currently viewing
CLIENT_VIEW=$(tmux list-clients -F '#{session_name}:#{window_index}' 2>/dev/null | head -1)
CLIENT_SESSION="${CLIENT_VIEW%%:*}"
CLIENT_WINDOW="${CLIENT_VIEW##*:}"

SAME_VIEW=false
if [ "$TMUX_SESSION" = "$CLIENT_SESSION" ] && [ "$TMUX_WINDOW" = "$CLIENT_WINDOW" ]; then
  SAME_VIEW=true
fi

NOTIFY="$HOME/.local/bin/claude-notify.app/Contents/MacOS/claude-notify"

if [ -x "$NOTIFY" ]; then
  SWITCH_CMD="open -a Ghostty && tmux switch-client -t '${TMUX_SESSION}' && tmux select-window -t '${TMUX_SESSION}:${TMUX_WINDOW}' && tmux select-pane -t '${PANE}'"
  if [ "$SAME_VIEW" = "true" ]; then
    nohup "$NOTIFY" --title "$TITLE" --message "Claude needs your attention" --on-click "$SWITCH_CMD" &>/dev/null &
  else
    nohup "$NOTIFY" --title "$TITLE" --message "Claude needs your attention" --sound "$SOUND" --on-click "$SWITCH_CMD" &>/dev/null &
  fi
  disown
else
  osascript -e "display notification \"Claude needs your attention\" with title \"$TITLE\" sound name \"$SOUND\""
fi
