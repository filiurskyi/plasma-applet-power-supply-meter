# Conventions

Each rule is marked:
- **Required:** Plasma or the KDE Store will not work or will reject it otherwise.
- **Official:** a KDE or Qt recommendation.
- **Community:** common practice among maintained third-party widgets.
- **Project:** a decision made for this repository.

The "Verified" notes say how each rule was checked, on 2026-11-25.

## Package and metadata

| Rule | Class | Source / verification |
|---|---|---|
| `metadata.json` with `"KPackageStructure": "Plasma/Applet"`; `metadata.desktop` is not supported in KF6 | Required | [Widget properties](https://develop.kde.org/docs/plasma/widget/properties/), [porting to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/) |
| `X-Plasma-API-Minimum-Version: "6.0"` so Plasma 6 loads the widget | Required | porting guide |
| Root item is `PlasmoidItem`, with `Plasmoid` as an attached property | Required (Plasma 6) | porting guide; checked against the battery applet in plasma-workspace/powerdevil |
| `Category` from the documented list | Official | widget properties page; the list is reproduced in `scripts/init.py` |
| Plugin id is a reverse domain you control; `org.kde.*` is for KDE projects | Official | the KDE tutorial uses `com.github.zren.helloworld` |
| `io.github.<user>.<widget>` rather than `com.github.<user>.<widget>` | Project | both are common. `io.github` is tied to the `<user>.github.io` domain the author owns, and it is the form Flathub expects for GitHub-hosted apps |
| Repository named `plasma-applet-<name>` | Community | most-starred examples on GitHub: Zren/plasma-applet-eventcalendar, kotelnik/plasma-applet-thermal-monitor, orblazer/plasma-applet-resources-monitor |
| `.plasmoid` is a zip with `metadata.json` at the archive root | Required | `kpackagetool6 --install` |
| Translation domain `plasma_applet_<id>`, catalogs in `contents/locale/<lang>/LC_MESSAGES/` | Required | KPackage/Plasma loads packaged catalogs from there |

## QML and Plasma APIs

| Rule | Class | Source / verification |
|---|---|---|
| Plasma 6 public modules only: `org.kde.plasma.plasmoid`, `.core`, `.components`, Kirigami, KCMUtils, KQuickControls, KQuickCharts | Official | api.kde.org; each type checked against the installed `plugins.qmltypes` |
| `PlasmaCore.Action` in `Plasmoid.contextualActions` | Official | battery monitor applet (powerdevil) |
| `KCMUtils.SimpleKCM` + `Kirigami.FormLayout` for settings pages; `cfg_<key>` properties | Official | Digital Clock applet (plasma-workspace) |
| Font settings stored as separate family/weight/style keys and chosen with `Qt.labs.platform` `FontDialog` | Official (copied) | Digital Clock `configAppearance.qml` uses the same keys and dialog |
| Compact representation is a `MouseArea` with a `wasExpanded` latch, `activeFocusOnTab`, `Accessible.role: Button` | Official | battery monitor `CompactRepresentation.qml` |
| `pragma ComponentBehavior: Bound` and `required property` in delegates | Official | [Qt QML coding conventions](https://doc.qt.io/qt-6/qml-codingconventions.html); qmllint recommends it |
| Theme values (`Kirigami.Theme.*`, `Kirigami.Units.*`) instead of hard-coded colours and sizes | Official | [KDE HIG](https://develop.kde.org/hig/) |
| Avoid Qt5Compat (`GraphicalEffects`); outline the label with `Text.Outline` | Official | Qt5Compat exists only for porting |
| Plasma5Support "executable" engine for reading sysfs | Project (justified exception) | Plasma 5 data engines are deprecated, but nothing in Plasma 6 or UPower exposes the PD rating (checked over UPower D-Bus, the ksystemstats `power` and `lmsensors` plugins, and the `powermanagement` engine). The alternative is a compiled plugin, which would make the package architecture-dependent |
| Control paddings set individually (`leftPadding: 0` etc.) | Project | the Plasma style sets the side paddings explicitly, so `padding: 0` has no effect and the gauge shrinks |

## Formatting and linting

| Rule | Class | Source / verification |
|---|---|---|
| `qmlformat` with `.qmlformat.ini` (4 spaces, no column limit) | Official tool | Qt 6 qmlformat; `make format-check` |
| `qmllint` clean, except `i18n*()` unqualified access and `Plasmoid.configuration` members, which are injected at runtime | Project | `scripts/lint.sh` filters exactly those two kinds and fails on everything else |
| POSIX `sh` scripts that pass shellcheck; Python 3 standard library only | Project | `make lint` |

## Localization

| Rule | Class | Source / verification |
|---|---|---|
| `i18n`, `i18nc`, `i18np`, `i18ncp` with placeholders, no concatenation | Official | [KDE i18n tutorial](https://develop.kde.org/docs/plasma/widget/translations-i18n/) |
| Context strings such as `@label`, `@info`, `@action` | Official | KDE i18n semantic markup |
| Extract with xgettext over the QML/JS files, compile with msgfmt into `contents/locale/<lang>/LC_MESSAGES/plasma_applet_<id>.mo` | Official | [KDE widget translation tutorial](https://develop.kde.org/docs/plasma/widget/translations-i18n/) |
| Catalog sources in `po/` instead of the tutorial's `package/translate/`, compiled only into the build | Project | keeps development files out of the shipped package; `scripts/package.py` rejects anything not on its allow-list |
| No machine translations | Project | |

## Licensing

| Rule | Class | Source / verification |
|---|---|---|
| SPDX headers in every source file; `REUSE.toml` for JSON, images and docs | Official | [REUSE 3.3](https://reuse.software/spec/), KDE uses REUSE; `reuse lint` in CI |
| GPL-3.0-or-later | Project | the author's choice |
| Licence text shipped inside the `.plasmoid` (`contents/LICENSES/`) | Project | GPL-3.0 §4–6 require a copy of the licence with distributed copies |

## Distribution and releases

| Rule | Class | Source / verification |
|---|---|---|
| Content follows the KDE Store publishing terms (own work or compatible licence, no malware, accurate description) | Required | [store.kde.org/terms/publishing](https://store.kde.org/terms/publishing) |
| Semantic versioning; tags `vX.Y.Z` equal to `metadata.json` Version | Project | enforced by `scripts/package.py check-tag` in the release workflow |
| Commit titles in Conventional Commits style (`type(scope): description`), title line only | Project | AGENTS.md; Dependabot uses the `ci` prefix |
| GitHub Actions pinned to commit SHAs, least-privilege `permissions` | Official (GitHub) | GitHub security hardening guide; Dependabot keeps the pins current |
| No automated KDE Store upload | Project | no supported, documented upload API was found; publish by hand |

## Documents vs. reality

- **KF6 porting guide versus current applets.** The porting guide still
  shows `Plasmoid.configuration` and `PlasmaComponents` patterns that are
  correct. Current first-party applets have moved further, e.g.
  `Kirigami.FormEntry` in the Digital Clock settings. This widget uses the
  older `Kirigami.FormLayout` because it exists in every Plasma 6 release,
  and the minimum version is 6.0.
- **The KDE widget tutorial's id example uses `com.github.*`.** See the
  plugin id row above for why this widget uses `io.github.*` instead.
