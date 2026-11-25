# Changelog

All notable changes are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Chromebook chargers (`cros-usbpd-charger`): the rating is read from
  `voltage_max_design` when `voltage_max` is missing (untested on hardware).
- When the hardware reports no rating, the tooltip and popup explain why no
  wattage is shown.
- Warning when the battery discharges while an external supply is online
  (for example a charger that negotiated too little under heavy load): the
  arc turns the theme's negative colour, the tooltip and popup show the
  discharge power, and the widget requests attention so it leaves the
  system tray's hidden area. Shown after two consecutive polls; `Not charging`
  and `Full` (charge thresholds) never warn. New setting "Warn when the
  battery drains while plugged in" (on by default) controls the colour and
  attention request.

## [1.0.0] - Unreleased

First public release.

### Added

- Circular panel gauge of the power the connected supply can deliver
  (negotiated USB-C PD contract, `voltage_max × current_max` from sysfs).
- Tooltip and popup listing every rated supply.
- Settings: full-scale wattage, update interval, label font, gauge, track and
  text colours, label outline.
- "Show Energy Information…" context menu action.
- Keyboard activation, accessible name and description, focus indicator.
- Translation template; packaged catalogs are loaded from the `.plasmoid`.

### Changed (compared with the private pre-release)

- Plugin id is now `io.github.filiurskyi.powersupplymeter`; the old
  `org.kde.plasma.*` id is reserved for KDE. Settings of the pre-release do
  not carry over.
- Licence is GPL-3.0-or-later (was GPL-2.0-or-later).
- With several supplies online the gauge shows the best one instead of the
  sum, since a laptop draws from one source at a time.
- Update interval is configured in seconds (minimum 1 s, the engine's limit).
- A supply whose rating cannot be read now counts as external power instead
  of "No external power".
