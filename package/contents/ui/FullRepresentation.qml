// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Popup with an optional warning, the total and a line per supply.
ColumnLayout {
    id: full

    property string heading: ""
    property list<string> details: []
    // Shown above the heading when not empty.
    property string warning: ""
    property color warningColor: Kirigami.Theme.negativeTextColor

    // As wide as the longest line, so the popup fits its content; capped so
    // long text (the drain warning, the no-rating hint) wraps instead.
    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.preferredWidth: Math.min(implicitWidth, Kirigami.Units.gridUnit * 24)
    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        Layout.fillWidth: true
        visible: full.warning !== ""
        text: full.warning
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: full.warningColor
        font.bold: true
    }

    Kirigami.Heading {
        Layout.fillWidth: true
        level: 4
        text: full.heading
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }

    Repeater {
        model: full.details

        PlasmaComponents.Label {
            required property string modelData

            Layout.fillWidth: true
            text: modelData
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
        }
    }
}
