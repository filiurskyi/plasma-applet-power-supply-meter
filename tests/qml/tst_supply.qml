// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtTest

import "../../package/contents/code/supply.js" as Supply

TestCase {
    name: "SupplyParser"

    function line(name: string, attribute: string, value: string): string {
        return "/sys/class/power_supply/" + name + "/" + attribute + ":" + value;
    }

    function test_usbPdContract() {
        const out = [line("ucsi-source-psy-USBC000:001", "online", "1"), line("ucsi-source-psy-USBC000:001", "voltage_max", "19500000"), line("ucsi-source-psy-USBC000:001", "current_max", "6660000"), line("AC", "online", "1")].join("\n");
        const result = Supply.parse(out);
        verify(result.online);
        compare(result.sources.length, 1);
        compare(result.sources[0].name, "ucsi-source-psy-USBC000:001");
        fuzzyCompare(result.sources[0].volts, 19.5, 1e-9);
        fuzzyCompare(result.sources[0].amps, 6.66, 1e-9);
        fuzzyCompare(result.watts, 129.87, 1e-6);
    }

    function test_offlineSuppliesAreIgnored() {
        const out = [line("ucsi-source-psy-USBC000:002", "online", "0"), line("ucsi-source-psy-USBC000:002", "voltage_max", "5000000"), line("ucsi-source-psy-USBC000:002", "current_max", "3000000")].join("\n");
        const result = Supply.parse(out);
        verify(!result.online);
        compare(result.sources.length, 0);
        compare(result.watts, 0);
    }

    function test_onlineWithoutRatingCountsAsExternalPower() {
        // A plain AC adapter, or a UCSI read that failed: online but no rating.
        const result = Supply.parse(line("AC", "online", "1"));
        verify(result.online);
        compare(result.sources.length, 0);
        compare(result.watts, 0);
    }

    function test_zeroCurrentIsNotASource() {
        const out = [line("usb", "online", "1"), line("usb", "voltage_max", "5000000"), line("usb", "current_max", "0")].join("\n");
        const result = Supply.parse(out);
        verify(result.online);
        compare(result.sources.length, 0);
    }

    function test_bestSupplyWinsOverSum() {
        const out = [line("a", "online", "1"), line("a", "voltage_max", "20000000"), line("a", "current_max", "3250000"), line("b", "online", "1"), line("b", "voltage_max", "5000000"), line("b", "current_max", "3000000")].join("\n");
        const result = Supply.parse(out);
        compare(result.sources.length, 2);
        fuzzyCompare(result.watts, 65, 1e-9);
    }

    function test_garbageIsIgnored() {
        for (const out of [undefined, "", "grep: oops", "/sys/class/power_supply/x/online:not-a-number", "/etc/passwd:1"]) {
            const result = Supply.parse(out);
            verify(!result.online, String(out));
            compare(result.sources.length, 0);
        }
    }

    // BAT0 plus a 130 W USB-C contract and the AC adapter, as on the author's laptop.
    function pluggedIn(): var {
        return [line("ucsi-source-psy-USBC000:001", "type", "USB"), line("ucsi-source-psy-USBC000:001", "online", "1"), line("ucsi-source-psy-USBC000:001", "voltage_max", "19500000"), line("ucsi-source-psy-USBC000:001", "current_max", "6660000"), line("AC", "type", "Mains"), line("AC", "online", "1"), line("BAT0", "type", "Battery")];
    }

    function test_drainFromPowerNow() {
        const out = pluggedIn().concat([line("BAT0", "status", "Discharging"), line("BAT0", "power_now", "23500000")]).join("\n");
        const result = Supply.parse(out);
        verify(result.draining);
        fuzzyCompare(result.drainWatts, 23.5, 1e-9);
        // Existing fields are unaffected.
        verify(result.online);
        compare(result.sources.length, 1);
        fuzzyCompare(result.watts, 129.87, 1e-6);
    }

    function test_drainFromCurrentAndVoltage() {
        const out = pluggedIn().concat([line("BAT0", "status", "Discharging"), line("BAT0", "current_now", "1500000"), line("BAT0", "voltage_now", "16000000")]).join("\n");
        const result = Supply.parse(out);
        verify(result.draining);
        fuzzyCompare(result.drainWatts, 24, 1e-9);
    }

    function test_powerNowWinsAndSignIsIgnored() {
        const out = pluggedIn().concat([line("BAT0", "status", "Discharging"), line("BAT0", "power_now", "-10000000"), line("BAT0", "current_now", "-1500000"), line("BAT0", "voltage_now", "16000000")]).join("\n");
        fuzzyCompare(Supply.parse(out).drainWatts, 10, 1e-9);
    }

    function test_unknownDrainPowerIsZero() {
        const out = pluggedIn().concat([line("BAT0", "status", "Discharging"), line("BAT0", "voltage_now", "16000000")]).join("\n");
        const result = Supply.parse(out);
        verify(result.draining);
        compare(result.drainWatts, 0);
    }

    // Charge thresholds stop charging at a limit; that is normal, not a drain.
    function test_notChargingAndFullDoNotWarn() {
        for (const status of ["Not charging", "Full", "Charging", "Unknown"]) {
            const out = pluggedIn().concat([line("BAT0", "status", status), line("BAT0", "current_now", "1000000"), line("BAT0", "voltage_now", "16000000")]).join("\n");
            const result = Supply.parse(out);
            verify(!result.draining, status);
            compare(result.drainWatts, 0, status);
        }
    }

    function test_dischargingOnBatteryDoesNotWarn() {
        const out = [line("AC", "type", "Mains"), line("AC", "online", "0"), line("BAT0", "type", "Battery"), line("BAT0", "status", "Discharging"), line("BAT0", "power_now", "12000000")].join("\n");
        const result = Supply.parse(out);
        verify(!result.online);
        verify(!result.draining);
        compare(result.drainWatts, 0);
    }

    // The UCSI source reports a status and *_now values of its own; only
    // batteries count.
    function test_nonBatteryStatusIsIgnored() {
        const out = pluggedIn().concat([line("ucsi-source-psy-USBC000:001", "status", "Discharging"), line("ucsi-source-psy-USBC000:001", "current_now", "3000000"), line("ucsi-source-psy-USBC000:001", "voltage_now", "5000000"), line("BAT0", "status", "Not charging")]).join("\n");
        verify(!Supply.parse(out).draining);
    }

    function test_peripheralBatteryIsIgnored() {
        const out = pluggedIn().concat([line("hid-mouse-battery", "type", "Battery"), line("hid-mouse-battery", "scope", "Device"), line("hid-mouse-battery", "status", "Discharging"), line("BAT0", "status", "Not charging")]).join("\n");
        verify(!Supply.parse(out).draining);
    }

    function test_multipleBatteriesAreSummed() {
        const out = pluggedIn().concat([line("BAT0", "status", "Discharging"), line("BAT0", "power_now", "8000000"), line("BAT1", "type", "Battery"), line("BAT1", "status", "Discharging"), line("BAT1", "current_now", "500000"), line("BAT1", "voltage_now", "12000000"), line("BAT2", "type", "Battery"), line("BAT2", "status", "Full"), line("BAT2", "power_now", "99000000")]).join("\n");
        const result = Supply.parse(out);
        verify(result.draining);
        fuzzyCompare(result.drainWatts, 14, 1e-9);
    }

    // A supply without "type" still counts as external, as "online" always did.
    function test_missingAttributes() {
        const result = Supply.parse([line("AC", "online", "1"), line("BAT0", "type", "Battery"), line("BAT0", "status", "Discharging")].join("\n"));
        verify(result.draining);
        compare(result.drainWatts, 0);
        // No battery type: the status alone is not enough.
        verify(!Supply.parse([line("AC", "online", "1"), line("BAT0", "status", "Discharging")].join("\n")).draining);
    }

    // grep's output order follows the glob expansion and is not guaranteed.
    function test_orderDoesNotMatter() {
        const lines = pluggedIn().concat([line("BAT0", "status", "Discharging"), line("BAT0", "current_now", "2000000"), line("BAT0", "voltage_now", "15000000")]);
        const expected = Supply.parse(lines.join("\n"));
        for (const order of [lines.slice().reverse(), lines.slice(3).concat(lines.slice(0, 3)), lines.filter((_, i) => i % 2).concat(lines.filter((_, i) => !(i % 2)))]) {
            const result = Supply.parse(order.join("\n"));
            compare(JSON.stringify(result), JSON.stringify(expected));
        }
        verify(expected.draining);
        fuzzyCompare(expected.drainWatts, 30, 1e-9);
    }

    function test_drainStreakNeedsConsecutivePolls() {
        let streak = 0;
        streak = Supply.drainStreak(streak, true);
        verify(streak < Supply.DRAIN_POLLS, "one poll is not enough");
        streak = Supply.drainStreak(streak, false);
        compare(streak, 0, "a non-draining poll resets the streak");
        for (let i = 0; i < Supply.DRAIN_POLLS; ++i)
            streak = Supply.drainStreak(streak, true);
        verify(streak >= Supply.DRAIN_POLLS);
        compare(Supply.drainStreak(streak, true), streak, "the streak is capped");
        compare(Supply.drainStreak(streak, false), 0);
    }

    function test_commandIsFixedAndReadOnly() {
        verify(Supply.COMMAND.startsWith("grep -sH . /sys/class/power_supply/"));
        verify(!/[;&|`$<>]/.test(Supply.COMMAND), "command must not contain shell control characters");
        for (const attribute of ["online", "voltage_max", "current_max", "type", "scope", "status", "power_now", "current_now", "voltage_now"])
            verify(Supply.COMMAND.includes("/sys/class/power_supply/*/" + attribute + " ") || Supply.COMMAND.endsWith("/sys/class/power_supply/*/" + attribute), attribute);
    }

    function test_voltageMaxDesignFallback() {
        // cros-usbpd-charger reports voltage_max_design instead of voltage_max.
        const out = [line("cros-usbpd-charger", "online", "1"), line("cros-usbpd-charger", "type", "USB"), line("cros-usbpd-charger", "voltage_max_design", "20000000"), line("cros-usbpd-charger", "current_max", "3000000")].join("\n");
        const result = Supply.parse(out);
        compare(result.sources.length, 1);
        fuzzyCompare(result.watts, 60, 1e-9);
    }

    function test_voltageMaxPreferredOverDesign() {
        const out = [line("usb", "online", "1"), line("usb", "voltage_max", "15000000"), line("usb", "voltage_max_design", "20000000"), line("usb", "current_max", "3000000")].join("\n");
        fuzzyCompare(Supply.parse(out).watts, 45, 1e-9);
    }

    function test_batteryIsNeverARatedSource() {
        const out = [line("BAT0", "online", "1"), line("BAT0", "type", "Battery"), line("BAT0", "voltage_max_design", "15400000"), line("BAT0", "current_max", "5000000")].join("\n");
        compare(Supply.parse(out).sources.length, 0);
    }
}
