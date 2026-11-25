# Security policy

## Supported versions

Only the latest release receives fixes.

## Reporting a vulnerability

Please report privately through GitHub:
**Security → Report a vulnerability** on
<https://github.com/filiurskyi/plasma-applet-power-supply-meter/security/advisories/new>.
Do not open a public issue.

Include the widget version, Plasma version, and steps to reproduce. You can
expect an acknowledgement within 14 days. This is a one-person project, so
there is no fixed timeline for fixes; you will be kept informed and credited
unless you prefer not to be.

## What the widget does

The widget runs inside `plasmashell` with your user's privileges.

- **It runs one fixed command:**
  `grep -sH . /sys/class/power_supply/*/online …/voltage_max …/voltage_max_design …/current_max
  …/type …/scope …/status …/power_now …/current_now …/voltage_now`
  (each `…` is `/sys/class/power_supply/*`).
  - No user input or setting is ever put into a command line.
  - It only reads world-readable sysfs files.
- **It does not access the network**, collect telemetry, or store credentials.
- **It writes only its own settings,** through Plasma's per-widget
  configuration.
- **It never needs root** and does not install anything at runtime.

## Rules for future changes

- **External commands:** use a constant command or a fixed argument list.
  Never build shell strings from settings, file contents or D-Bus data. If a
  value must be passed, validate it against a strict pattern and quote it.
  Prefer a native QML or D-Bus API over spawning processes.
- **Network:** add it only for a feature that needs it, over HTTPS, with no
  tracking. Document it in README and here, and make it opt-in where
  possible.
- **D-Bus:** call only the services you need. Validate replies before using
  them, and never call privileged methods implicitly.
- **Credentials:** never store them in `main.xml` or any plain config file.
  Use the Secret Service (KWallet) through a native backend.
- **Code from elsewhere:** do not download or execute code at runtime. Do not
  vendor obfuscated or minified code. Third-party files need a compatible
  licence recorded in `LICENSES/` and `REUSE.toml`.
