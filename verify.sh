#!/usr/bin/env bash
set -euo pipefail

echo "Launchers:"
grep -n '^Exec=\|^Icon=\|^StartupWMClass=' "$HOME/.local/share/applications/brave-personal.desktop" "$HOME/.local/share/applications/brave-work.desktop"
echo
echo "Wrappers:"
readlink -f "$HOME/.config/BraveSoftware/Brave-Workspace-Personal/Default"
readlink -f "$HOME/.config/BraveSoftware/Brave-Workspace-Work/Profile 1"
echo
echo "Dock favorites:"
gsettings get org.gnome.shell favorite-apps
