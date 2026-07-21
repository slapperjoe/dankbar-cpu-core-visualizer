import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    property string selectedDisplay: "auto"
    property var connectedDisplays: []
    property string currentRotation: "normal"

    function fetchDisplays() {
        Proc.runCommand("displays", ["sh", "-c", "niri msg --json outputs 2>/dev/null"],
            function(output, exitCode) {
                if (exitCode !== 0 || !output) {
                    root.connectedDisplays = [];
                    return;
                }
                try {
                    var data = JSON.parse(output);
                    var displays = [];
                    for (var key in data) {
                        displays.push(key);
                    }
                    root.connectedDisplays = displays;
                    if (displays.length > 0 && root.selectedDisplay === "auto") {
                        root.selectedDisplay = displays[0];
                        pluginService.savePluginData("quickActions", "selectedDisplay", displays[0]);
                    }
                } catch (e) {
                    console.error("Failed to parse niri outputs:", e);
                    root.connectedDisplays = [];
                }
            }, 50, 5000);
    }

    function fetchRotationState(display) {
        if (!display) display = root.selectedDisplay;
        Proc.runCommand("rotation", ["sh", "-c", "niri msg --json outputs 2>/dev/null"],
            function(output, exitCode) {
                if (exitCode !== 0 || !output) return;
                try {
                    var data = JSON.parse(output);
                    if (data[display]) {
                        var rot = data[display].logical.transform;
                        root.currentRotation = rot || "normal";
                    }
                } catch (e) {
                    console.error("Failed to parse rotation state:", e);
                }
            }, 50, 5000);
    }

    function rotateDisplay(transform) {
        var display = root.selectedDisplay;
        if (!display || display === "auto") {
            if (root.connectedDisplays.length > 0) {
                display = root.connectedDisplays[0];
                root.selectedDisplay = display;
                pluginService.savePluginData("quickActions", "selectedDisplay", display);
            } else {
                ToastService.error("No display", "No connected displays found.");
                return;
            }
        }
        Proc.runCommand("rotate", ["sh", "-c", "niri msg output " + display + " transform " + transform],
            function(output, exitCode) {
                if (exitCode !== 0) {
                    console.error("Failed to rotate display:", output);
                    ToastService.error("Rotation failed", "Could not rotate display.");
                } else {
                    ToastService.success("Display rotated", "Rotated " + display + " to " + transform);
                    root.fetchRotationState(display);
                }
            }, 50, 5000);
    }

    function rotateLeft() {
        root.rotateDisplay("90");
    }

    function rotateRight() {
        root.rotateDisplay("270");
    }

    function rotateNormal() {
        root.rotateDisplay("normal");
    }

    function rotateInverted() {
        root.rotateDisplay("180");
    }

    Component.onCompleted: {
        root.selectedDisplay = pluginData["selectedDisplay"] || "auto";
        root.fetchDisplays();
    }

    Component.onDestruction: {
    }

    Timer {
        id: settingsPoller
        interval: 250
        running: true
        repeat: true
        onTriggered: root.reloadSettings()
    }

    function reloadSettings() {
        root.selectedDisplay = pluginData["selectedDisplay"] || "auto";
    }

    horizontalBarPill: Component {
        MouseArea {
            implicitWidth: hContentRow.implicitWidth
            implicitHeight: hContentRow.implicitHeight
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.pillRightClickAction()
                } else {
                    root.pillClickAction()
                }
            }

            Row {
                id: hContentRow
                spacing: -4

                DankIcon {
                    name: "bolt"
                    size: Theme.iconSize - 6
                    color: "#FFFFFF"
                    filled: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    verticalBarPill: Component {
        MouseArea {
            implicitWidth: vContentRow.implicitWidth
            implicitHeight: vContentRow.implicitHeight
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.pillRightClickAction()
                } else {
                    root.pillClickAction()
                }
            }

            Row {
                id: vContentRow
                spacing: -4

                DankIcon {
                    name: "bolt"
                    size: Theme.iconSize - 6
                    color: "#FFFFFF"
                    filled: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    pillClickAction: function() {
        root.openPopout();
    }

    pillRightClickAction: function(posX, posY, posWidth, sectionName, currentScreen) {
        root.openPopout();
    }

    function openPopout() {
        root.fetchDisplays();
        var popout = null, pill = null;
        for (var i = 0; i < root.children.length; i++) {
            var child = root.children[i];
            if (typeof child.setTriggerPosition === "function") popout = child;
            if (typeof child.mapToItem === "function" && child.width !== undefined && child.width > 0 && typeof child.setTriggerPosition !== "function") pill = child;
        }
        if (popout && pill) {
            var globalPos = pill.mapToItem(null, 0, 0);
            var screen = root.parentScreen || Screen;
            var pos = SettingsData.getPopupTriggerPosition(globalPos, screen, root.barThickness, pill.width, 8, 0, null);
            popout.setTriggerPosition(pos.x, pos.y, pos.width, root.section, screen, 0, root.barThickness, 8, null);
            popout.toggle();
            if (root.selectedDisplay !== "auto") {
                root.fetchRotationState(root.selectedDisplay);
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Quick Actions"
            detailsText: "Display rotation and system shortcuts"
            showCloseButton: false

            Column {
                width: parent.width
                anchors.margins: 8
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacingM

                // ── Display Rotation ─────────────────────
                StyledText {
                    text: "Display Rotation"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    // Rotate Left
                    Rectangle {
                        width: (parent.width - 2 * Theme.spacingS) / 3
                        height: 56
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        anchors.verticalCenter: parent.verticalCenter

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            DankIcon {
                                name: "rotate_left"
                                size: 24
                                color: Theme.primary
                                filled: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: "Left 90°"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.rotateLeft();
                                popout.closePopout();
                            }
                        }
                    }

                    // Rotate Right
                    Rectangle {
                        width: (parent.width - 2 * Theme.spacingS) / 3
                        height: 56
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        anchors.verticalCenter: parent.verticalCenter

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            DankIcon {
                                name: "rotate_right"
                                size: 24
                                color: Theme.primary
                                filled: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: "Right 90°"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.rotateRight();
                                popout.closePopout();
                            }
                        }
                    }

                    // Rotate Normal
                    Rectangle {
                        width: (parent.width - 2 * Theme.spacingS) / 3
                        height: 56
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        anchors.verticalCenter: parent.verticalCenter

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            DankIcon {
                                name: "screen_rotation"
                                size: 24
                                color: Theme.primary
                                filled: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: "Normal"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.rotateNormal();
                                popout.closePopout();
                            }
                        }
                    }
                }

                // Current rotation indicator
                Rectangle {
                    width: parent.width
                    height: 28
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Row {
                        anchors.centerIn: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "monitor"
                            size: 16
                            color: Theme.surfaceVariantText
                            filled: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.selectedDisplay
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "— " + root.currentRotation + " rotation"
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall - 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
    popoutWidth: 340
    popoutHeight: 0
}
