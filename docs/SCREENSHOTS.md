# Screenshots

`make screenshots` runs in a throwaway, headless Plasma session.

```sh
make screenshots                                   # Breeze light + dark into screenshots/
THEMES=org.kde.breezedark.desktop scripts/screenshots.sh /tmp/shots
SIZE=1920x1080 PANEL_HEIGHT=56 make screenshots
```

| Variable | Default | |
|---|---|---|
| `THEMES` | `org.kde.breeze.desktop org.kde.breezedark.desktop` | look-and-feel themes, space-separated |
| `SIZE` | `1280x800` | virtual screen |
| `PANEL_HEIGHT` | `44` | |
| `PACKAGE` | `package/` | directory or `.plasmoid` to install |
| `KEEP_SANDBOX` | unset | `1` keeps the temporary directory; plasmashell's log is `state/plasmashell.log` in it |

Output per theme (`breeze`, `breezedark`):

| File | Shows |
|---|---|
| `<theme>-panel.png` | full desktop |
| `<theme>-popup.png` | full desktop, popup open |
| `<theme>-closeup.png` | bottom-right 600×200 crop of the popup shot; needs Python PIL |

Values come from this machine's sysfs: plug in the charger you want to show.

## Settings dialog

Not captured by `make screenshots`: it cannot be opened in the headless
session. Take it on your own desktop:

1. Right-click the widget, **Configure Power Supply Meter…**
2. With the dialog focused, press <kbd>Meta</kbd>+<kbd>Print</kbd>, or run
   the command below and focus the dialog within 3 s.

```sh
spectacle --activewindow --background --delay 3000 --output screenshots/breezedark-settings.png
```

`--activewindow` captures whichever window has focus. Check every image for
unrelated windows and personal data before committing.
