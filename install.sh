#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_APPS_DIR="$HOME/.local/share/applications"
LOCAL_ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

BRAVE_MASTER_DIR="${BRAVE_MASTER_DIR:-$HOME/.config/BraveSoftware/Brave-Browser}"
BRAVE_DEV_SOURCE_PROFILE="${BRAVE_DEV_SOURCE_PROFILE:-Default}"
BRAVE_WORK_SOURCE_PROFILE="${BRAVE_WORK_SOURCE_PROFILE:-Profile 1}"
BRAVE_DEV_WRAPPER_DIR="$HOME/.config/BraveSoftware/Brave-Workspace-Personal"
BRAVE_WORK_WRAPPER_DIR="$HOME/.config/BraveSoftware/Brave-Workspace-Work"

require_file() {
    if [ ! -e "$1" ]; then
        echo "Required path not found: $1" >&2
        exit 1
    fi
}

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        mv "$target" "${target}.bak-$STAMP"
    fi
}

require_file "$BRAVE_MASTER_DIR"
require_file "$BRAVE_MASTER_DIR/$BRAVE_DEV_SOURCE_PROFILE"
require_file "$BRAVE_MASTER_DIR/$BRAVE_WORK_SOURCE_PROFILE"
require_file "$REPO_DIR/bin/brave-personal"
require_file "$REPO_DIR/bin/brave-work"
require_file "$REPO_DIR/desktop/brave-personal.desktop.template"
require_file "$REPO_DIR/desktop/brave-work.desktop.template"
require_file "$REPO_DIR/icons/brave-dev.png"
require_file "$REPO_DIR/icons/brave-work-badge.png"

mkdir -p "$LOCAL_BIN_DIR" "$LOCAL_APPS_DIR" "$LOCAL_ICON_DIR"

install -m 0755 "$REPO_DIR/bin/brave-personal" "$LOCAL_BIN_DIR/brave-personal"
install -m 0755 "$REPO_DIR/bin/brave-work" "$LOCAL_BIN_DIR/brave-work"
install -m 0644 "$REPO_DIR/icons/brave-dev.png" "$LOCAL_ICON_DIR/brave-dev.png"
install -m 0644 "$REPO_DIR/icons/brave-work-badge.png" "$LOCAL_ICON_DIR/brave-work-badge.png"

sed "s|__HOME__|$HOME|g" \
    "$REPO_DIR/desktop/brave-personal.desktop.template" \
    > "$LOCAL_APPS_DIR/brave-personal.desktop"
sed "s|__HOME__|$HOME|g" \
    "$REPO_DIR/desktop/brave-work.desktop.template" \
    > "$LOCAL_APPS_DIR/brave-work.desktop"

backup_if_exists "$BRAVE_DEV_WRAPPER_DIR"
backup_if_exists "$BRAVE_WORK_WRAPPER_DIR"

mkdir -p "$BRAVE_DEV_WRAPPER_DIR" "$BRAVE_WORK_WRAPPER_DIR"
cp -a "$BRAVE_MASTER_DIR/Local State" "$BRAVE_DEV_WRAPPER_DIR/"
cp -a "$BRAVE_MASTER_DIR/Local State" "$BRAVE_WORK_WRAPPER_DIR/"
cp -a "$BRAVE_MASTER_DIR/First Run" "$BRAVE_DEV_WRAPPER_DIR/" 2>/dev/null || true
cp -a "$BRAVE_MASTER_DIR/First Run" "$BRAVE_WORK_WRAPPER_DIR/" 2>/dev/null || true

ln -s "$BRAVE_MASTER_DIR/$BRAVE_DEV_SOURCE_PROFILE" "$BRAVE_DEV_WRAPPER_DIR/Default"
ln -s "$BRAVE_MASTER_DIR/$BRAVE_WORK_SOURCE_PROFILE" "$BRAVE_WORK_WRAPPER_DIR/Profile 1"

python3 - <<'PY'
import json
import os

paths = [
    (os.path.expanduser("~/.config/BraveSoftware/Brave-Workspace-Personal/Local State"), "Default"),
    (os.path.expanduser("~/.config/BraveSoftware/Brave-Workspace-Work/Local State"), "Profile 1"),
]

for path, last_used in paths:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    data.setdefault("profile", {})["last_used"] = last_used
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))
PY

update-desktop-database "$LOCAL_APPS_DIR" >/dev/null 2>&1 || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true

echo "Installed Brave workspace customization."
echo "DEV wrapper:  $BRAVE_DEV_WRAPPER_DIR -> $BRAVE_MASTER_DIR/$BRAVE_DEV_SOURCE_PROFILE"
echo "WORK wrapper: $BRAVE_WORK_WRAPPER_DIR -> $BRAVE_MASTER_DIR/$BRAVE_WORK_SOURCE_PROFILE"
echo
echo "If needed, pin these launchers to the Ubuntu Dock:"
echo "  $LOCAL_APPS_DIR/brave-personal.desktop"
echo "  $LOCAL_APPS_DIR/brave-work.desktop"
