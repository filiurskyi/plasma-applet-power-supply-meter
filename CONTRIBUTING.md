# Contributing

Open an issue before anything bigger than a fix. One topic per pull request.

## Workflow

1. `make doctor`, then install the tools it lists as missing.
2. `make link` once; then edit and `make run` or `make restart-plasma`. See
   [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
3. `make translations` if user-visible strings changed.
4. `make check` before pushing; CI runs the same command.

## Rules

- **APIs:** public Plasma 6, KDE Frameworks 6 and Qt 6 only. Follow
  [docs/CONVENTIONS.md](docs/CONVENTIONS.md).
- **Settings:** never rename or retype an existing `main.xml` key. See
  [Changing settings](docs/ARCHITECTURE.md#changing-settings-without-losing-users-values).
- **Strings:** every user-visible string goes through `i18n*()` with
  placeholders, never concatenation.
- **Accessibility:** interactive items need keyboard access and an
  `Accessible.name`. Use theme colours and units.
- **Performance:** no new timers, polling or logging unless necessary.
- **Security:** follow the rules in [SECURITY.md](SECURITY.md).
- **Tests:** update `tests/` for changed behaviour. State in the pull request
  what you tested manually.
- **Licensing:** contributions are GPL-3.0-or-later. New files need an SPDX
  header; `reuse lint` checks it.
- **Commits:** a [Conventional Commits](https://www.conventionalcommits.org/)
  title only, no body, e.g.
  `fix(popup): grow when content outgrows the remembered size`.

## Translations

Start `po/<lang>.po` with `scripts/translations.sh new <lang>`. Translate by
hand; machine translations are not merged.

## Bugs

Use the issue templates. Report security problems privately, see
[SECURITY.md](SECURITY.md).
