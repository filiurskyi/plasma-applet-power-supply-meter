#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Takes store screenshots inside a throwaway, headless Plasma session:
# a virtual KWin compositor with its own D-Bus session bus and its own
# XDG config/data/cache directories. The real desktop, its windows and its
# settings are never touched or captured.
#
# Usage: scripts/screenshots.sh [output-dir]   (default: screenshots/)
# Env:   THEMES="org.kde.breeze.desktop org.kde.breezedark.desktop"
#        SIZE=1280x800  PANEL_HEIGHT=44
set -eu

repo=$(cd "$(dirname "$0")/.." && pwd)
out=$(mkdir -p "${1:-$repo/screenshots}" && cd "${1:-$repo/screenshots}" && pwd)
size=${SIZE:-1280x800}
themes=${THEMES:-"org.kde.breeze.desktop org.kde.breezedark.desktop"}

for tool in kwin_wayland dbus-run-session plasmashell spectacle kpackagetool6 lookandfeeltool qdbus6 jq; do
    command -v "$tool" >/dev/null 2>&1 || { echo "screenshots: missing '$tool'" >&2; exit 1; }
done

package=${PACKAGE:-$repo/package}
# D-Bus-activated daemons (portal, ksecretd, activity manager) outlive the
# session; stop only the processes whose environment points into this sandbox.
stop_sandbox_processes() {
    for pid in $(pgrep -u "$(id -u)"); do
        if tr '\0' '\n' 2>/dev/null <"/proc/$pid/environ" | grep -qx "XDG_CONFIG_HOME=$1/config"; then
            kill "$pid" 2>/dev/null || true
        fi
    done
}

plugin_id=$(jq -r .KPlugin.Id "$package/metadata.json")

for theme in $themes; do
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/psm-shots.XXXXXX")
    name=$(echo "$theme" | sed 's/^org\.kde\.//; s/\.desktop$//')
    echo "screenshots: $name in $sandbox"
    (
        export XDG_CONFIG_HOME="$sandbox/config" XDG_DATA_HOME="$sandbox/data" \
               XDG_CACHE_HOME="$sandbox/cache" XDG_STATE_HOME="$sandbox/state"
        unset DISPLAY WAYLAND_DISPLAY
        mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
        kpackagetool6 -t Plasma/Applet -i "$package" >/dev/null
        dbus-run-session -- kwin_wayland --virtual --no-lockscreen \
            --width "${size%x*}" --height "${size#*x}" \
            --exit-with-session "$repo/scripts/screenshots-session.sh $plugin_id $theme $out/$name ${PANEL_HEIGHT:-44}" \
            >"$sandbox/session.log" 2>&1
    ) || { stop_sandbox_processes "$sandbox"; echo "screenshots: session failed, see $sandbox/session.log" >&2; exit 1; }
    stop_sandbox_processes "$sandbox"
    sleep 1
    [ -n "${KEEP_SANDBOX:-}" ] || rm -rf "$sandbox" 2>/dev/null || true
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
