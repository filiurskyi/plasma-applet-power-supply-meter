# Compatibility

| Layer | Needed |
|---|---|
| Plasma and Qt | Plasma 6.0+ and the QML modules below |
| Userland | `/bin/sh` and a `grep` with `-s` and `-H` (GNU, BusyBox and Toybox all qualify) |
| Kernel and hardware | a `power_supply` with `voltage_max` and `current_max` |

**Tested:** Plasma 6.6.7 with Qt 6.10 on Kubuntu 26.04 (Wayland, UCSI
laptop). The rest comes from package dependencies and kernel configs,
researched on 2026-11-25. *Unverified* entries could not be confirmed from a
primary source.

## What the widget uses

| Module | Debian/Ubuntu package | Arch package | Used for |
|---|---|---|---|
| Qt Quick, Layouts, Controls | `qml6-module-qtquick*` | | everything |
| `Qt.labs.platform` | `qml6-module-qt-labs-platform` | `qt6-declarative` | font dialog in settings |
| `org.kde.kirigami` | `qml6-module-org-kde-kirigami` | `kirigami` | theme, units, settings layout |
| `org.kde.kcmutils` | `qml6-module-org-kde-kcmutils` | `kcmutils` | settings pages, Info Center action |
| `org.kde.kquickcontrols` | `qml6-module-org-kde-kquickcontrols` | `kdeclarative` | colour buttons |
| `org.kde.quickcharts` (+ `.controls`) | `qml6-module-org-kde-quickcharts` | `kquickcharts` | the gauge |
| `org.kde.plasma.plasma5support` + "executable" engine | `qml6-module-org-kde-plasma-plasma5support` → `libplasma5support6` | `plasma5support` | runs the sysfs `grep` |
| `org.kde.plasma.{plasmoid,core,components,configuration}` | `plasma-desktoptheme` | | Plasma integration |
| `kcm_energyinfo` (optional) | `kinfocenter` | | "Show Energy Information…" action |

Debian/Ubuntu names: `dpkg -S` on Kubuntu 26.04. Arch names: archlinux.org
package data.

The command reads these attributes of every `/sys/class/power_supply/*`
entry, skipping missing ones: `online`, `voltage_max`, `voltage_max_design`,
`current_max`, `type`, `scope`, `status`, `power_now`, `current_now`,
`voltage_now`.

`Qt.labs.platform.FontDialog` has no Plasma-native implementation; Qt falls
back to the Qt Widgets `QFontDialog`, which works because plasmashell is a
`QApplication`.

## If the widget shows an error instead of the gauge

A QML module is missing. Plasma shows a generic icon; clicking it shows:

```text
…/CompactRepresentation.qml:10:1: module "org.kde.quickcharts" is not installed
```

Install the package that provides the named module, from the table above or
with:

| Distribution | Command (example for `org.kde.quickcharts`) |
|---|---|
| Debian, Ubuntu, KDE neon | `apt-file search org/kde/quickcharts/qmldir` (needs `apt-file`) |
| Fedora, Kinoite | `sudo dnf install 'qt6qml(org.kde.quickcharts)'` (Kinoite: `rpm-ostree install …`) |
| openSUSE | `sudo zypper install 'qt6qmlimport(org.kde.quickcharts)'` |
| Arch and derivatives | `pacman -F usr/lib/qt6/qml/org/kde/quickcharts/qmldir` |

Then restart Plasma (`systemctl --user restart plasma-plasmashell`) or log
out and back in.

## Distributions

Where "yes", the standard Plasma 6 desktop install pulls in every module
above.

| Distribution | Plasma | Works out of the box | Evidence |
|---|---|---|---|
| Kubuntu 26.04 | 6.6.7 | yes (**tested**) | `plasma-workspace` Depends on quickcharts, kquickcontrols, kcmutils, plasma5support; `plasma-desktop` Depends on qt-labs-platform |
| Kubuntu 25.10 | 6.4.5 | yes | same packaging (Launchpad) |
| Kubuntu 24.04 LTS | 5.27.12 | **no**: Plasma 5; the Kubuntu backports PPA has Plasma 6 only for 25.10 and 26.04 | Launchpad |
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

## Kernel and hardware

A rating is shown only for a non-battery supply that exposes `current_max`
and `voltage_max` (or, failing that, `voltage_max_design`). Otherwise the
tooltip and popup say "This computer does not report the charger's rating to
Linux…".

| Driver | Device name | Rating | Notes |
|---|---|---|---|
| UCSI (`ucsi_acpi`, `ucsi/psy.c`) | `ucsi-source-psy-*` | **yes** | Most modern Intel and AMD laptops with ACPI `USBC000`. In the power_supply class since about Linux 5.8 (*version unverified*). No per-vendor list could be verified |
| TCPM (`tcpm.c`) | `tcpm-source-psy-*` | **yes** | Many ARM boards and phones |
| ChromeOS EC (`cros-usbpd-charger`) | | **yes** (*untested on hardware*) | Exposes `voltage_max_design` instead of `voltage_max` |
| TI TPS6598x / Apple CD321x (`tipd`, Apple Silicon) | | **no** | Only `online` and `usb_type`; Asahi's downstream drivers *unverified* |
| ACPI AC adapter | `AC`, `ADP1`, … | **no** | Only `online` |

`CONFIG_TYPEC_UCSI=m` and `CONFIG_UCSI_ACPI=m` are set in the stock kernels
of Ubuntu 26.04 (checked locally), Debian trixie, Fedora, Arch, openSUSE
Tumbleweed and SL-16.0, Void, and Gentoo's dist-kernel (Fedora's config).
NixOS: *unverified*. Alpine x86_64: not enabled.

The drain warning needs only the battery's `status`, so it works without
UCSI.

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
