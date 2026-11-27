# Security policy

Only the latest release receives fixes.

## Reporting a vulnerability

Report privately at
<https://github.com/filiurskyi/plasma-applet-power-supply-meter/security/advisories/new>.
Do not open a public issue.

Include the widget version, the Plasma version and steps to reproduce.
Acknowledgement within 14 days.

## What the widget does

It runs inside `plasmashell` with the user's privileges and executes one
fixed command, which reads world-readable sysfs files:

```sh
grep -sH . /sys/class/power_supply/*/online /sys/class/power_supply/*/voltage_max /sys/class/power_supply/*/voltage_max_design /sys/class/power_supply/*/current_max /sys/class/power_supply/*/type /sys/class/power_supply/*/scope /sys/class/power_supply/*/status /sys/class/power_supply/*/power_now /sys/class/power_supply/*/current_now /sys/class/power_supply/*/voltage_now
```

It writes only its own settings, through Plasma's per-widget configuration.
No network access, telemetry, stored credentials or root.

## Rules for changes

- **External commands:** prefer a native QML or D-Bus API. Otherwise use a
  constant command or a fixed argument list. Never build shell strings from
  settings, file contents or D-Bus data. A value that must be passed is
  validated against a strict pattern and quoted.
- **Network:** only for a feature that needs it, over HTTPS, no tracking,
  opt-in where possible. Document it in README and here.
- **D-Bus:** call only the services needed. Validate replies. Never call
  privileged methods implicitly.
- **Credentials:** never in `main.xml` or any plain config file. Use the
  Secret Service (KWallet) through a native backend.
- **Third-party code:** never download or execute code at runtime. No
  obfuscated or minified code. Record the licence in `LICENSES/` and
  `REUSE.toml`.
