# Compatibility

The widget is distribution-agnostic: it is a QML package with no compiled
code. Whether it works on a given machine depends on three layers.

| Layer | Needed | Varies by |
|---|---|---|
| Plasma and Qt | Plasma 6.0+ and its standard QML modules | distribution release |
| Userland | `/bin/sh` and a `grep` with `-s` and `-H` | nothing: GNU, BusyBox and Toybox grep all have both |
| Kernel and hardware | a `power_supply` with `voltage_max` and `current_max` | laptop firmware and kernel configuration |

**Tested:** only Plasma 6.6.7 with Qt 6.10 on Kubuntu 26.04 (Wayland,
UCSI laptop). Everything else below comes from package dependencies and
kernel configs, researched on 2026-11-25. Entries marked *unverified* could
not be confirmed from a primary source.

## What the widget uses

| Need | Ubuntu/Debian package | Used for |
|---|---|---|
| Qt Quick, Layouts, Controls | `qml6-module-qtquick*` | everything |
| `Qt.labs.platform` | `qml6-module-qt-labs-platform` | font dialog in settings |
| `org.kde.kirigami` | `qml6-module-org-kde-kirigami` | theme, units, settings layout |
| `org.kde.kcmutils` | `qml6-module-org-kde-kcmutils` | settings pages, Info Center action |
| `org.kde.kquickcontrols` (KDeclarative) | `qml6-module-org-kde-kquickcontrols` | colour buttons |
| `org.kde.quickcharts` (+ `.controls`) | `qml6-module-org-kde-quickcharts` | the gauge |
| `org.kde.plasma.plasma5support` + "executable" engine | `qml6-module-org-kde-plasma-plasma5support` → `libplasma5support6` | runs the sysfs `grep` |
| `org.kde.plasma.{plasmoid,core,components,configuration}` | `plasma-desktoptheme` (libplasma) | Plasma integration |
| `kcm_energyinfo` (optional) | `kinfocenter` | "Show Energy Information…" action |

The command reads these sysfs attributes of every
`/sys/class/power_supply/*` entry: `online`, `voltage_max`, `voltage_max_design`,
`current_max`, `type`, `scope`, `status`, `power_now`, `current_now`, `voltage_now`.
Missing attributes are skipped.

About the font dialog: `Qt.labs.platform.FontDialog` has no Plasma-native
implementation, so Qt falls back to the Qt Widgets `QFontDialog`. That works
because plasmashell is a `QApplication`, so the dialog behaves the same on
every distribution.

## Distributions

On every distribution below that has Plasma 6, the standard desktop install
pulls in all the modules above. For example, KQuickCharts comes in through
`plasma-workspace` and Plasma5Support through `plasma-desktop` or
`plasma-workspace`.

| Distribution | Plasma | Works out of the box | Evidence |
|---|---|---|---|
| Kubuntu 26.04 | 6.6.7 | yes (**tested**) | `plasma-workspace` Depends on quickcharts, kquickcontrols, kcmutils, plasma5support; `plasma-desktop` Depends on qt-labs-platform |
| Kubuntu 25.10 | 6.4.5 | yes | same packaging (Launchpad) |
| Kubuntu 24.04 LTS | 5.27.12 | **no**: Plasma 5; the backports PPA has Plasma 6 only for 25.10 and 26.04 | Launchpad |
| KDE neon (24.04 base) | 6.8.x | yes | archive.neon.kde.org package dependencies |
| Debian 13 trixie | 6.3.6 | yes | packages.debian.org: `kde-plasma-desktop` → `plasma-workspace`, `plasma-desktop` |
| Debian 12 | 5.27 | **no** (Plasma 5), *unverified* | |
| Fedora KDE Plasma Desktop 43–45 | 6.8.x | yes | `plasma-workspace.spec` `Requires: kf6-kquickcharts`; `plasma-desktop` `Requires: qt6qml(org.kde.plasma.plasma5support)` |
| Fedora Kinoite | 6.8.x | yes | atomic-desktops `kinoite.yaml` includes plasma-desktop, plasma-workspace, kinfocenter |
| Bazzite | Kinoite base | yes, *unverified* (inherits Kinoite) | |
| openSUSE Tumbleweed | 6.8.x | yes | `plasma6-workspace` `Requires: kf6-kquickcharts` plus automatic `qt6qmlimport()` requires; `plasma6-desktop` `Requires: qt6qmlimport(org.kde.plasma.plasma5support)` |
| openSUSE Leap 16.0 / 16.1 | 6.4 / 6.6 | yes | same packaging |
| Arch Linux | 6.8.x | yes | `plasma-workspace` depends on kquickcharts, kdeclarative, kcmutils; `plasma-desktop` depends on plasma5support |
| Manjaro, EndeavourOS, CachyOS | Arch packages | yes, *unverified* (inherit Arch) | |
| NixOS (`services.desktopManager.plasma6`) | 6.5 (25.11), 6.8 (unstable) | yes; loading third-party plasmoids *unverified* | `plasma6.nix` requiredPackages; plasma-workspace dependencies include kquickcharts, kdeclarative, plasma5support |
| Gentoo | 6.7 stable, 6.8 testing | yes, with `kde-plasma/plasma-meta` | plasma-workspace RDEPEND; plasma-meta pulls plasma5support |
| Void | 6.8.x | yes, with `kde-plasma` | void-packages templates |
| Alpine | 6.3–6.8 | userland yes; **no wattage with stock kernels** (no UCSI) | `plasma-desktop-meta` deps; `linux-lts`/`linux-stable` configs lack `CONFIG_TYPEC_UCSI` |
| postmarketOS, Kali, Mageia, Solus, SteamOS desktop mode | | *unverified* (Kali follows Debian packaging) | |

