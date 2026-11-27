# Architecture

`package/` is the `.plasmoid` root. `scripts/package.py` copies it, adds the
licence text and compiled translations
(`po/<lang>.po` → `contents/locale/<lang>/LC_MESSAGES/plasma_applet_<plugin id>.mo`),
and rejects any file not on its allow-list.

## Components

Paths are relative to `package/contents/`.

| File | Responsibility |
|---|---|
| `ui/main.qml` | `PlasmoidItem` root. Owns the state (`watts`, `sources`, `onAc`, `drainStreak`, `drainWatts`) and the data source. Resolves settings and theme into colours and font, formats translated text, sets `Plasmoid.status`, declares the context menu action. |
| `ui/CompactRepresentation.qml` | The gauge. Takes values through properties, emits `expandRequested(bool)`. No `Plasmoid` attached object, so tests create it on its own. |
| `ui/FullRepresentation.qml` | The popup: optional warning line, heading, one line per supply. |
| `ui/configGeneral.qml`, `ui/configAppearance.qml` | Settings pages. `cfg_<key>` properties map one-to-one to `main.xml` entries. |
| `code/supply.js` | `COMMAND` (a fixed `grep` over sysfs), `parse()` → `{online, sources, watts, draining, drainWatts}`, `drainStreak()` (debounce). |
| `config/main.xml`, `config/config.qml` | KConfigXT schema; settings page list. |

## Runtime lifecycle

1. Plasma creates `main.qml` once per widget instance, each with its own
   `Plasmoid.configuration`.
2. The `P5Support.DataSource` ("executable" engine) runs `Supply.COMMAND`
   immediately and then every `intervalSeconds`, asynchronously.
   - `grep -sH .` skips unreadable attributes, so a failing UCSI read shows
     "supply rating not reported" rather than "No external power".
   - At startup the engine may log "Process … already running" once. This
     is harmless.
3. `onNewData` parses the output. `parse()` groups attributes by supply, so
   line order does not matter. `sources` is reassigned only when it changed,
   so the popup and tooltip are not rebuilt on every poll.
4. Plasma creates and destroys the compact and full representations as the
   widget moves between panel, desktop and tray. Keep state in `main.qml`;
   the only exception is the `wasExpanded` press latch.

### Drain warning

- **Condition.** `parse()` sets `draining` when a non-battery supply has
  `online` = 1 and a battery (`type` = `Battery`, `scope` not `Device`,
  which excludes mouse and headset batteries) reports `status` =
  `Discharging`. `Not charging` (charge threshold reached) and `Full` are
  normal on external power and do not count.
- **Power.** `drainWatts` sums the discharging batteries: `|power_now|` (µW)
  if present, otherwise `|current_now × voltage_now|` (µA × µV), otherwise 0,
  in which case the text omits the wattage. Only battery `*_now` values are
  used; the UCSI source reports a meaningless 5 V there.
- **Debounce.** During a PD renegotiation the battery may report
  `Discharging` for one read. `main.qml` counts consecutive draining polls in
  `drainStreak`, capped at `Supply.DRAIN_POLLS` (2), and treats the widget as
  draining when the cap is reached.
- **Text.** While draining, the tooltip, popup and accessible description
  gain a line, whatever the setting.
- **Attention.** With `warnWhenDraining` (default on), the arc also uses
  `Kirigami.Theme.negativeTextColor` (overriding a custom gauge colour) and
  `Plasmoid.status` becomes `NeedsAttentionStatus`, which moves the widget
  out of the tray's hidden area. Otherwise the status is `ActiveStatus`.

### Why polling

Neither Plasma nor UPower exposes the negotiated PD rating:

- UPower's line-power objects only expose `Online`.
- The ksystemstats sensors set the hwmon maximum once and never refresh it.

## Configuration

- `config/main.xml` defines the keys. Plasma stores the values per instance
  in `~/.config/plasma-org.kde.plasma.desktop-appletsrc`.
- QML reads them as `Plasmoid.configuration.<key>`.
- The settings dialog handles Apply, Cancel and Defaults through the pages'
  `cfg_<key>` properties.
- Bounds are set in three places: `<min>`/`<max>` in the schema, `from`/`to`
  on the spin boxes (`tests/test_repository.py` checks they agree), and
  clamping in the gauge.
- Write extra data, cache or runtime files to the XDG directories
  (`$XDG_DATA_HOME`, `$XDG_CACHE_HOME`, `$XDG_RUNTIME_DIR`), never into the
  installed package.

### Changing settings without losing users' values

- **Never rename or retype a released key.** Add a new key instead.
- **Reading an old value.** Read the new key when it differs from its
  default, otherwise fall back to the old key. Plasma keeps unknown keys in
  the config file.
- **One-time conversion.** Do it in `main.qml` in `Component.onCompleted`:
  - only when the new key still has its default value;
  - write the converted value with `Plasmoid.configuration.newKey = …`;
  - mention it in the release notes.
- **Removing a key.** Remove it from `main.xml` only after at least one
  release in which it is unused.

## Native backends

Ship compiled code separately from the `.plasmoid` (a distribution-packaged
QML plugin or a D-Bus service); the `.plasmoid` must stay
architecture-independent. The QML must detect a missing backend and show a
message.
