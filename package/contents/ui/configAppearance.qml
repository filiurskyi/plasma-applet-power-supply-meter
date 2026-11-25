// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.platform as Platform

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.kquickcontrols as KQuickControls

KCMUtils.SimpleKCM {
    id: page

    // Both radio buttons bind to this; a ButtonGroup would uncheck them
    // imperatively and break the bindings.
    property bool cfg_autoFont
    // Not all of these affect rendering, but they keep the exact style when
    // the font dialog is reopened (same approach as the Digital Clock applet).
    property alias cfg_fontFamily: fontDialog.fontChosen.family
    property alias cfg_boldText: fontDialog.fontChosen.bold
    property alias cfg_italicText: fontDialog.fontChosen.italic
    property alias cfg_fontWeight: fontDialog.fontChosen.weight
    property alias cfg_fontStyleName: fontDialog.fontChosen.styleName

    property alias cfg_customGaugeColor: customGaugeColor.checked
    property alias cfg_gaugeColor: gaugeColor.color
    property alias cfg_customTrackColor: customTrackColor.checked
    property alias cfg_trackColor: trackColor.color
    property alias cfg_customTextColor: customTextColor.checked
    property alias cfg_textColor: textColor.color
    property alias cfg_textOutline: textOutline.checked

    Kirigami.FormLayout {
        QQC2.RadioButton {
            Kirigami.FormData.label: i18nc("@label:group", "Font:")
            text: i18nc("@option:radio", "System default")
            autoExclusive: false
            checked: page.cfg_autoFont
            onToggled: page.cfg_autoFont = true
        }
        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC2.RadioButton {
                id: manualFontButton
                text: i18nc("@option:radio", "Custom")
                autoExclusive: false
                checked: !page.cfg_autoFont
                onToggled: {
                    page.cfg_autoFont = false;
                    if (page.cfg_fontFamily === "")
                        fontDialog.fontChosen = Kirigami.Theme.defaultFont;
                }
            }
            QQC2.Button {
                text: i18nc("@action:button", "Choose Font…")
                icon.name: "settings-configure"
                enabled: manualFontButton.checked
                onClicked: {
                    fontDialog.currentFont = fontDialog.fontChosen;
                    fontDialog.open();
                }
            }
        }
        QQC2.Label {
            visible: manualFontButton.checked
            text: fontDialog.fontChosen.styleName === "" ? fontDialog.fontChosen.family : i18nc("@info %1 font family, %2 font style", "%1 %2", fontDialog.fontChosen.family, fontDialog.fontChosen.styleName)
            textFormat: Text.PlainText
            font.family: fontDialog.fontChosen.family
            font.styleName: fontDialog.fontChosen.styleName
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label", "Gauge colour:")
            spacing: Kirigami.Units.smallSpacing
            QQC2.CheckBox {
                id: customGaugeColor
                text: i18nc("@option:check", "Custom")
                Accessible.name: i18nc("@option:check accessible", "Custom gauge colour")
            }
            KQuickControls.ColorButton {
                id: gaugeColor
                enabled: customGaugeColor.checked
                showAlphaChannel: false
                dialogTitle: i18nc("@title:window", "Choose Gauge Colour")
                Accessible.name: i18nc("@label accessible", "Gauge colour")
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18nc("@label", "Track colour:")
            spacing: Kirigami.Units.smallSpacing
            QQC2.CheckBox {
                id: customTrackColor
                text: i18nc("@option:check", "Custom")
                Accessible.name: i18nc("@option:check accessible", "Custom track colour")
            }
            KQuickControls.ColorButton {
                id: trackColor
                enabled: customTrackColor.checked
                showAlphaChannel: false
                dialogTitle: i18nc("@title:window", "Choose Track Colour")
                Accessible.name: i18nc("@label accessible", "Track colour")
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18nc("@label", "Text colour:")
            spacing: Kirigami.Units.smallSpacing
            QQC2.CheckBox {
                id: customTextColor
                text: i18nc("@option:check", "Custom")
                Accessible.name: i18nc("@option:check accessible", "Custom text colour")
            }
            KQuickControls.ColorButton {
                id: textColor
                enabled: customTextColor.checked
                showAlphaChannel: false
                dialogTitle: i18nc("@title:window", "Choose Text Colour")
                Accessible.name: i18nc("@label accessible", "Text colour")
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: i18nc("@info", "Colours that are not customised follow the Plasma theme.")
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            opacity: 0.8
        }

        QQC2.CheckBox {
            id: textOutline
            Kirigami.FormData.label: i18nc("@label", "Label:")
            text: i18nc("@option:check", "Draw outline for readability")
        }
    }

    // Qt.labs.platform gives the native KDE font dialog, as in the Digital
    // Clock applet; the QtQuick.Dialogs version does not integrate as well.
    Platform.FontDialog {
        id: fontDialog

        property font fontChosen: Kirigami.Theme.defaultFont

        title: i18nc("@title:window", "Choose a Font")
        modality: Qt.WindowModal
        parentWindow: page.Window.window
        onAccepted: fontChosen = font
    }
}
