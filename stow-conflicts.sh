#!/usr/bin/env bash
set -euo pipefail

# stow-conflicts.sh — Detect and resolve files that would conflict with stow.
#
# Usage:
#   ./stow-conflicts.sh                # dry-run: show conflicting files
#   ./stow-conflicts.sh --fix          # rename conflicts to .bak
#   ./stow-conflicts.sh --cleanup      # delete .bak files created by --fix

DOTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_DIRS="docs .git"

info() { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m==> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m==> %s\033[0m\n" "$1"; }

MODE="dry-run"
case "${1:-}" in
  --fix)     MODE="fix" ;;
  --cleanup) MODE="cleanup" ;;
  "")        MODE="dry-run" ;;
  *)         echo "Usage: stow-conflicts.sh [--fix | --cleanup]"; exit 1 ;;
esac

# Discover stow packages
packages=()
for dir in "$DOTS_DIR"/*/; do
  pkg="$(basename "$dir")"
  skip=false
  for s in $SKIP_DIRS; do
    [[ "$pkg" == "$s" ]] && skip=true
  done
  $skip && continue
  packages+=("$pkg")
done

if [ "$MODE" = "cleanup" ]; then
  info "Cleaning up .bak files..."
  count=0
  for pkg in "${packages[@]}"; do
    find "$DOTS_DIR/$pkg" -type f -not -path '*/.git/*' | while read -r src; do
      rel="${src#$DOTS_DIR/$pkg/}"
      bak="$HOME/$rel.bak"
      if [ -f "$bak" ]; then
        rm "$bak"
        echo "  deleted: ~/$rel.bak"
        count=$((count + 1))
      fi
    done
  done
  ok "Cleanup done."
  exit 0
fi

# Scan for conflicts
conflicts=()
for pkg in "${packages[@]}"; do
  find "$DOTS_DIR/$pkg" -type f -not -path '*/.git/*' | while read -r src; do
    rel="${src#$DOTS_DIR/$pkg/}"
    target="$HOME/$rel"
    if [ -f "$target" ] && [ ! -L "$target" ]; then
      echo "$pkg:$rel"
    fi
  done
done | {
  count=0
  if [ "$MODE" = "dry-run" ]; then
    info "Conflicting files (would block stow):"
    echo ""
  fi

  while IFS=: read -r pkg rel; do
    target="$HOME/$rel"
    count=$((count + 1))

    if [ "$MODE" = "dry-run" ]; then
      echo "  [$pkg] ~/$rel"
    elif [ "$MODE" = "fix" ]; then
      mv "$target" "$target.bak"
      warn "  ~/$rel → ~/$rel.bak"
    fi
  done

  if [ "$count" -eq 0 ]; then
    ok "No conflicts found. Stow is clear to run."
  elif [ "$MODE" = "dry-run" ]; then
    echo ""
    echo "  $count conflict(s) found."
    echo "  Run with --fix to rename them to .bak"
  elif [ "$MODE" = "fix" ]; then
    echo ""
    ok "$count file(s) renamed to .bak. Stow should now work."
    echo "  Run with --cleanup to delete .bak files after verifying."
  fi
}
