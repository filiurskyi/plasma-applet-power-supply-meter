# Power Supply Meter

A KDE Plasma 6 panel gauge showing how much power the connected charger can
deliver: the negotiated USB-C Power Delivery contract
(`voltage_max × current_max`), not what the laptop draws.

A flaky dock or cable can make a 130 W charger negotiate 60 W. Under load the
laptop then drains its battery while plugged in.

| Breeze Dark | Breeze |
|---|---|
| ![Gauge and popup in a dark panel](screenshots/breezedark-closeup.png) | ![Gauge and popup in a light panel](screenshots/breeze-closeup.png) |

<details>
<summary>Settings</summary>

![The General settings page](screenshots/breezedark-settings.png)

</details>

<!-- Regenerate with `make screenshots`; see docs/SCREENSHOTS.md. -->

## Features

- Circular gauge in horizontal and vertical panels or on the desktop.
- Tooltip and popup with each supply's voltage, current and wattage.
- Gauge turns red when the battery drains while plugged in.
- Follows the Plasma theme; font and colours can be overridden.
- Keyboard and screen-reader accessible.
- No network access, no telemetry, no root.

## Requirements

- KDE Plasma 6.0 or later.
- A `power_supply` that reports `online`, `voltage_max` and `current_max`:

  ```sh
  grep -sH . /sys/class/power_supply/*/{online,voltage_max,current_max}
  ```

  Without `voltage_max` and `current_max` the widget shows only that external
  power is connected; the drain warning still works.
- `kinfocenter`, optional, for the "Show Energy Information…" action.

QML modules, packages, distributions and hardware:
[docs/COMPATIBILITY.md](docs/COMPATIBILITY.md). If the panel shows an error
instead of the gauge, see
[its fix list](docs/COMPATIBILITY.md#if-the-widget-shows-an-error-instead-of-the-gauge).

## Installation

**KDE Store:** right-click the panel → **Add or Manage Widgets…** →
**Get New…** → **Download New Plasma Widgets**, search for "Power Supply
Meter". [Store page](https://store.kde.org/p/2382745).

**Manually:** download `power-supply-meter-<version>.plasmoid` (and its
`.sha256`) from the
[releases](https://github.com/filiurskyi/plasma-applet-power-supply-meter/releases):

```sh
kpackagetool6 --type Plasma/Applet --install power-supply-meter-<version>.plasmoid
# later versions:
kpackagetool6 --type Plasma/Applet --upgrade power-supply-meter-<version>.plasmoid
```

It installs into `~/.local/share/plasma/plasmoids/`.

## Configuration

Right-click the widget → **Configure Power Supply Meter…** Settings are per
widget instance.

| Setting | Default | Range |
|---|---|---|
| Full scale (your charger's rating) | 130 W | 1–500 W |
| Update interval | 2 s | 1–60 s |
| Warn when the battery drains while plugged in | on | |
| Font | system | |
| Gauge, track and text colours | theme | |
| Label outline | on | |

With the warning off, the tooltip and popup still report the drain; the gauge
colour and tray visibility stay unchanged.

## Known limitations

- The drain warning needs the battery to report `Discharging` and appears
  after two consecutive polls. Discharge power needs `power_now`, or
  `current_now` and `voltage_now`.
- Each poll spawns a short `grep` process
  ([why](docs/ARCHITECTURE.md#why-polling)).

## Development

[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md),
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md),
[CONTRIBUTING.md](CONTRIBUTING.md). To start a new widget from this
repository, run `make init` in a fresh copy.

## License

GPL-3.0-or-later, see [LICENSE](LICENSE). Copyright © 2026 Andrii Filiurskyi.
