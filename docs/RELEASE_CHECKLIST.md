# Release checklist

Only the maintainer releases. Agents and scripts never push tags or publish.

## 1. Prepare

- [ ] `main` is green in CI; working tree clean
- [ ] Version bumped in `package/metadata.json`: patch for fixes, minor for
      features, major for breaking setting changes or dropped Plasma versions
- [ ] `metadata.json`: Id unchanged, minimum Plasma version still true
- [ ] No renamed or retyped `main.xml` keys, or a documented migration
- [ ] No `console.log` or debug output; no new qmllint suppressions
- [ ] No network access, telemetry or new external command; if one was
      added, SECURITY.md justifies it and its argument list is fixed
- [ ] No secrets, tokens or personal data in the repository or archive
- [ ] [COMPATIBILITY.md](COMPATIBILITY.md) states what
      was tested for this release and list new QML imports and sysfs attributes

## 2. Test

- [ ] `make check` passes
- [ ] `make smoke` passes; screenshots in `build/smoke/` reviewed
- [ ] [Manual test matrix](DEVELOPMENT.md#manual-test-matrix) completed
- [ ] Idle CPU: no noticeable plasmashell increase with the widget added
      ([Profiling](DEVELOPMENT.md#profiling))
- [ ] Screenshots current ([SCREENSHOTS.md](SCREENSHOTS.md))

## 3. Publish

- [ ] Commit, `git tag vX.Y.Z`, push the tag
- [ ] The release workflow checks the tag against `metadata.json`, runs CI
      and creates the GitHub release with the `.plasmoid` and `.sha256`.
      Edit its generated notes
- [ ] KDE Store (https://store.kde.org/p/2382745), manual: upload the
      `.plasmoid` from the GitHub release (the MD5 on the Files tab must
      match), set the file version, update the product version, changelog
      and screenshots. Page text: [STORE_LISTING.md](STORE_LISTING.md)
- [ ] New uploads can take up to 24 hours to appear in Plasma's "Get New…"
      dialog (sort by Release Date)
