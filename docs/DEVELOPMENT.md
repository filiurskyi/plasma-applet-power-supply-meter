# Development

## Tools

`make doctor` lists installed tools and prints install commands for missing
ones.

| Task | Needs |
|---|---|
| install, package | `kpackagetool6`, `python3`, `msgfmt` if `po/*.po` exist |
| `make run` | `plasmoidviewer` (plasma-sdk), else `plasmawindowed` with the installed copy |
| `make check` | `qmllint`, `qmlformat`, `qmltestrunner` (+ QtTest QML module), `xmllint`, `shellcheck`, `reuse`, gettext |
| `make smoke`, `make screenshots` | `kwin_wayland`, `plasmashell`, `spectacle`, `qdbus6`, `dbus-run-session`, `lookandfeeltool`; optional `kscreen-doctor` (150 % shot), Python PIL (close-ups) |

Qt tools are looked up on `PATH` as `<tool>`, `<tool>6` or `<tool>-qt6`,
then in `$QT_BIN`, the `qtpaths6` host directories and `/usr/lib/qt6/bin`.

## Everyday loop

```sh
make link            # once: symlink package/ into ~/.local/share/plasma/plasmoids/<id>
make run             # plasmoidviewer on package/
make restart-plasma  # reload the copy in your real panel
```

| `plasmoidviewer -a package` option | Effect |
|---|---|
| `-f horizontal`, `-f vertical` | panel form factor |
| `-l bottomedge` | panel location |
| `-s 400x300` | window size |

`make link` runs without compiled translations; `make install` or
`make upgrade` installs what ships.

## Debugging

- Log: `journalctl --user -f -g powersupplymeter`; `plasmoidviewer` logs to
  the terminal.
- QML errors: `make lint`.
- Settings not saving: the page's `cfg_<key>` must match `main.xml`
  (`ConfigurationTest`).

## Profiling

- CPU at idle: `pidstat -p $(pgrep -x plasmashell) 5` with and without the
  widget. Each poll spawns one `grep`; at a 1 s interval it shows in `top` or
  `perf trace -s`.
- Scene graph timings: `QSG_RENDER_TIMING=1 plasmoidviewer -a package`.
- Binding and JavaScript costs: start with
  `-qmljsdebugger=port:3768,block` and attach Qt Creator's QML Profiler.
- Memory: `heaptrack plasmoidviewer -a package` against an empty
  `plasmoidviewer`.

Quote performance numbers in docs only with the hardware they were measured
on.

## Tests

| Layer | Covers | Command |
|---|---|---|
| Static | QML lint and format, kcfg XML, metadata JSON, shellcheck, REUSE, translation template | `make lint format-check translations-check reuse` |
| Python | metadata, settings pages against the schema, package contents and reproducibility, tag check, `init.py` | `make test` |
| QML | sysfs parser; gauge clamping, click and keyboard toggling, panel sizing, warning colour, accessibility | `make test` (offscreen) |
| Smoke | the `.plasmoid` in a headless plasmashell: 24 and 64 px panels, two instances with different settings, vertical panel, desktop, 150 % scaling if the virtual output allows it | `make smoke` |
| Manual | matrix below | |

`make check` (what CI runs) is the first three layers plus `make package`.

`make smoke`:

- Installs `dist/*-<version>.plasmoid`, built only if missing: run
  `make package` first after edits.
- Fails on any plasmashell log line naming the widget.
- Writes screenshots and `plasmashell.log` to `build/smoke/`. Review the
  screenshots; `scale-150-skipped.txt` means scaling was not tested.

### Manual test matrix

Run before each release. Note the Plasma version and session type.
*(smoke)*: review the `make smoke` screenshot instead.

- [ ] Fresh install from the `.plasmoid`, add to panel, remove, uninstall
- [ ] Upgrade from the previous release keeps settings
- [ ] `make restart-plasma`: widget returns with its settings
- [ ] Horizontal panel at 24 and 64 px *(smoke)* and 36 px; vertical panel *(smoke)*
- [ ] Desktop: gauge scales with the widget size *(smoke)*, popup opens
- [ ] Breeze light, Breeze dark, one third-party Plasma theme, a custom accent colour
- [ ] Fractional scaling (125 % or 150 %): ring and label crisp, not clipped
- [ ] Two instances with different full scale and colours stay independent *(smoke)*
- [ ] Settings: Apply, Cancel, Defaults, reopen; custom font survives reopening
- [ ] Keyboard: Tab to the gauge, focus ring visible, Space or Enter toggles the popup
- [ ] Screen reader (Orca) announces name and status
- [ ] Unplug the charger: "—", tooltip "No external power"; plug in: value returns
- [ ] Charger without a reported rating: "rating not reported"
- [ ] Battery `Discharging` while plugged in (heavy load, weak charger):
      after two polls the arc turns red, tooltip and popup show the drain
      line, a widget in the tray's hidden area moves out. With the setting
      off, only the line shows. `Not charging` (charge threshold): no warning
- [ ] Wayland and X11 sessions
- [ ] Right-to-left language (`LANGUAGE=ar plasmoidviewer -a package`): layout mirrors

## Translations

```sh
make translations                  # regenerate po/*.pot, merge into po/*.po
scripts/translations.sh new uk     # start po/uk.po
make translations-check            # template current, catalogs valid
```

To check a translation: `make install`, then
`LANGUAGE=uk plasmawindowed io.github.filiurskyi.powersupplymeter`.

## Packaging

`make package` writes `dist/power-supply-meter-<version>.plasmoid` and
`.plasmoid.sha256`, with `po/*.po` compiled in. The same commit always gives
identical bytes. `python3 scripts/package.py verify FILE` checks any archive
against the allow-list.

## Releasing

See [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
