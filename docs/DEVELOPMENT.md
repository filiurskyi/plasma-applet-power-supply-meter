# Development

## Tools

`make doctor` lists what is installed and prints install commands for
missing tools. Nothing is ever installed automatically.

| Task | Needs |
|---|---|
| install, package | `kpackagetool6`, `python3` (+ `msgfmt` once `po/*.po` exist) |
| run in a window | `plasmoidviewer` (plasma-sdk) or `plasmawindowed` |
| `make check` | `qmllint`, `qmlformat`, `qmltestrunner` (+ QtTest QML module), `xmllint`, `shellcheck`, `reuse`, gettext |
| `make screenshots` | `kwin_wayland`, `plasmashell`, `spectacle`, `qdbus6`, `dbus-run-session`, `lookandfeeltool` |

Qt tools are found on `PATH` under their plain name, with a `6` or `-qt6`
suffix, or in `qtpaths6 --query QT_HOST_BINS` and `/usr/lib/qt6/bin`.
Set `QT_BIN=/path` to override.

On Kubuntu 26.04:

```sh
sudo apt install plasma-sdk qt6-declarative-dev-tools qml6-module-qttest gettext libxml2-utils shellcheck reuse
```

## Everyday loop

```sh
make link            # once: symlink package/ into ~/.local/share/plasma/plasmoids/<id>
# edit QML ...
make run             # plasmoidviewer on package/ (fast; no panel)
make restart-plasma  # reload the copy that lives in your real panel
```

`plasmoidviewer` options worth knowing:
- `plasmoidviewer -a package -f horizontal`, or `-f vertical`, shows the
  panel form factors;
- `-l bottomedge` sets the panel location;
- `-s 400x300` sets the window size.

Use `make install` or `make upgrade` instead of `make link` to test exactly
what ships, compiled translations included.

## Debugging

- **Plasma's log:** `journalctl --user -f -g powersupplymeter`.
  `plasmoidviewer` prints QML warnings to the terminal.
- **QML errors after editing:** run `make lint` first. It catches most
  typos, unknown properties and broken imports before Plasma loads anything.
- **Settings not saving:** check that the page's `cfg_<key>` name matches
  `main.xml`. The `ConfigurationTest` tests check this.
- **Leftover logging:** don't leave `console.log` in shipped code.

## Profiling

- **CPU at idle:** `pidstat -p $(pgrep -x plasmashell) 5` with and without
  the widget. Each poll spawns one short-lived `grep`; set the interval to 1 s
  to see it in `top` or with `perf trace -s`.
- **QML:** run `QSG_RENDER_TIMING=1 plasmoidviewer -a package` for scene
  graph timings. Alternatively, start it with
  `-qmljsdebugger=port:3768,block` and attach the QML Profiler from Qt
  Creator to see binding and JavaScript costs.
- **Memory:** use `heaptrack plasmoidviewer -a package` and compare against
  an empty `plasmoidviewer` run.

Do not quote performance numbers in docs unless you measured them on stated
hardware.

## Tests

| Layer | What | How |
|---|---|---|
| Static | QML lint and format, kcfg XML, metadata JSON, shellcheck, REUSE, translation template up to date | `make lint format-check translations-check reuse` |
| Automated | metadata and schema consistency, settings pages against schema, package contents, reproducibility, tag check, `init.py` | `python3 -m unittest discover -s tests -v` |
| Automated (QML) | sysfs parser; gauge clamping, click and keyboard toggling, panel sizing, accessibility | `qmltestrunner -input tests/qml` (offscreen) |
| Runtime smoke | widget loads in a real plasmashell, popup opens | `make screenshots` and look at the images; logs stay in the sandbox with `KEEP_SANDBOX=1` |
| Manual | see the matrix below | |

### Manual test matrix

Run before each release and note the Plasma version and session type used.

- [ ] Fresh install from the `.plasmoid`, add to panel, remove, uninstall
- [ ] Upgrade from the previous release keeps settings
- [ ] `make restart-plasma`: widget comes back with its settings
- [ ] Horizontal panel at 24, 36 and 64 px; vertical panel
- [ ] On the desktop: gauge scales with the widget size, popup opens
- [ ] Breeze light, Breeze dark, one third-party Plasma theme, a custom accent colour
- [ ] Fractional scaling (125 % or 150 %): ring and label are crisp, not clipped
- [ ] Two instances with different full scale and colours stay independent
- [ ] Settings: Apply, Cancel, Defaults, reopen; custom font survives reopening
- [ ] Keyboard: Tab to the gauge, focus ring visible, Space or Enter toggles the popup
- [ ] Screen reader (Orca) announces name and status
- [ ] Unplug the charger: "—", tooltip "No external power"; plug back in: value returns
- [ ] Charger that does not report a rating: "rating not reported"
- [ ] Heavy load on a weak charger (battery `Discharging` while plugged in):
      after two polls the arc turns red, tooltip and popup show the drain line,
      a widget in the tray's hidden area moves out; with the setting off only
      the line shows. At a charge threshold (`Not charging`) nothing warns
- [ ] Wayland and X11 sessions
- [ ] Right-to-left language (e.g. `LANGUAGE=ar plasmoidviewer -a package`): layout mirrors sensibly

## Translations

```sh
make translations                  # regenerate po/*.pot, merge into po/*.po
scripts/translations.sh new uk     # start a Ukrainian catalog
make translations-check            # template current, catalogs valid
```

Translators edit `po/<lang>.po` with any PO editor (Lokalize, Poedit).
`make package` compiles the catalogs into the archive.

To check a translation, `make install` and then run
`LANGUAGE=uk plasmawindowed io.github.filiurskyi.powersupplymeter`.

Do not add machine-generated translations.

## Packaging

`make package` writes `dist/power-supply-meter-<version>.plasmoid` and a
`.sha256` file.
- The archive is a zip with `metadata.json` at its root.
- Entries are sorted, permissions fixed and timestamps set to the last
  commit time, so rebuilding the same commit gives identical bytes.
- `python3 scripts/package.py verify FILE` checks any archive against the
  allow-list.

## Releasing

See [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
