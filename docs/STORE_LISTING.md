# KDE Store listing

Text for the product page, <https://store.kde.org/p/2382745> (edit it from
opendesktop.org, account `flrsk`). Keep it in sync with README when features
change.

**Name:** Power Supply Meter

**Category:** Plasma 6 Monitoring (under Plasma 6 Extensions)

**License:** GPL-3.0-or-later (the store's closest option is "GPLv3"; the
description states "or later")

**Source:** https://github.com/filiurskyi/plasma-applet-power-supply-meter

**Summary (one line):** Shows the wattage your charger can deliver and warns
when the battery drains while plugged in.

## Description

A small gauge for your panel that shows how much power your charger can
actually deliver: the negotiated USB-C Power Delivery contract, not how much
the laptop is using.

A flaky dock or cable can make a 130 W charger negotiate far less. Under
heavy load the laptop then drains its battery while plugged in. This widget
makes that visible:

- the gauge shows the negotiated wattage at a glance;
- the ring turns red when the battery discharges while plugged in, and the
  widget leaves the system tray's hidden area;
- the tooltip and popup list each charger's voltage, current and wattage, and
  the discharge power.

Configurable full scale (65 W, 100 W, …), update interval, font and colours;
it follows your Plasma theme by default. No network access, no telemetry, no
root.

**Requirements:** Plasma 6.0 or later. The wattage needs hardware that
reports the charger's rating to Linux; most modern laptops do, via the UCSI
driver. Check with:
`grep -sH . /sys/class/power_supply/*/{voltage_max,current_max}`.
Details: https://github.com/filiurskyi/plasma-applet-power-supply-meter/blob/main/docs/COMPATIBILITY.md

## Screenshots to upload

1. `screenshots/breezedark-closeup.png`
2. `screenshots/breeze-closeup.png`
3. `screenshots/breezedark-settings.png`
4. `screenshots/breezedark-panel.png` (full desktop)

## Changelog field

Paste the matching section of CHANGELOG.md.
