// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartControls

// Circular gauge shown in panels and on the desktop. Has no dependency on
// the Plasmoid attached object so it can be tested on its own.
MouseArea {
    id: compact

    property real value: 0
    property real maximum: 100
    property string text: ""
    property int formFactor: PlasmaCore.Types.Planar
    property bool expanded: false
    property color gaugeColor: Kirigami.Theme.highlightColor
    // While warning, the arc uses warningColor instead of gaugeColor.
    property bool warning: false
    property color warningColor: Kirigami.Theme.negativeTextColor
    readonly property color arcColor: warning ? warningColor : gaugeColor
    property color trackColor: Kirigami.Theme.backgroundColor
    property color textColor: Kirigami.Theme.textColor
    property bool textOutline: true
    property font labelFont: Kirigami.Theme.defaultFont
    property string accessibleName: ""
    property string accessibleDescription: ""

    readonly property real clampedValue: Math.max(0, Math.min(value, maximum))

    signal expandRequested(bool expand)

    readonly property bool horizontal: formFactor === PlasmaCore.Types.Horizontal
    readonly property bool vertical: formFactor === PlasmaCore.Types.Vertical

    // Same sizing as the System Monitor compact pie face.
    Layout.minimumWidth: Kirigami.Units.gridUnit
    Layout.minimumHeight: Kirigami.Units.gridUnit
    Layout.maximumWidth: horizontal ? Math.max(Kirigami.Units.iconSizes.enormous, Layout.minimumWidth) : -1
    Layout.maximumHeight: vertical ? Math.max(Kirigami.Units.iconSizes.enormous, Layout.minimumHeight) : -1
    Layout.preferredWidth: horizontal ? Math.min(Math.max(height, Layout.minimumWidth), Layout.maximumWidth) : -1
    Layout.preferredHeight: vertical ? Math.min(Math.max(width, Layout.minimumHeight), Layout.maximumHeight) : -1

    activeFocusOnTab: true
    hoverEnabled: true
    Accessible.name: accessibleName
    Accessible.description: accessibleDescription
    Accessible.role: Accessible.Button
    Accessible.onPressAction: expandRequested(!expanded)

    // The popup closes when focus leaves it, i.e. on press. Remember the
    // state at press time so a click on the gauge closes it instead of
    // reopening it.
    property bool wasExpanded: false
    onPressed: wasExpanded = expanded
    onClicked: expandRequested(!wasExpanded)
    Keys.onPressed: event => {
        if ([Qt.Key_Space, Qt.Key_Enter, Qt.Key_Return, Qt.Key_Select].includes(event.key)) {
            expandRequested(!expanded);
            event.accepted = true;
        }
    }

    ChartControls.PieChartControl {
        id: chart
        anchors.centerIn: parent
        width: Math.max(0, Math.min(parent.width, parent.height) - 2)
        height: width
        // The Plasma style sets explicit side paddings, which "padding: 0"
        // would not override; without these the ring shrinks to a disc.
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0

        range {
            from: 0
            to: compact.maximum
            automatic: false
        }
        valueSources: Charts.SingleValueSource {
            value: compact.clampedValue
        }
        chart.colorSource: Charts.SingleValueSource {
            value: compact.arcColor
        }
        chart.backgroundColor: compact.trackColor
        chart.thickness: Kirigami.Units.smallSpacing
        chart.smoothEnds: true

        QQC2.Label {
            id: label
            anchors.fill: parent
            text: compact.text
            color: compact.textColor
            font: compact.labelFont
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.HorizontalFit
            minimumPointSize: Kirigami.Theme.smallFont.pointSize * 0.8
            maximumLineCount: 1
            // Outline in the opposite brightness of the text, so it stays
            // readable over the ring and any panel background.
            style: compact.textOutline ? Text.Outline : Text.Normal
            styleColor: Kirigami.ColorUtils.brightnessForColor(compact.textColor) === Kirigami.ColorUtils.Light ? Qt.rgba(0, 0, 0, 0.9) : Qt.rgba(1, 1, 1, 0.9)
        }
    }

    // Keyboard focus indicator.
    Rectangle {
        anchors.fill: parent
        visible: compact.activeFocus
        color: "transparent"
        border.color: Kirigami.Theme.focusColor
        border.width: 1
        radius: Kirigami.Units.cornerRadius
    }
}
