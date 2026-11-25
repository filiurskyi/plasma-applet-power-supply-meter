# SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Developer interface. Every target is a thin wrapper around a script in
# scripts/ so it also works without make. Run `make help` for the list.

.POSIX:
.SUFFIXES:

PLUGIN_ID = $$(python3 -c 'import json; print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')
INSTALL_DIR = $${XDG_DATA_HOME:-$$HOME/.local/share}/plasma/plasmoids

help:
	@echo "Usage: make <target>"
	@echo
	@echo "  doctor         check which tools are installed (never installs anything)"
	@echo "  init           turn a fresh template clone into a new widget (scripts/init.py)"
	@echo "  install        build and install for the current user (kpackagetool6)"
	@echo "  upgrade        build and upgrade an installed copy"
	@echo "  link           install as a symlink to package/ for development"
	@echo "  uninstall      remove the installed copy or symlink"
	@echo "  run            open the widget in a window (plasmoidviewer or plasmawindowed)"
	@echo "  restart-plasma restart plasmashell so an installed or linked copy reloads"
	@echo "  lint           qmllint, kcfg/JSON validation, shellcheck"
	@echo "  format         format QML with qmlformat"
	@echo "  format-check   fail if QML is not formatted"
	@echo "  test           Python repository tests and Qt Quick Tests"
	@echo "  translations   regenerate po/*.pot and merge po/*.po"
	@echo "  package        build dist/<name>-<version>.plasmoid and .sha256"
	@echo "  reuse          REUSE licensing compliance"
	@echo "  check          everything CI runs"
	@echo "  smoke          runtime test of the built .plasmoid in a headless Plasma session"
	@echo "  screenshots    light/dark panel and popup shots in a headless session"
	@echo "  clean          remove build/ and dist/"

doctor:
	@scripts/doctor.sh

init:
	@python3 scripts/init.py

install:
	python3 scripts/package.py stage
	kpackagetool6 --type Plasma/Applet --install build/package

upgrade:
	python3 scripts/package.py stage
	kpackagetool6 --type Plasma/Applet --upgrade build/package

# Plasma loads packages from symlinked directories, so edits under package/
# take effect after `make restart-plasma` without reinstalling. Translations
# are not compiled in this mode.
link:
	@target="$(INSTALL_DIR)/$(PLUGIN_ID)"; \
	if [ -L "$$target" ]; then echo "already linked: $$target"; \
	elif [ -e "$$target" ]; then echo "error: $$target exists and is not a symlink; run 'make uninstall' first" >&2; exit 1; \
	else mkdir -p "$(INSTALL_DIR)" && ln -s "$$PWD/package" "$$target" && echo "linked $$target -> $$PWD/package"; fi

uninstall:
	@target="$(INSTALL_DIR)/$(PLUGIN_ID)"; \
	if [ -L "$$target" ]; then rm "$$target" && echo "removed symlink $$target"; \
	else kpackagetool6 --type Plasma/Applet --remove "$(PLUGIN_ID)"; fi

run:
	@if command -v plasmoidviewer >/dev/null 2>&1; then plasmoidviewer --applet package; \
	else echo "plasmoidviewer not found; using plasmawindowed with the installed copy"; plasmawindowed "$(PLUGIN_ID)"; fi

restart-plasma:
	systemctl --user restart plasma-plasmashell.service

lint:
	scripts/lint.sh

format:
	scripts/format.sh

format-check:
	scripts/format.sh --check

test:
	PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
	@qmltestrunner=$$(. scripts/lib.sh; qt_tool qmltestrunner) || { echo "error: qmltestrunner not found; run 'make doctor'" >&2; exit 1; }; \
	QT_QPA_PLATFORM=$${QT_QPA_PLATFORM:-offscreen} "$$qmltestrunner" -input tests/qml

translations:
	scripts/translations.sh extract
	scripts/translations.sh merge

translations-check:
	scripts/translations.sh check

package:
	python3 scripts/package.py build

reuse:
	reuse lint

check: format-check lint translations-check reuse test package

smoke:
	scripts/smoke.sh

screenshots:
	scripts/screenshots.sh

clean:
	rm -rf build dist

.PHONY: help doctor init install upgrade link uninstall run restart-plasma lint format format-check test \
	translations translations-check package reuse check smoke screenshots clean
