# Changelog

All notable changes are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-11-25

First public release.

### Added

- Circular panel gauge of the power the connected charger can deliver: the
  negotiated USB-C PD contract, `voltage_max × current_max` from sysfs.
- Warning when the battery discharges while a charger is connected, for
  example a charger that negotiated too little under heavy load:
  - the ring turns the theme's warning colour;
  - the tooltip and popup show the discharge power;
  - the widget asks for attention, so it leaves the system tray's hidden area.

  It shows after two consecutive polls. `Not charging` and `Full` (charge
  thresholds) never trigger it, and peripheral batteries such as mice and
  headsets are ignored.
- Tooltip and popup listing every rated supply. When the hardware reports no
  rating, they explain why no wattage is shown.
- Chromebook chargers (`cros-usbpd-charger`): the rating is read from
  `voltage_max_design` when `voltage_max` is missing (untested on hardware).
- Settings:
  - full-scale wattage and update interval;
  - the drain warning (on by default);
  - label font;
  - gauge, track and text colours;
  - label outline.
- "Show Energy Information…" context menu action.
- Keyboard activation, accessible name and description, and a focus indicator.
- Translation template; translations are loaded from the `.plasmoid`.

### Changed (compared with the private pre-release)

- The plugin id is now `io.github.filiurskyi.powersupplymeter`, because the
  old `org.kde.plasma.*` id is reserved for KDE. Pre-release settings do not
  carry over.
- The licence is now GPL-3.0-or-later (was GPL-2.0-or-later).
- With several chargers online, the gauge shows the best one instead of the
  sum, since a laptop draws from one source at a time.
- The update interval is set in seconds; the minimum is 1 s, the engine's
  limit.
- A charger whose rating cannot be read now counts as external power instead
  of "No external power".
- The gauge label scales with the gauge, so it fills a large gauge on the
  desktop.
- The popup fits its content. If a remembered popup size is too short for the
  content, the popup grows.
