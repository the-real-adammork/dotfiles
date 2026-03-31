#!/bin/bash
# Notify when Claude Code needs input

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')

if [ "$EVENT" = "Notification" ]; then
  TITLE="Claude Code - Permission Needed"
  SOUND="Funk"
else
  TITLE="Claude Code - Done"
  SOUND="Glass"
fi

osascript -e "display notification \"Claude needs your attention\" with title \"$TITLE\" sound name \"$SOUND\""
