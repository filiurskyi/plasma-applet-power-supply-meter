#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Runs inside the throwaway session started by screenshots.sh. Do not run
# it directly: it expects the sandboxed XDG and D-Bus environment.
set -eu
plugin_id=$1 theme=$2 prefix=$3 panel_height=$4

lookandfeeltool --apply "$theme" >/dev/null 2>&1 || true
mkdir -p "$XDG_STATE_HOME"
plasmashell --no-respawn >"$XDG_STATE_HOME/plasmashell.log" 2>&1 &

i=0
until qdbus6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1; do
    i=$((i + 1)); [ "$i" -lt 60 ] || { echo "plasmashell did not start" >&2; exit 1; }
    sleep 0.5
done
sleep 3

shell() { qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"; }

# Add the widget to the default panel and give it a shortcut so the popup
# can be opened without input injection.
shell "
var panel = panels()[0];
panel.height = $panel_height;
var w = panel.addWidget('$plugin_id');
w.globalShortcut = 'Meta+Ctrl+Alt+F12';
"
sleep 3
spectacle -b -n -f -o "$prefix-panel.png" >/dev/null 2>&1

toggle_popup() {
    qdbus6 org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut \
        "activate widget $(shell "print(panels()[0].widgets('$plugin_id')[0].id)")" >/dev/null 2>&1 || true
    sleep 2
}
toggle_popup
spectacle -b -n -f -o "$prefix-popup.png" >/dev/null 2>&1

# The settings dialog cannot be opened from here: the scripting API's
# showConfigurationInterface() does nothing in this headless session.
# Capture it manually instead (docs/SCREENSHOTS.md).
kquitapp6 plasmashell >/dev/null 2>&1 || true
