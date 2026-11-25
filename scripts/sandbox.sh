#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Runs a script inside a throwaway, headless Plasma session: a virtual KWin
# compositor with its own D-Bus session bus and its own XDG config, data,
# cache and state directories. The real desktop, its windows and its settings
# are never touched or captured.
#
# Usage: scripts/sandbox.sh SESSION_SCRIPT THEME [ARGS...]
#   SESSION_SCRIPT runs inside the session as: SESSION_SCRIPT PLUGIN_ID THEME [ARGS...]
# Env:   PACKAGE      package directory or .plasmoid file (default: package/)
#        SIZE         virtual screen size (default: 1280x800)
#        SANDBOX_LOG  copy plasmashell's log here when done
#        KEEP_SANDBOX keep the temporary directory
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

[ $# -ge 2 ] || die "usage: $0 SESSION_SCRIPT THEME [ARGS...]"
session_script=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
shift
size=${SIZE:-1280x800}
package=${PACKAGE:-$repo/package}

for tool in kwin_wayland dbus-run-session plasmashell spectacle kpackagetool6 lookandfeeltool qdbus6; do
    require "$tool"
done

plugin_id=$(python3 - "$package" <<'PY'
import json, sys, zipfile
path = sys.argv[1]
if zipfile.is_zipfile(path):
    meta = json.loads(zipfile.ZipFile(path).read("metadata.json"))
else:
    meta = json.load(open(path + "/metadata.json"))
print(meta["KPlugin"]["Id"])
PY
)

# D-Bus-activated daemons (portal, ksecretd, activity manager) outlive the
# session; stop only the processes whose environment points into this sandbox.
stop_sandbox_processes() {
    for pid in $(pgrep -u "$(id -u)"); do
        if tr '\0' '\n' 2>/dev/null <"/proc/$pid/environ" | grep -qx "XDG_CONFIG_HOME=$1/config"; then
            kill "$pid" 2>/dev/null || true
        fi
    done
}

sandbox=$(mktemp -d "${TMPDIR:-/tmp}/psm-shots.XXXXXX")
status=0
(
    export XDG_CONFIG_HOME="$sandbox/config" XDG_DATA_HOME="$sandbox/data" \
           XDG_CACHE_HOME="$sandbox/cache" XDG_STATE_HOME="$sandbox/state"
    unset DISPLAY WAYLAND_DISPLAY
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
    kpackagetool6 -t Plasma/Applet -i "$package" >/dev/null
    # kwin_wayland splits --exit-with-session on spaces, so pass arguments
    # through a generated wrapper instead.
    wrapper="$sandbox/session"
    {
        echo '#!/bin/sh'
        printf 'exec'
        for arg in "$session_script" "$plugin_id" "$@"; do
            printf " '%s'" "$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")"
        done
        echo
    } >"$wrapper"
    chmod +x "$wrapper"
    dbus-run-session -- kwin_wayland --virtual --no-lockscreen \
        --width "${size%x*}" --height "${size#*x}" \
        --exit-with-session "$wrapper" >"$sandbox/session.log" 2>&1
) || status=$?
stop_sandbox_processes "$sandbox"
sleep 1
if [ -n "${SANDBOX_LOG:-}" ]; then
    cp "$sandbox/state/plasmashell.log" "$SANDBOX_LOG" 2>/dev/null || : >"$SANDBOX_LOG"
fi
if [ "$status" -ne 0 ]; then
    echo "sandbox: session failed, logs kept in $sandbox" >&2
    exit "$status"
fi
if [ -n "${KEEP_SANDBOX:-}" ]; then
    echo "sandbox: kept $sandbox"
else
    rm -rf "$sandbox"
fi