If the hardware reports no rating, the tooltip and popup say so ("This
computer does not report the charger's rating to Linux…").

## If the widget shows an error instead of the gauge

When a QML module is missing, Plasma replaces the gauge with a generic icon.
Clicking it shows an error such as:

```text
…/CompactRepresentation.qml:10:1: module "org.kde.quickcharts" is not installed
```

Find the package that provides the named module:

| Distribution | Command (example for `org.kde.quickcharts`) |
|---|---|
| Debian, Ubuntu, KDE neon | `apt-file search org/kde/quickcharts/qmldir` (needs `apt-file`), or see the table below |
| Fedora, Kinoite | `sudo dnf install 'qt6qml(org.kde.quickcharts)'` (Kinoite: `rpm-ostree install …`) |
| openSUSE | `sudo zypper install 'qt6qmlimport(org.kde.quickcharts)'` |
| Arch and derivatives | `pacman -F usr/lib/qt6/qml/org/kde/quickcharts/qmldir` |

| Module in the error | Debian/Ubuntu | Arch |
|---|---|---|
| `org.kde.quickcharts` | `qml6-module-org-kde-quickcharts` | `kquickcharts` |
| `org.kde.plasma.plasma5support` | `qml6-module-org-kde-plasma-plasma5support` | `plasma5support` |
| `org.kde.kcmutils` | `qml6-module-org-kde-kcmutils` | `kcmutils` |
| `org.kde.kquickcontrols` | `qml6-module-org-kde-kquickcontrols` | `kdeclarative` |
| `Qt.labs.platform` | `qml6-module-qt-labs-platform` | `qt6-declarative` |
| `org.kde.kirigami` | `qml6-module-org-kde-kirigami` | `kirigami` |

Then restart Plasma (`systemctl --user restart plasma-plasmashell`) or log
out and back in. The Debian/Ubuntu names were checked with `dpkg -S` on
Kubuntu 26.04; the Arch names come from archlinux.org package data.

## Kernel and hardware

A rating is shown only for a non-battery supply that exposes `current_max`
and `voltage_max` (or, failing that, `voltage_max_design`) in sysfs.

| Driver | Device name | Rating | Notes |
|---|---|---|---|
| UCSI (`ucsi_acpi`, `ucsi/psy.c`) | `ucsi-source-psy-*` | **yes** | Most modern Intel and AMD laptops with ACPI `USBC000`. Registered with the power_supply class since about Linux 5.8 (*version unverified*). No per-vendor list (ThinkPad, Dell, Framework, …) could be verified |
| TCPM (`tcpm.c`) | `tcpm-source-psy-*` | **yes** | Many ARM boards and phones |
| ChromeOS EC (`cros-usbpd-charger`) | | **yes**, via fallback (*untested on hardware*) | Exposes `voltage_max_design` instead of `voltage_max`; the widget uses it when `voltage_max` is missing |
| TI TPS6598x / Apple CD321x (`tipd`, Apple Silicon) | | **no** | Only `online` and `usb_type`; Asahi's downstream drivers *unverified* |
| ACPI AC adapter | `AC`, `ADP1`, … | no | Only `online`: the widget shows "on external power" without wattage |

`CONFIG_TYPEC_UCSI=m` and `CONFIG_UCSI_ACPI=m` are set in the stock kernels of:
- Ubuntu 26.04 (checked locally);
- Debian trixie;
- Fedora;
- Arch;
- openSUSE Tumbleweed and SL-16.0;
- Void;
- Gentoo's dist-kernel, which uses Fedora's config.

NixOS sets modules automatically and very likely builds UCSI as a module
(*unverified*). Alpine's x86_64 kernels do not enable UCSI.

The drain warning needs only the battery's `status`, so it works without
UCSI on any laptop whose battery reports `Discharging`.

## Sources

- **Local:** `dpkg -S`, `apt-cache show` and `/boot/config-*` on Kubuntu 26.04.
- **Arch Linux:** archlinux.org package JSON.
- **Debian and Ubuntu:** packages.debian.org and the Launchpad API.
- **KDE neon:** archive.neon.kde.org.
- **Fedora:** src.fedoraproject.org spec files, fedora-comps and
  atomic-desktops config.
- **openSUSE:** src.opensuse.org and openSUSE/kernel-source.
- **Other distributions:** NixOS/nixpkgs, gentoo/gentoo, Alpine aports and
  void-packages.
- **KDE and Qt sources:** invent.kde.org (plasma-workspace,
  plasma-integration) and code.qt.io (qtdeclarative 6.10).
- **Linux kernel:** torvalds/linux
  (`drivers/usb/typec/ucsi/psy.c`, `tcpm/tcpm.c`,
  `drivers/power/supply/cros_usbpd-charger.c`).
