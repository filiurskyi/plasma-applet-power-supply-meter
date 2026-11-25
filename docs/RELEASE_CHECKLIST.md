# Release checklist

Releases are made by the maintainer. Agents and scripts never push tags or
publish anything.

## 1. Prepare

- [ ] `main` is green in CI and the working tree is clean
- [ ] Version bumped in `package/metadata.json` (semantic versioning: patch
      for fixes, minor for features, major for breaking setting changes or
      dropped Plasma versions)
- [ ] `CHANGELOG.md`: move "Unreleased" entries under `## [X.Y.Z] - YYYY-MM-DD`
- [ ] `make translations` run; no stale template
- [ ] README requirements and docs/COMPATIBILITY.md state what was actually tested for this
      release; new QML imports or sysfs attributes are listed there

## 2. Technical correctness

- [ ] `make check` passes locally
- [ ] No `console.log` or debug output; no new qmllint suppressions
- [ ] No renamed or retyped `main.xml` keys (or a documented migration)
- [ ] `metadata.json`: Id unchanged, minimum Plasma version still true

## 3. Runtime and manual tests

- [ ] Manual test matrix in [DEVELOPMENT.md](DEVELOPMENT.md) completed; note the
      Plasma version and session types used
- [ ] Upgrade from the previous release keeps settings
- [ ] Idle CPU: no noticeable plasmashell increase with the widget added

## 4. Visual integration and accessibility

- [ ] Breeze light and dark, one third-party theme, custom accent colour
- [ ] Panel sizes, vertical panel, desktop, fractional scaling
- [ ] Keyboard focus visible; screen reader announces name and status
- [ ] Screenshots current (`make screenshots`, see [SCREENSHOTS.md](SCREENSHOTS.md))

## 5. Security and privacy

- [ ] No network access, telemetry or new external commands; or, if one was
      added, it is justified in SECURITY.md and has a fixed argument list
- [ ] No secrets, tokens or personal data in the repository or archive

## 6. Licensing

- [ ] `reuse lint` passes; new third-party files have their licence in `LICENSES/`
- [ ] `metadata.json` License matches `LICENSE` and the SPDX headers

## 7. Package

- [ ] `make package`; `unzip -l dist/*.plasmoid` lists only metadata, QML/JS/XML,
      licence and catalogs
- [ ] `kpackagetool6 --type Plasma/Applet --install dist/*.plasmoid` in a clean
      user account or a sandbox session works

## 8. Publish (maintainer)

- [ ] Commit, then `git tag vX.Y.Z` and push the tag
- [ ] Release workflow: tag matches metadata, checks pass, the GitHub release
      has the `.plasmoid` and `.sha256`
- [ ] KDE Store (https://store.kde.org, category "Plasma 6 Extensions →
      Plasma Widgets"): upload the same `.plasmoid` and update the version,
      changelog and screenshots. The first upload is a manual
      store account step. There is no automated upload.
- [ ] After publishing, add the store link to README
