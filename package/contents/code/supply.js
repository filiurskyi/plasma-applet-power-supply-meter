// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

.pragma library

// Fixed, read-only command. The shell expands the globs; "grep -sH ." prints
// every non-empty attribute as "<path>:<value>" and silently skips missing
// or unreadable files (for example a UCSI read failing with EIO). The order
// of the output lines is not guaranteed.
// "var" so the importing QML can read it as Supply.COMMAND.
var COMMAND = "grep -sH . /sys/class/power_supply/*/online /sys/class/power_supply/*/voltage_max /sys/class/power_supply/*/voltage_max_design /sys/class/power_supply/*/current_max /sys/class/power_supply/*/type /sys/class/power_supply/*/scope /sys/class/power_supply/*/status /sys/class/power_supply/*/power_now /sys/class/power_supply/*/current_now /sys/class/power_supply/*/voltage_now";

// Consecutive polls the battery must drain on external power before the
// warning shows, so a brief PD renegotiation does not flash it.
var DRAIN_POLLS = 2;

// Supply names can contain ":" (ucsi-source-psy-USBC000:001), so match the
// attribute name and take everything after its colon as the value.
const LINE = /^\/sys\/class\/power_supply\/([^/]+)\/(online|voltage_max|voltage_max_design|current_max|type|scope|status|power_now|current_now|voltage_now):(.*)$/;
const TEXT_ATTRIBUTES = ["type", "scope", "status"];

// Power a discharging battery delivers, in watts, or 0 if it reports neither
// power_now (µW) nor current_now (µA) and voltage_now (µV). Some drivers
// report negative values while discharging, so the magnitude is used.
function batteryWatts(battery) {
    if (Number.isFinite(battery.power_now))
        return Math.abs(battery.power_now) / 1e6;
    const watts = Math.abs(battery.current_now * battery.voltage_now) / 1e12;
    return Number.isFinite(watts) ? watts : 0;
}

// Parses the output of COMMAND.
// Returns { online, sources: [{ name, volts, amps, watts }], watts, draining, drainWatts }.
// "online" is true when any external supply is connected, even one that does
// not report its rating; such supplies are not listed in "sources".
// "watts" is the best single supply: a laptop draws from one source at a time.
// "draining" is true when an external supply is online and a system battery
// reports "Discharging". "Not charging" and "Full" are normal on external
// power (charge thresholds), so they never count. "drainWatts" is the total
// discharge power of those batteries, 0 if unknown.
function parse(stdout) {
    const supplies = {};
    for (const line of String(stdout || "").split("\n")) {
        const match = LINE.exec(line.trim());
        if (!match)
            continue;
        const supply = supplies[match[1]] || (supplies[match[1]] = {});
        supply[match[2]] = TEXT_ATTRIBUTES.includes(match[2]) ? match[3] : Number(match[3]);
    }

    const sources = [];
    let online = false;
    let external = false;
    let best = 0;
    let draining = false;
    let drainWatts = 0;
    for (const name of Object.keys(supplies).sort()) {
        const supply = supplies[name];
        // Peripheral batteries (mice, headsets) have scope "Device".
        if (supply.type === "Battery" && supply.scope !== "Device" && supply.status === "Discharging") {
            draining = true;
            drainWatts += batteryWatts(supply);
        }
        if (supply.online !== 1)
            continue;
        online = true;
        if (supply.type !== "Battery")
            external = true;
        // A battery is not a charger; its voltage_max_design is the pack's.
        if (supply.type === "Battery")
            continue;
        // ChromeOS EC chargers (cros-usbpd-charger) report the contract
        // voltage only as voltage_max_design.
        const volts = (Number.isFinite(supply.voltage_max) ? supply.voltage_max : supply.voltage_max_design) / 1e6;
        const amps = supply.current_max / 1e6;
        const watts = volts * amps;
        if (!Number.isFinite(watts) || watts <= 0)
            continue;
        sources.push({ name: name, volts: volts, amps: amps, watts: watts });
        best = Math.max(best, watts);
    }
    draining = draining && external;
    return { online: online, sources: sources, watts: best, draining: draining, drainWatts: draining ? drainWatts : 0 };
}

// Number of consecutive draining polls including this one, capped at
// DRAIN_POLLS so the value stops changing once the warning is shown.
function drainStreak(previous, draining) {
    return draining ? Math.min(previous + 1, DRAIN_POLLS) : 0;
}
