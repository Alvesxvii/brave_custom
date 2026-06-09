#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_DIR="$REPO_DIR/icons"
BASE_ICON="${BASE_ICON:-/usr/share/icons/hicolor/256x256/apps/brave-browser.png}"

if ! command -v convert >/dev/null 2>&1; then
    echo "ImageMagick 'convert' is required." >&2
    exit 1
fi

mkdir -p "$ICON_DIR"

convert "$BASE_ICON" \
  \( -size 96x96 xc:none -fill '#4b5563' -stroke white -strokewidth 4 -draw 'circle 48,48 48,4' -fill white -stroke none -font DejaVu-Sans-Bold -gravity center -pointsize 34 -annotate +0+2 'D' \) \
  -gravity southeast -geometry +8+8 -composite \
  "$ICON_DIR/brave-dev.png"

convert "$BASE_ICON" \
  \( -size 96x96 xc:none -fill '#22c55e' -stroke white -strokewidth 4 -draw 'circle 48,48 48,4' -fill white -stroke none -font DejaVu-Sans-Bold -gravity center -pointsize 34 -annotate +0+2 'W' \) \
  -gravity southeast -geometry +8+8 -composite \
  "$ICON_DIR/brave-work-badge.png"

echo "Icons generated in $ICON_DIR"
