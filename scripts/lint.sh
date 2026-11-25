#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Static analysis: qmllint, kcfg XML, metadata JSON, shellcheck.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

status=0

echo "lint: metadata.json"
python3 -m json.tool "$repo/package/metadata.json" >/dev/null || status=1

echo "lint: main.xml"
require xmllint
xmllint --noout "$repo/package/contents/config/main.xml" || status=1

echo "lint: qmllint"
qmllint=$(require_qt_tool qmllint)
import_dir=$(qtpaths6 --query QT_INSTALL_QML 2>/dev/null || true)
# Two warning kinds are expected for every Plasma widget and are filtered:
#  - i18n*() are injected at runtime by KLocalizedContext;
#  - Plasmoid.configuration keys come from main.xml at runtime.
# Everything else fails the check.
# shellcheck disable=SC2046
output=$("$qmllint" ${import_dir:+-I "$import_dir"} $(qml_files) "$repo/package/contents/code/supply.js" 2>&1 || true)
filtered=$(printf '%s\n' "$output" | awk '
    /^(Warning|Info|Error):/ {
        header = $0; getline code; getline caret
        if (header ~ /Unqualified access/ && code ~ /i18n[cp]*\(/) next
        if (header ~ /not found on type "KConfigPropertyMap"/) next
        print header; print code; print caret; next
    }
    { print }')
if [ -n "$(printf '%s' "$filtered" | tr -d '[:space:]')" ]; then
    printf '%s\n' "$filtered"
    status=1
fi

echo "lint: shellcheck"
require shellcheck
(cd "$repo" && shellcheck -x scripts/*.sh) || status=1

[ "$status" -eq 0 ] && echo "lint: ok"
exit "$status"
