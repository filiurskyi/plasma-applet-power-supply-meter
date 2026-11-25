# Screenshots

Screenshots are taken in a throwaway, headless Plasma session, so your real
desktop, its windows and its settings are never captured or changed.

```sh
make screenshots                                   # Breeze light + dark into screenshots/
THEMES=org.kde.breezedark.desktop scripts/screenshots.sh /tmp/shots
SIZE=1920x1080 PANEL_HEIGHT=56 make screenshots
```

## How it works

1. `scripts/screenshots.sh` creates a temporary directory and points
   `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME` and `XDG_STATE_HOME`
   into it. It then installs the widget there with `kpackagetool6`.
2. `dbus-run-session` starts a private session bus. In it,
   `kwin_wayland --virtual` starts a compositor that renders into memory,
   not to a screen.
3. Inside that session, `scripts/screenshots-session.sh`:
   1. applies the look-and-feel theme;
   2. starts `plasmashell`, which creates its default panel;
   3. adds the widget to the panel through the Plasma scripting D-Bus API;
   4. takes `<theme>-panel.png` with `spectacle --background --fullscreen`;
   5. opens the popup through the widget's global shortcut (via
      kglobalaccel's D-Bus `invokeShortcut`), then takes `<theme>-popup.png`.
4. Afterwards the script stops the daemons D-Bus started inside the sandbox
   (portal, ksecretd, activity manager) and deletes the directory. Set
   `KEEP_SANDBOX=1` to keep it. `state/plasmashell.log` then has the QML
   warnings from the run, which makes this a useful runtime smoke test too.

The values shown are read from **this machine's** sysfs, so plug in the
charger you want to show.

## Manual shots

The settings dialog cannot be opened in the headless session: Plasma's
scripting `showConfigurationInterface()` does nothing there. Take it on your
own desktop:

1. Right-click the widget, then **Configure Power Supply Meter…**
2. With the dialog focused, press <kbd>Meta</kbd>+<kbd>Print</kbd> (Spectacle,
   active window), or run `spectacle --activewindow --background --delay 3000
   --output screenshots/settings-general.png` and focus the dialog within 3 s.

`spectacle --activewindow` captures whatever window has focus. Check every
image before committing it, so no unrelated windows or personal data end up
in the repository.

## For the KDE Store

- Use PNG, at least one image showing the gauge at a readable size: crop the
  panel shot or use a larger `PANEL_HEIGHT`.
- Show light and dark themes, the popup, and the settings page.
- Commit the final images to `screenshots/` and reference them from README.
