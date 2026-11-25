// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18nc("@title config page", "General")
        icon: "battery-ac-adapter"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18nc("@title config page", "Appearance")
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
}
