#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Usage: scripts/format.sh [--check]
# Formats QML with qmlformat using .qmlformat.ini. With --check, only
# reports files that would change.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

qmlformat=$(require_qt_tool qmlformat)
cd "$repo"
status=0
for file in $(qml_files); do
    if [ "${1:-}" = --check ]; then
        if ! "$qmlformat" "$file" | cmp -s - "$file"; then
            echo "needs formatting: ${file#"$repo"/}"
            status=1
        fi
    else
        "$qmlformat" -i "$file"
    fi
done
exit "$status"
