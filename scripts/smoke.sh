#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Runtime smoke test in a throwaway, headless Plasma session
# (scripts/sandbox.sh). It:
#  - installs the release archive (dist/*.plasmoid, built if missing),
#  - places the widget in thin and thick panels, a vertical panel, on the
#    desktop and as a second instance with other settings,
#  - fails if plasmashell logged any warning about the widget.
# Screenshots land in build/smoke/ for a human to review.
#
# Usage: scripts/smoke.sh   Env: THEME=org.kde.breezedark.desktop
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

out="$repo/build/smoke"
rm -rf "$out"
mkdir -p "$out"

version=$(metadata Version)
archive=$(find "$repo/dist" -name "*-$version.plasmoid" 2>/dev/null | head -1)
if [ -z "$archive" ]; then
    python3 "$repo/scripts/package.py" build >/dev/null
    archive=$(find "$repo/dist" -name "*-$version.plasmoid" | head -1)
fi
echo "smoke: installing $(basename "$archive")"

PACKAGE="$archive" SANDBOX_LOG="$out/plasmashell.log" \
    "$repo/scripts/sandbox.sh" "$repo/scripts/smoke-session.sh" "${THEME:-org.kde.breezedark.desktop}" "$out"

# Any log line naming the widget is a failure, except the executable
# engine's harmless startup message (see docs/ARCHITECTURE.md).
problems=$(grep -i -e "$(metadata Id)" -e "contents/ui/" -e "contents/code/" "$out/plasmashell.log" \
    | grep -v 'already running' || true)
if [ -n "$problems" ]; then
    echo "smoke: FAILED, plasmashell reported:" >&2
    printf '%s\n' "$problems" >&2
    exit 1
fi
[ ! -e "$out/scale-150-skipped.txt" ] || echo "smoke: fractional scaling was not available, not tested"
echo "smoke: no widget warnings; review the screenshots in ${out#"$repo"/}/"
ls -1 "$out"
