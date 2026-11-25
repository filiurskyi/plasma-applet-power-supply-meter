#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Takes store screenshots inside a throwaway, headless Plasma session
# (scripts/sandbox.sh). The real desktop is never touched or captured.
#
# Usage: scripts/screenshots.sh [output-dir]   (default: screenshots/)
# Env:   THEMES="org.kde.breeze.desktop org.kde.breezedark.desktop"
#        SIZE=1280x800  PANEL_HEIGHT=44  PACKAGE=dir-or-.plasmoid
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
out=$(mkdir -p "${1:-$repo/screenshots}" && cd "${1:-$repo/screenshots}" && pwd)
themes=${THEMES:-"org.kde.breeze.desktop org.kde.breezedark.desktop"}

for theme in $themes; do
    name=$(echo "$theme" | sed 's/^org\.kde\.//; s/\.desktop$//')
    echo "screenshots: $name"
    "$repo/scripts/sandbox.sh" "$repo/scripts/screenshots-session.sh" "$theme" "$out/$name" "${PANEL_HEIGHT:-44}"
done

# Close-ups of the panel corner with the popup open: the gauge is tiny in a
# full-desktop shot. Optional: needs Python's PIL (python3-pil / python-pillow).
if python3 -c 'import PIL' 2>/dev/null; then
    for shot in "$out"/*-popup.png; do
        python3 -I - "$shot" "${shot%-popup.png}-closeup.png" <<'PY'
import sys
from PIL import Image
image = Image.open(sys.argv[1])
width, height = image.size
image.crop((max(0, width - 600), max(0, height - 200), width, height)).save(sys.argv[2])
PY
    done
else
    echo "screenshots: python3 PIL not found, skipping close-ups"
fi
ls -1 "$out"
