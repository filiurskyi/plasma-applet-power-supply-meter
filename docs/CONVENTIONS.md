# Conventions

| Class | Meaning |
|---|---|
| Required | Plasma or the KDE Store will not work or will reject it otherwise |
| Official | a KDE or Qt recommendation |
| Community | common practice among maintained third-party widgets |
| Project | a decision made for this repository |

Sources were checked on 2026-11-25.

## Package and metadata

| Rule | Class | Source / verification |
|---|---|---|
| `metadata.json` with `"KPackageStructure": "Plasma/Applet"`; `metadata.desktop` is not supported in KF6 | Required | [Widget properties](https://develop.kde.org/docs/plasma/widget/properties/), [porting to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/) |
| `X-Plasma-API-Minimum-Version: "6.0"` so Plasma 6 loads the widget | Required | porting guide |
| Root item is `PlasmoidItem`, with `Plasmoid` as an attached property | Required | porting guide; battery applet (powerdevil) |
| `Category` from the documented list | Official | widget properties page; list in `scripts/init.py` |
| Plugin id is a reverse domain you control; `org.kde.*` is for KDE projects | Official | the KDE tutorial uses `com.github.zren.helloworld` |
| `io.github.<user>.<widget>` rather than `com.github.<user>.<widget>` | Project | tied to the `<user>.github.io` domain the author owns; the form Flathub expects for GitHub-hosted apps |
| Repository named `plasma-applet-<name>` | Community | Zren/plasma-applet-eventcalendar, kotelnik/plasma-applet-thermal-monitor, orblazer/plasma-applet-resources-monitor |
| `.plasmoid` is a zip with `metadata.json` at the archive root | Required | `kpackagetool6 --install` |
| Translation domain `plasma_applet_<id>`, catalogs in `contents/locale/<lang>/LC_MESSAGES/` | Required | KPackage/Plasma loads packaged catalogs from there |

## QML and Plasma APIs

| Rule | Class | Source / verification |
|---|---|---|
| Plasma 6 public modules only: `org.kde.plasma.plasmoid`, `.core`, `.components`, Kirigami, KCMUtils, KQuickControls, KQuickCharts | Official | api.kde.org; each type checked against the installed `plugins.qmltypes` |
| `PlasmaCore.Action` in `Plasmoid.contextualActions` | Official | battery monitor applet (powerdevil) |
| `KCMUtils.SimpleKCM` + `Kirigami.FormLayout` for settings pages; `cfg_<key>` properties | Official | Digital Clock applet (plasma-workspace). Its settings have since moved to `Kirigami.FormEntry`; `FormLayout` exists in every Plasma 6 release, and the minimum is 6.0 |
| Font settings stored as separate family/weight/style keys and chosen with `Qt.labs.platform` `FontDialog` | Official (copied) | Digital Clock `configAppearance.qml` |
| Compact representation is a `MouseArea` with a `wasExpanded` latch, `activeFocusOnTab`, `Accessible.role: Button` | Official | battery monitor `CompactRepresentation.qml` |
| `pragma ComponentBehavior: Bound` and `required property` in delegates | Official | [Qt QML coding conventions](https://doc.qt.io/qt-6/qml-codingconventions.html); qmllint recommends it |
| Theme values (`Kirigami.Theme.*`, `Kirigami.Units.*`) instead of hard-coded colours and sizes | Official | [KDE HIG](https://develop.kde.org/hig/) |
| No Qt5Compat (`GraphicalEffects`); outline the label with `Text.Outline` | Official | Qt5Compat exists only for porting |
| Plasma5Support "executable" engine for reading sysfs | Project (justified exception) | Plasma 5 data engines are deprecated, but nothing in Plasma 6 or UPower exposes the PD rating (checked: UPower D-Bus, the ksystemstats `power` and `lmsensors` plugins, the `powermanagement` engine). The alternative, a compiled plugin, would make the package architecture-dependent |
| Control paddings set individually (`leftPadding: 0` etc.) | Project | the Plasma style sets the side paddings explicitly, so `padding: 0` has no effect and the gauge shrinks |

## Formatting and linting

| Rule | Class | Source / verification |
|---|---|---|
| `qmlformat` with `.qmlformat.ini` (4 spaces, no column limit) | Official tool | `make format-check` |
| `qmllint` clean, except `i18n*()` unqualified access and `Plasmoid.configuration` members, which are injected at runtime | Project | `scripts/lint.sh` filters those two kinds and fails on everything else |
| POSIX `sh` scripts that pass shellcheck; Python 3 standard library only | Project | `make lint` (shellcheck) |

## Localization

| Rule | Class | Source / verification |
|---|---|---|
| `i18n`, `i18nc`, `i18np`, `i18ncp` with placeholders, no concatenation | Official | [KDE i18n tutorial](https://develop.kde.org/docs/plasma/widget/translations-i18n/) |
| Context strings such as `@label`, `@info`, `@action` | Official | KDE i18n semantic markup |
| Numbers formatted with `toLocaleString(Qt.locale(), …)` | Project | `main.qml` |
| Extract with xgettext over the QML/JS files, compile with msgfmt | Official | KDE i18n tutorial; `scripts/translations.sh`, `scripts/package.py` |
| Catalog sources in `po/` instead of the tutorial's `package/translate/`, compiled only into the build | Project | keeps development files out of the shipped package |

## Licensing

| Rule | Class | Source / verification |
|---|---|---|
| SPDX headers in every source file; `REUSE.toml` for JSON, images, translations and docs | Official | [REUSE 3.3](https://reuse.software/spec/); `make reuse` in CI |
| GPL-3.0-or-later | Project | the author's choice |
| Licence text shipped inside the `.plasmoid` (`contents/LICENSES/`) | Project | GPL-3.0 §4–6 require a copy of the licence with distributed copies |

## Distribution and releases

| Rule | Class | Source / verification |
|---|---|---|
| Content follows the KDE Store publishing terms (own work or compatible licence, no malware, accurate description) | Required | [store.kde.org/terms/publishing](https://store.kde.org/terms/publishing) |
| Semantic versioning; tags `vX.Y.Z` equal to `metadata.json` Version | Project | `scripts/package.py check-tag` in the release workflow |
| Commit titles in Conventional Commits style (`type(scope): description`), title line only | Project | [CONTRIBUTING.md](../CONTRIBUTING.md); Dependabot uses the `ci` prefix |
| GitHub Actions pinned to commit SHAs, least-privilege `permissions` | Official (GitHub) | GitHub security hardening guide; Dependabot updates the pins |
| KDE Store upload by hand | Project | no supported, documented upload API was found |
