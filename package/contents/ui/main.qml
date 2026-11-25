// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

import "../code/supply.js" as Supply

PlasmoidItem {
    id: root

    // Negotiated supply power: voltage_max × current_max of the best online
    // source that reports them (USB-C PD via UCSI, some AC adapters).
    property real watts: 0
    property var sources: []
    property bool onAc: false
    // Battery discharging while an external supply is online, debounced over
    // Supply.DRAIN_POLLS polls so a PD renegotiation blip does not show it.
    property int drainStreak: 0
    property real drainWatts: 0
    readonly property bool draining: drainStreak >= Supply.DRAIN_POLLS
    // The setting only controls the attention signals (colour, tray status);
    // the explanatory line is always shown while draining.
    readonly property bool warningActive: draining && Plasmoid.configuration.warnWhenDraining

    readonly property int maxWatts: Plasmoid.configuration.maxWatts

    readonly property color gaugeColor: Plasmoid.configuration.customGaugeColor ? Plasmoid.configuration.gaugeColor : Kirigami.Theme.highlightColor
    readonly property color trackColor: Plasmoid.configuration.customTrackColor ? Plasmoid.configuration.trackColor : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.1)
    readonly property color textColor: Plasmoid.configuration.customTextColor ? Plasmoid.configuration.textColor : Kirigami.Theme.textColor
    readonly property font labelFont: {
        const base = Kirigami.Theme.defaultFont;
        if (Plasmoid.configuration.autoFont || Plasmoid.configuration.fontFamily === "")
            return base;
        return Qt.font({
            family: Plasmoid.configuration.fontFamily,
            styleName: Plasmoid.configuration.fontStyleName,
            weight: Plasmoid.configuration.fontWeight,
            bold: Plasmoid.configuration.boldText,
            italic: Plasmoid.configuration.italicText,
            pointSize: base.pointSize
        });
    }

    function formatWatts(value: real): string {
        return i18nc("@label power in watts, %1 is a number", "%1 W", Math.round(value).toLocaleString(Qt.locale(), "f", 0));
    }

    function describeSource(source: var): string {
        return i18nc("@info %1 supply name, %2 volts, %3 amps, %4 watts", "%1: %2 V × %3 A = %4 W", source.name, source.volts.toLocaleString(Qt.locale(), "f", 1), source.amps.toLocaleString(Qt.locale(), "f", 2), Math.round(source.watts).toLocaleString(Qt.locale(), "f", 0));
    }

    readonly property string drainText: {
        if (!draining)
            return "";
        if (drainWatts <= 0)
            return i18nc("@info", "Battery is discharging while plugged in");
        return i18nc("@info %1 is a number of watts", "Battery is discharging at %1 W while plugged in", drainWatts.toLocaleString(Qt.locale(), "f", 1));
    }

    // Shown when external power is on but no supply reports a rating.
    readonly property string noRatingHint: onAc && sources.length === 0 ? i18nc("@info", "This computer does not report the charger's rating to Linux, so the wattage cannot be shown. The drain warning still works.") : ""

    readonly property string statusText: {
        if (!onAc)
            return i18nc("@info", "No external power");
        if (sources.length === 0)
            return i18nc("@info", "On external power (supply rating not reported)");
        return i18nc("@info %1 and %2 are power values with units", "%1 of %2", formatWatts(watts), formatWatts(maxWatts));
    }

    preferredRepresentation: compactRepresentation
    toolTipMainText: i18nc("@title tooltip", "Power Supply")
    toolTipSubText: {
        const lines = sources.length === 0 ? [statusText] : sources.map(describeSource);
        if (noRatingHint !== "")
            lines.push(noRatingHint);
        if (drainText !== "")
            lines.unshift(drainText);
        return lines.join("\n");
    }
    // Brings the widget out of the system tray's hidden area while warning.
    Plasmoid.status: warningActive ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus

    // Neither Plasma nor UPower exposes the negotiated PD rating, so sysfs is
    // read with a fixed command through the Plasma5Support "executable"
    // engine, which runs it asynchronously off the UI thread.
    P5Support.DataSource {
        id: reader
        engine: "executable"
        connectedSources: [Supply.COMMAND]
        interval: Plasmoid.configuration.intervalSeconds * 1000
        onNewData: (source, data) => {
            const result = Supply.parse(data["stdout"]);
            root.onAc = result.online;
            root.watts = result.watts;
            root.drainStreak = Supply.drainStreak(root.drainStreak, result.draining);
            root.drainWatts = result.drainWatts;
            // Reassigning an equal array would still rebuild the popup and tooltip.
            if (JSON.stringify(result.sources) !== JSON.stringify(root.sources))
                root.sources = result.sources;
        }
    }

    compactRepresentation: CompactRepresentation {
        value: root.watts
        maximum: root.maxWatts
        text: root.onAc ? i18nc("@label compact gauge, %1 is a number of watts", "%1W", Math.round(root.watts).toLocaleString(Qt.locale(), "f", 0)) : "—"
        formFactor: Plasmoid.formFactor
        expanded: root.expanded
        gaugeColor: root.gaugeColor
        warning: root.warningActive
        warningColor: Kirigami.Theme.negativeTextColor
        trackColor: root.trackColor
        textColor: root.textColor
        textOutline: Plasmoid.configuration.textOutline
        labelFont: root.labelFont
        accessibleName: Plasmoid.title
        accessibleDescription: root.drainText === "" ? root.statusText : i18nc("@info accessible description, %1 is the drain warning, %2 the supply status", "%1. %2", root.drainText, root.statusText)
        onExpandRequested: expand => root.expanded = expand
    }

    fullRepresentation: FullRepresentation {
        heading: root.statusText
        details: root.noRatingHint !== "" ? [root.noRatingHint] : root.sources.map(root.describeSource)
        warning: root.drainText
        warningColor: root.warningActive ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action", "Show Energy Information…")
            icon.name: "documentinfo"
            onTriggered: KCMUtils.KCMLauncher.openInfoCenter("kcm_energyinfo")
        }
    ]
}
