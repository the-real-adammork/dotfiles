#!/usr/bin/env bash
set -euo pipefail

# migrate-rekordbox.sh — Pull Rekordbox data from an old Mac over the network.
#
# Run this on the NEW machine. It mounts the old Mac via SMB, then uses ditto
# to copy Rekordbox data directly — preserving macOS metadata, resource forks,
# and extended attributes.
#
# Prerequisites:
#   - File Sharing enabled on the old Mac
#     (System Settings > General > Sharing > File Sharing)
#   - Rekordbox must be closed on BOTH machines
#
# Usage:
#   ./migrate-rekordbox.sh                          # prompts for host and user
#   ./migrate-rekordbox.sh old-mac.local
#   ./migrate-rekordbox.sh old-mac.local adam
#   ./migrate-rekordbox.sh --dry-run old-mac.local  # test mount + show sizes
#
# ⚠️  Rekordbox stores absolute paths to audio files in master.db.
#     If your username or music folder changes, use:
#     Rekordbox > File > Display All Missing Files > Relocate

info() { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m==> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m==> %s\033[0m\n" "$1"; }
err()  { printf "\033[1;31m==> %s\033[0m\n" "$1"; exit 1; }

MOUNT_POINT="/Volumes/rekordbox-migrate"

RB_DATA="Library/Pioneer/rekordbox"
RB_PREFS="Library/Preferences/com.pioneerdj.rekordboxdj.plist"
RB_APP_SUPPORT="Library/Application Support/Pioneer/rekordbox"

cleanup() {
    if mount | grep -q "$MOUNT_POINT"; then
        info "Unmounting $MOUNT_POINT..."
        diskutil unmount "$MOUNT_POINT" 2>/dev/null || umount "$MOUNT_POINT" 2>/dev/null || true
    fi
    rmdir "$MOUNT_POINT" 2>/dev/null || true
}
trap cleanup EXIT

# --- Parse flags ---
DRY_RUN=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) ARGS+=("$arg") ;;
    esac
done

HOST="${ARGS[0]:-}"
REMOTE_USER="${ARGS[1]:-}"

if [ -z "$HOST" ]; then
    echo "Enter the hostname or IP of the old Mac (e.g. old-mac.local or 192.168.1.50):"
    read -r HOST
fi
[ -z "$HOST" ] && err "No hostname provided."

if [ -z "$REMOTE_USER" ]; then
    echo "Enter the username on the old Mac [$(whoami)]:"
    read -r REMOTE_USER
    REMOTE_USER="${REMOTE_USER:-$(whoami)}"
fi

# --- Check Rekordbox is not running locally ---
if pgrep -xq "rekordbox"; then
    err "Rekordbox is running on this machine. Quit it first."
fi

# --- Mount the old Mac via SMB ---
info "Mounting //$REMOTE_USER@$HOST/$REMOTE_USER ..."
mkdir -p "$MOUNT_POINT"

if ! mount_smbfs "//$REMOTE_USER@$HOST/$REMOTE_USER" "$MOUNT_POINT" 2>/dev/null; then
    # Some setups share the home folder under a different name
    warn "Could not mount home directory share. Trying username as share name..."
    if ! mount_smbfs "smb://$REMOTE_USER@$HOST/$REMOTE_USER" "$MOUNT_POINT" 2>/dev/null; then
        rmdir "$MOUNT_POINT" 2>/dev/null || true
        err "Failed to mount SMB share. Ensure File Sharing is enabled on the old Mac and the share name is correct."
    fi
fi
ok "Mounted old Mac at $MOUNT_POINT"

# --- Verify Rekordbox data exists on remote ---
if [ ! -d "$MOUNT_POINT/$RB_DATA" ]; then
    err "No Rekordbox data found at $MOUNT_POINT/$RB_DATA"
fi

REMOTE_SIZE=$(du -sh "$MOUNT_POINT/$RB_DATA" 2>/dev/null | cut -f1)
info "Found Rekordbox data on old Mac: $REMOTE_SIZE"

# --- Check for username mismatch ---
if [ "$REMOTE_USER" != "$USER" ]; then
    warn "Username mismatch: old Mac is '$REMOTE_USER', this Mac is '$USER'"
    warn "Rekordbox stores absolute file paths — tracks will show as missing."
    warn "After import, use Rekordbox > File > Display All Missing Files > Relocate"
    if [ "$DRY_RUN" = false ]; then
        echo ""
        read -p "Continue? [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || exit 0
    fi
fi

# --- Dry run: report what would be copied and exit ---
if [ "$DRY_RUN" = true ]; then
    echo ""
    ok "Dry run — showing what would be copied:"
    echo ""

    echo "  Rekordbox data:      $MOUNT_POINT/$RB_DATA"
    echo "    Size:              $REMOTE_SIZE"
    echo "    Destination:       $HOME/$RB_DATA"
    if [ -d "$HOME/$RB_DATA" ]; then
        echo "    Local exists:      YES (will be backed up before copy)"
    else
        echo "    Local exists:      no"
    fi
    echo ""

    if [ -f "$MOUNT_POINT/$RB_PREFS" ]; then
        PREFS_SIZE=$(du -sh "$MOUNT_POINT/$RB_PREFS" 2>/dev/null | cut -f1)
        echo "  Preferences:         $MOUNT_POINT/$RB_PREFS"
        echo "    Size:              $PREFS_SIZE"
        echo "    Destination:       $HOME/$RB_PREFS"
    else
        echo "  Preferences:         not found on remote (skipping)"
    fi
    echo ""

    if [ -d "$MOUNT_POINT/$RB_APP_SUPPORT" ]; then
        APP_SUPPORT_SIZE=$(du -sh "$MOUNT_POINT/$RB_APP_SUPPORT" 2>/dev/null | cut -f1)
        echo "  Application Support: $MOUNT_POINT/$RB_APP_SUPPORT"
        echo "    Size:              $APP_SUPPORT_SIZE"
        echo "    Destination:       $HOME/$RB_APP_SUPPORT"
    else
        echo "  Application Support: not found on remote (skipping)"
    fi
    echo ""

    ok "Dry run complete. Run without --dry-run to copy."
    exit 0
fi

# --- Back up existing local data ---
if [ -d "$HOME/$RB_DATA" ]; then
    BACKUP="$HOME/$RB_DATA.backup-$(date +%Y%m%d-%H%M%S)"
    warn "Existing local Rekordbox data found. Backing up to:"
    warn "  $BACKUP"
    mv "$HOME/$RB_DATA" "$BACKUP"
fi

# --- Copy with ditto ---
info "Copying Rekordbox data (this may take a while for $REMOTE_SIZE)..."
ditto "$MOUNT_POINT/$RB_DATA" "$HOME/$RB_DATA"
ok "Rekordbox data copied."

if [ -f "$MOUNT_POINT/$RB_PREFS" ]; then
    info "Copying preferences..."
    ditto "$MOUNT_POINT/$RB_PREFS" "$HOME/$RB_PREFS"
    ok "Preferences copied."
fi

if [ -d "$MOUNT_POINT/$RB_APP_SUPPORT" ]; then
    info "Copying Application Support data..."
    ditto "$MOUNT_POINT/$RB_APP_SUPPORT" "$HOME/$RB_APP_SUPPORT"
    ok "Application Support copied."
fi

# --- Done ---
echo ""
ok "Rekordbox migration complete!"
echo ""
info "Next steps:"
echo "  1. Transfer your music files to this machine (same folder structure)"
echo "  2. Launch Rekordbox"
echo "  3. If tracks show missing, use File > Display All Missing Files > Relocate"
if [ "$REMOTE_USER" != "$USER" ]; then
    warn "Username changed ($REMOTE_USER → $USER) — you WILL need to relocate tracks."
fi
