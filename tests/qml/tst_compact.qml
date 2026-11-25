// SPDX-FileCopyrightText: 2026 Andrii Filiurskyi
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtTest

import org.kde.plasma.core as PlasmaCore

import "../../package/contents/ui" as Ui

// TestCase is invisible, so the item under test needs a visible parent to
// receive mouse events.
Item {
    id: root

    width: 200
    height: 200

    TestCase {
        name: "CompactRepresentation"
        when: windowShown

        Component {
            id: compactComponent

            Ui.CompactRepresentation {
                width: 40
                height: 40
            }
        }

        SignalSpy {
            id: spy

            signalName: "expandRequested"
        }

        function createCompact(properties: var): var {
            const item = createTemporaryObject(compactComponent, root, properties);
            verify(item);
            spy.clear();
            spy.target = item;
            waitForRendering(item);
            return item;
        }

        function test_valueIsClampedToRange() {
            const item = createCompact({
                value: 180,
                maximum: 130
            });
            compare(item.clampedValue, 130);
            item.value = -5;
            compare(item.clampedValue, 0);
            item.value = 60;
            compare(item.clampedValue, 60);
        }

        function test_clickTogglesPopup() {
            const item = createCompact({
                expanded: false
            });
            mouseClick(item);
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0], true);
        }

        // The popup closes on press because it loses focus; the click must then
        // keep it closed instead of reopening it.
        function test_clickWhileExpandedCloses() {
            const item = createCompact({
                expanded: true
            });
            mouseClick(item);
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0], false);
        }

        function test_keyboardActivation() {
            const item = createCompact({
                expanded: false
            });
            item.forceActiveFocus();
            verify(item.activeFocus);
            for (const key of [Qt.Key_Space, Qt.Key_Return, Qt.Key_Enter]) {
                keyClick(key);
            }
            compare(spy.count, 3);
        }

        function test_horizontalPanelSizing() {
            const item = createCompact({
                formFactor: PlasmaCore.Types.Horizontal
            });
            item.height = 30;
            compare(item.Layout.preferredWidth, 30);
            compare(item.Layout.preferredHeight, -1);
        }

        function test_warningOverridesArcColor() {
            const item = createCompact({
                gaugeColor: "#3daee9",
                warningColor: "#da4453"
            });
            compare(item.arcColor, Qt.color("#3daee9"));
            item.warning = true;
            compare(item.arcColor, Qt.color("#da4453"));
            item.warning = false;
            compare(item.arcColor, Qt.color("#3daee9"));
        }

        function test_accessibility() {
            const item = createCompact({
                accessibleName: "Power Supply",
                accessibleDescription: "130 W of 130 W"
            });
            compare(item.Accessible.role, Accessible.Button);
            compare(item.Accessible.name, "Power Supply");
            compare(item.Accessible.description, "130 W of 130 W");
        }
    }
}
