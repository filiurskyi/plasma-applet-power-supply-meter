# Agent rules

Rules for Codex, Claude Code and other coding agents working in this
repository. Details live in `docs/`; this file only lists what you must do.

## Git

- Commit messages are a single title line only. Never add a body,
  description, trailers or `Co-Authored-By` lines.
- The title follows [Conventional Commits](https://www.conventionalcommits.org/):
  `<type>(<optional scope>): <description>`.
  - Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`,
    `chore`, `style`, `revert`.
  - Scope is optional, short and lower-case, naming the area: `gauge`,
    `popup`, `config`, `parser`, `i18n`, `package`, `scripts`, `agents`.
  - Description: lower-case imperative ("add", not "added"), no trailing
    period, whole title at most 72 characters.
  - Breaking changes (renamed setting keys, dropped Plasma versions) use `!`
    after the type or scope, e.g. `feat(config)!: …`.
- Never push. The maintainer pushes manually. This also covers tags,
  branches and force-pushes.

## Never without explicit permission from the maintainer

- Publish releases, upload to the KDE Store or GitHub, or change any external
  service.
- Change the plugin id (`package/metadata.json` `KPlugin.Id`), or rename or
  retype keys in `package/contents/config/main.xml`. Both break existing
  users' settings; see "Changing settings" in `docs/ARCHITECTURE.md`.
- Change the licence or relicense code.
- Add a dependency, a network request, an external command or a native
  (compiled) component.

## How to work

1. **Plasma APIs.** Use public Plasma 6, KDE Frameworks 6 and Qt 6 APIs only.
   Before using an unfamiliar type or property, check that it exists in
   api.kde.org / doc.qt.io or in the installed `plugins.qmltypes`. Do not use
   `org.kde.plasma.private.*`, Plasma 5 APIs or Qt5Compat. The single justified
   exception, Plasma5Support for reading sysfs, is documented in
   `docs/CONVENTIONS.md`.
2. **Simplicity.** Prefer native QML and Plasma behaviour over custom
   JavaScript. Add files, layers or settings only when they solve a real
   problem.
3. **Interfaces.** `CompactRepresentation.qml` and `FullRepresentation.qml`
   take everything through properties and must not use `Plasmoid`, so that
   they stay testable.
4. **Strings and accessibility.** Every user-visible string goes through
   `i18n`, `i18nc`, `i18np` or `i18ncp` with placeholders, never
   concatenation. Interactive items need keyboard access and an
   `Accessible.name`. Use theme colours and units, not hard-coded values.
5. **Continuous running.** This code runs all session long: no new timers,
   polling, logging or work on every poll unless it is necessary.
6. **Behaviour changes.** Update the tests in `tests/`, the docs and the
   "Unreleased" section of `CHANGELOG.md`. Run `make translations` when
   strings change.
7. **Commands.** Never build shell commands from settings or external data
   (see `SECURITY.md`).

## Before saying a task is done

- Run `make check`. If a tool is missing, say which one (`make doctor`) and
  which checks therefore did not run.
- Report results as they are. Never claim a check or test passed unless you
  ran it and saw it pass.
- Never weaken, skip or filter a check to make it pass. That includes
  qmllint filters, `REUSE-Ignore` markers and test assertions. If a check is
  wrong, explain why and ask.
- Changes visible in Plasma also need a run: `make run`, or
  `make screenshots` for a headless session. Say what you verified
  visually and what you did not.

## Map

- **Shipped widget:** `package/`. Only `scripts/package.py` decides what is
  in the `.plasmoid`.
- **Development:** workflow, tools and the manual test matrix are in
  `docs/DEVELOPMENT.md`.
- **Design:** components, lifecycle and settings migration are in
  `docs/ARCHITECTURE.md`.
- **Conventions:** verified rules with sources are in `docs/CONVENTIONS.md`.
- **Compatibility:** distributions, required modules and hardware, with
  sources, are in `docs/COMPATIBILITY.md`. Update it when adding an import
  or a sysfs attribute.
- **Releases:** `docs/RELEASE_CHECKLIST.md`; KDE Store page text in
  `docs/STORE_LISTING.md`.
- **Screenshots:** `docs/SCREENSHOTS.md`.
