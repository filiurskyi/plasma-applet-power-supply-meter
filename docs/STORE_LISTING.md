# KDE Store listing

Text for <https://store.kde.org/p/2382745>, edited from opendesktop.org,
account `flrsk`.

| Field | Value |
|---|---|
| Name | Power Supply Meter |
| Category | Plasma 6 Monitoring (under Plasma 6 Extensions) |
| License | GPLv3 (the store has no "or later" option) |
| Source | https://github.com/filiurskyi/plasma-applet-power-supply-meter |
| Summary | Shows the wattage your charger can deliver and warns when the battery drains while plugged in. |
| Changelog | the GitHub release notes |

## Description

A small gauge for your panel that shows how much power your charger can
deliver: the negotiated USB-C Power Delivery contract, not how much the
laptop is using.

A flaky dock or cable can make a 130 W charger negotiate far less. Under
heavy load the laptop then drains its battery while plugged in.

- The gauge shows the negotiated wattage.
- The ring turns red when the battery discharges while plugged in, and the
  widget leaves the system tray's hidden area.
- The tooltip and popup list each charger's voltage, current and wattage, and
  the discharge power.

Configurable full scale (65 W, 100 W, …), update interval, font and colours;
follows your Plasma theme by default. No network access, no telemetry, no
root. Licensed GPL-3.0-or-later.

**Requirements:** Plasma 6.0 or later, and hardware that reports the
charger's rating to Linux. Check with:
`grep -sH . /sys/class/power_supply/*/{voltage_max,current_max}`.
Details: https://github.com/filiurskyi/plasma-applet-power-supply-meter/blob/main/docs/COMPATIBILITY.md

## Screenshots

1. `screenshots/breezedark-closeup.png`
2. `screenshots/breeze-closeup.png`
3. `screenshots/breezedark-settings.png`
4. `screenshots/breezedark-panel.png` (full desktop)
