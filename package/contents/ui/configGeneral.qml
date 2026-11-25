// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    property alias cfg_maxWatts: maxWatts.value
    property alias cfg_intervalSeconds: intervalSeconds.value
    property alias cfg_warnWhenDraining: warnWhenDraining.checked

    Kirigami.FormLayout {
        // Plain integer spin boxes with the unit beside them: a unit inside
        // the text would break typing with SpinBox's default IntValidator.
        RowLayout {
            Kirigami.FormData.label: i18nc("@label:spinbox", "Full scale:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: maxWatts
                from: 1
                to: 500
                editable: true
                Accessible.name: i18nc("@label:spinbox accessible", "Full scale in watts")
            }
            QQC2.Label {
                text: i18nc("@label unit after a spin box", "W")
                textFormat: Text.PlainText
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: i18nc("@info", "Set this to the rating of your charger, for example 65 W or 100 W.")
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            opacity: 0.8
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:spinbox", "Update interval:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: intervalSeconds
                from: 1
                to: 60
                editable: true
                Accessible.name: i18nc("@label:spinbox accessible", "Update interval in seconds")
            }
            QQC2.Label {
                text: i18ncp("@label unit after a spin box", "second", "seconds", intervalSeconds.value)
                textFormat: Text.PlainText
            }
        }

        QQC2.CheckBox {
            id: warnWhenDraining
            Kirigami.FormData.label: i18nc("@label:checkbox", "Battery:")
            text: i18nc("@option:check", "Warn when the battery drains while plugged in")
        }
    }
}
