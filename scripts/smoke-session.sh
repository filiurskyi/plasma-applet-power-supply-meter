#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Runs inside the throwaway session started by scripts/smoke.sh. Places the
# widget in the layouts from the manual test matrix and takes a screenshot
# of each. Do not run it directly.
set -eu
plugin_id=$1 theme=$2 out=$3

lookandfeeltool --apply "$theme" >/dev/null 2>&1 || true
plasmashell --no-respawn >"$XDG_STATE_HOME/plasmashell.log" 2>&1 &

i=0
until qdbus6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1; do
    i=$((i + 1)); [ "$i" -lt 60 ] || { echo "plasmashell did not start" >&2; exit 1; }
    sleep 0.5
done
sleep 3

shell() { qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"; }
shot() { sleep "${2:-3}"; spectacle -b -n -f -o "$out/$1.png" >/dev/null 2>&1; echo "smoke: $1"; }

# Horizontal panel, thin and thick.
shell "var p = panels()[0]; p.height = 24; p.addWidget('$plugin_id');"
shot panel-24
shell "panels()[0].height = 64;"
shot panel-64

# A second instance with its own settings: half-scale and a custom colour.
# Both must render independently.
shell "
var p = panels()[0];
p.height = 44;
var w = p.addWidget('$plugin_id');
w.currentConfigGroup = ['General'];
w.writeConfig('maxWatts', 260);
w.currentConfigGroup = ['Appearance'];
w.writeConfig('customGaugeColor', true);
w.writeConfig('gaugeColor', '#e93d3d');
w.reloadConfig();
"
shot two-instances

# Vertical panel on the left edge.
shell "var v = new Panel('org.kde.panel'); v.location = 'left'; v.height = 48; v.addWidget('$plugin_id');"
shot vertical-panel

# On the desktop.
shell "desktops()[0].addWidget('$plugin_id', 300, 200, 160, 160);"
shot desktop

# Fractional scaling, when the virtual output allows it.
output=$(kscreen-doctor -o 2>/dev/null | sed -n 's/^Output: [0-9]* \([^ ]*\).*/\1/p' | head -1)
if [ -n "$output" ] && kscreen-doctor "output.$output.scale.1.5" >/dev/null 2>&1; then
    shot scale-150 4
else
    echo "fractional scaling not available in this session" >"$out/scale-150-skipped.txt"
fi

kquitapp6 plasmashell >/dev/null 2>&1 || true
