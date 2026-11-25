#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Usage: scripts/translations.sh extract   regenerate po/<domain>.pot from the sources
#        scripts/translations.sh merge     update every po/*.po from the template
#        scripts/translations.sh new LANG  start po/LANG.po (e.g. uk, de, pt_BR)
#        scripts/translations.sh check     template up to date, catalogs valid
#
# Catalogs are compiled into the package by scripts/package.py, never into
# package/ itself. Plasma loads them from contents/locale/<lang>/LC_MESSAGES/
# using the domain "plasma_applet_<plugin id>".
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

domain="plasma_applet_$(metadata Id)"
pot="$repo/po/$domain.pot"

extract_to() {
    require xgettext
    (
        cd "$repo/package"
        # QML is parsed as JavaScript; keywords match KI18n's QML functions.
        find contents -name '*.qml' -o -name '*.js' | sort | xargs xgettext \
            --from-code=UTF-8 --language=JavaScript --add-comments=i18n \
            --keyword=i18n:1 --keyword=i18nc:1c,2 --keyword=i18np:1,2 --keyword=i18ncp:1c,2,3 \
            --package-name="$(metadata Name)" --package-version="$(metadata Version)" \
            --msgid-bugs-address="$(metadata BugReportUrl)" \
            --copyright-holder="$(metadata Name) contributors" \
            --sort-by-file --width=100 --output="$1"
    )
    # The creation date makes every run differ; strip it so diffs stay quiet.
    sed -i '/^"POT-Creation-Date:/d' "$1"
}

case "${1:-}" in
extract)
    mkdir -p "$repo/po"
    extract_to "$pot"
    echo "translations: wrote ${pot#"$repo"/} ($(grep -c '^msgid "' "$pot") messages incl. header)"
    ;;
merge)
    require msgmerge
    for po in "$repo"/po/*.po; do
        [ -e "$po" ] || continue
        msgmerge --quiet --update --backup=none --width=100 "$po" "$pot"
        echo "translations: merged ${po#"$repo"/}"
    done
    ;;
new)
    [ -n "${2:-}" ] || die "usage: $0 new LANG"
    printf '%s' "$2" | grep -Eq '^[a-z]{2,3}(_[A-Z]{2})?(@[a-z]+)?$' || die "'$2' is not a locale code like uk, de or pt_BR"
    [ ! -e "$repo/po/$2.po" ] || die "po/$2.po already exists"
    require msginit
    msginit --no-translator --input="$pot" --locale="$2" --output-file="$repo/po/$2.po" --width=100
    ;;
check)
    require msgfmt
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    extract_to "$tmp"
    if ! cmp -s "$tmp" "$pot"; then
        echo "translations: ${pot#"$repo"/} is out of date; run 'make translations'" >&2
        diff -u "$pot" "$tmp" >&2 || true
        exit 1
    fi
    for po in "$repo"/po/*.po; do
        [ -e "$po" ] || continue
        msgfmt --check --statistics --output-file=/dev/null "$po"
    done
    echo "translations: ok"
    ;;
*)
    sed -n '5,9p' "$0" | sed 's/^# //'
    exit 2
    ;;
esac
