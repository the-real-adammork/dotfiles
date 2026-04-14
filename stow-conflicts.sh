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

# Use stow's own dry-run to detect real conflicts
# stow -n reports conflicts to stderr like:
#   * cannot stow pkg/file over existing target .file ...
detect_conflicts() {
  local conflicts=()
  for pkg in "${packages[@]}"; do
    while IFS= read -r line; do
      # Extract target path from stow conflict message
      local target
      target=$(echo "$line" | sed -n 's/.*existing target \(.*\) since.*/\1/p')
      if [ -n "$target" ]; then
        conflicts+=("$HOME/$target")
      fi
    done < <(stow -d "$DOTS_DIR" -t "$HOME" -n --restow "$pkg" 2>&1 || true)
  done
  printf '%s\n' "${conflicts[@]}"
}

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
      fi
    done
  done
  ok "Cleanup done."
  exit 0
fi

# Detect conflicts via stow dry-run
conflicts=$(detect_conflicts)

if [ -z "$conflicts" ]; then
  ok "No conflicts found. Stow is clear to run."
  exit 0
fi

count=$(echo "$conflicts" | wc -l | tr -d ' ')

if [ "$MODE" = "dry-run" ]; then
  info "Conflicting files (would block stow):"
  echo ""
  echo "$conflicts" | while read -r f; do
    echo "  ~/${f#$HOME/}"
  done
  echo ""
  echo "  $count conflict(s) found."
  echo "  Run with --fix to rename them to .bak"
elif [ "$MODE" = "fix" ]; then
  echo "$conflicts" | while read -r f; do
    mv "$f" "$f.bak"
    warn "  ~/${f#$HOME/} → ~/${f#$HOME/}.bak"
  done
  echo ""
  ok "$count file(s) renamed to .bak. Stow should now work."
  echo "  Run with --cleanup to delete .bak files after verifying."
fi
