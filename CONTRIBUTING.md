# Contributing

Open an issue before anything bigger than a fix. One topic per pull request.

## Workflow

Set up and test as in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). Before
pushing, run `make translations` if user-visible strings changed, then
`make check`.

## Rules

- **APIs and style:** public Plasma 6, KDE Frameworks 6 and Qt 6 only.
  Follow [docs/CONVENTIONS.md](docs/CONVENTIONS.md), including its i18n and
  theme rules.
- **Settings:** never rename or retype an existing `main.xml` key. See
  [Changing settings](docs/ARCHITECTURE.md#changing-settings-without-losing-users-values).
- **Accessibility:** interactive items need keyboard access and an
  `Accessible.name`.
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
