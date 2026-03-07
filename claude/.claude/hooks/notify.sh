#!/bin/bash
# Claude Code notification hook
# Sends macOS notifications when Claude needs input or finishes a response.

INPUT=$(cat)

# Skip notification if this pane is currently focused in tmux
if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  PANE_VISIBLE=$(tmux display-message -t "$TMUX_PANE" -p '#{&&:#{window_active},#{pane_active}}' 2>/dev/null)
  if [ "$PANE_VISIBLE" = "1" ]; then
    exit 0
  fi
fi

EVENT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hook_event_name',''))" 2>/dev/null)
PROJECT=$(echo "$INPUT" | python3 -c "import sys,json; import os; print(os.path.basename(json.load(sys.stdin).get('cwd','')))" 2>/dev/null)

case "$EVENT" in
  Notification)
    MESSAGE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','Permission needed'))" 2>/dev/null)
    osascript -e "display notification \"$MESSAGE\" with title \"Claude Code [$PROJECT]\" sound name \"Funk\""
    ;;
  Stop)
    osascript -e "display notification \"Claude finished and is waiting for input.\" with title \"Claude Code [$PROJECT]\" sound name \"Glass\""
    ;;
esac
