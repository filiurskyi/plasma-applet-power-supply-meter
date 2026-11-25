#!/bin/sh
# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Reports which tools are available for each task and how to install the
# missing ones. Never installs anything.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

missing=""
check() { # group tool [qt]
    if [ "${3:-}" = qt ]; then path=$(qt_tool "$2" || true); else path=$(command -v "$2" || true); fi
    if [ -n "$path" ]; then
        printf '  %-16s %s\n' "$2" "$path"
    else
        printf '  %-16s MISSING\n' "$2"
        missing="$missing $2"
    fi
}

echo "Install and package (required):"
check required kpackagetool6
check required python3
echo "Run the widget in a window:"
check run plasmoidviewer
check run plasmawindowed
echo "Development checks (make check):"
check dev qmllint qt
check dev qmlformat qt
check dev qmltestrunner qt
check dev xmllint
check dev shellcheck
check dev reuse
check dev xgettext
check dev msgmerge
check dev msgfmt
echo "Screenshots (make screenshots):"
check shots kwin_wayland
check shots plasmashell
check shots spectacle
check shots qdbus6
check shots dbus-run-session
check shots lookandfeeltool

if [ -z "$missing" ]; then
    echo "doctor: everything is available"
    exit 0
fi

cat <<'HINTS'

Missing tools are only needed for the tasks listed above. Typical packages:
  Arch:          sudo pacman -S plasma-sdk qt6-declarative gettext libxml2 shellcheck reuse
  Fedora:        sudo dnf install plasma-sdk qt6-qtdeclarative-devel gettext libxml2 ShellCheck reuse
  Debian/Ubuntu: sudo apt install plasma-sdk qt6-declarative-dev-tools qml6-module-qttest gettext libxml2-utils shellcheck reuse
  openSUSE:      sudo zypper install plasma6-sdk qt6-declarative-tools gettext-tools libxml2-tools ShellCheck reuse
Package names differ between releases; search your distribution if one is not found.
HINTS
exit 1
