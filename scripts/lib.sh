# shellcheck shell=sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Shared helpers for the POSIX sh scripts in this directory. Source it, do
# not execute it.

repo=$(cd "$(dirname "$0")/.." && pwd)

die() {
    echo "error: $*" >&2
    exit 1
}

# Prints the path of a Qt developer tool. Distributions install them under
# different names and directories (qmllint, qmllint6, /usr/lib/qt6/bin).
qt_tool() {
    for candidate in "$1" "${1}6" "${1}-qt6"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done
    for dir in "${QT_BIN:-}" "$(qtpaths6 --query QT_HOST_BINS 2>/dev/null)" \
               "$(qtpaths6 --query QT_HOST_LIBEXECS 2>/dev/null)" \
               /usr/lib/qt6/bin /usr/lib64/qt6/bin /usr/libexec/qt6; do
        if [ -n "$dir" ] && [ -x "$dir/$1" ]; then
            echo "$dir/$1"
            return 0
        fi
    done
    return 1
}

require_qt_tool() {
    qt_tool "$1" || die "'$1' not found; run 'make doctor' for install hints"
}

require() {
    command -v "$1" >/dev/null 2>&1 || die "'$1' not found; run 'make doctor' for install hints"
}

metadata() {
    python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["KPlugin"][sys.argv[2]])' \
        "$repo/package/metadata.json" "$1"
}

qml_files() {
    find "$repo/package" "$repo/tests" -name '*.qml' | sort
}
