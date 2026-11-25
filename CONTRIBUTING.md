# Contributing

Thanks for helping. This is a small, single-maintainer project, so the
process is light.

## Before you start

- For anything bigger than a fix, open an issue first so we can agree on the
  approach.
- Keep changes focused: one topic per pull request.

## Workflow

1. Run `make doctor` and install the missing development tools it lists.
2. Run `make link` once, then edit and use `make run` or `make restart-plasma`.
   [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) has the details.
3. If you change user-visible strings, run `make translations`.
4. Before pushing, run `make check`; CI runs the same command.
5. Add an entry under "Unreleased" in `CHANGELOG.md`.
6. Write commit titles in [Conventional Commits](https://www.conventionalcommits.org/)
   style, e.g. `fix(popup): grow when content outgrows the remembered size`.

## Expectations

- **Plasma conventions:** follow the KDE and Qt conventions in
  [docs/CONVENTIONS.md](docs/CONVENTIONS.md). Use public Plasma 6 APIs only.
- **Settings compatibility:** never rename or retype an existing `main.xml`
  key. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) explains how to migrate
  settings.
- **Strings and accessibility:** every visible string is translatable, and
  interactive elements stay reachable by keyboard and have accessible names.
- **Performance:** the widget runs all session long. No new timers, polling
  or logging without a reason.
- **Tests:** add or update tests for changed behaviour, and describe in the
  pull request what you tested manually.
- **Licensing:** contributions are licensed GPL-3.0-or-later. New files need
  an SPDX header; `reuse lint` checks this.

## Translations

Translations are welcome as `po/<lang>.po` files; start one with
`scripts/translations.sh new <lang>`. Please translate by hand; machine
translations will not be merged.

## Reporting bugs

Use the issue templates. For security problems see [SECURITY.md](SECURITY.md).
