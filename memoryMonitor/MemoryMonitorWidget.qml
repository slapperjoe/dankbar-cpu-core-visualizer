import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // ── Settings ──────────────────────────────────────────────
    property int probeIntervalMs: 3000
    property string colorMode: "vivid"
    property int smoothingPercent: 15

    // ── Runtime data ──────────────────────────────────────────
    readonly property real memoryUsageValue: Math.max(0, Math.min(100, Number(DgopService.memoryUsage || 0)))
    property real animatedMemoryUsage: 0

    // ── Smoothing ─────────────────────────────────────────────
    readonly property real smoothingFactor: Math.pow(0.5, smoothingPercent / 100.0)

    // ── 2-color mini palette (usage-based color) ──────────────
    readonly property string barColor: {
        const usage = root.animatedMemoryUsage;
        if (root.colorMode === "soft") {
            if (usage < 50) return "#9AEF9A";
            if (usage < 80) return "#EFD49A";
            return "#EF9A9A";
        }
        if (usage < 50) return "#2DFF2D";
        if (usage < 80) return "#FFD42D";
        return "#FF2D2D";
    }

    // ── Process list ──────────────────────────────────────────
    readonly property var memoryProcesses: Array.isArray(DgopService.memoryProcesses) ? DgopService.memoryProcesses : []

    // ── Settings load ─────────────────────────────────────────
    Component.onCompleted: {
        root.probeIntervalMs = Math.max(500, Math.min(10000, Math.round(pluginData["probeInterval"] || 3000)));
        root.colorMode = pluginData["colorMode"] || "vivid";
        root.smoothingPercent = Math.max(1, Math.min(99, Math.round(pluginData["smoothingPercent"] || 15)));
        DgopService.addRef(["memory", "processes"]);
        root.syncAnimatedMemoryUsage(true);
    }

    Component.onDestruction: {
        DgopService.removeRef(["memory", "processes"]);
    }

    // ── Timers ────────────────────────────────────────────────
    Timer {
        id: probeTimer
        interval: root.probeIntervalMs
        running: true
        repeat: true
        onTriggered: DgopService.updateAllStats()
    }

    Timer {
        id: animationTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: root.syncAnimatedMemoryUsage(false)
    }

    // ── Functions ─────────────────────────────────────────────
    function syncUsageValue(current, target, force) {
        if (force || Number.isNaN(current))
            return target;
        const delta = target - current;
        if (Math.abs(delta) < 0.35)
            return target;
        return current + delta * root.smoothingFactor;
    }

    function syncAnimatedMemoryUsage(force) {
        root.animatedMemoryUsage = root.syncUsageValue(root.animatedMemoryUsage, root.memoryUsageValue, force);
    }

    function overallTextSize() {
        const fontScale = root.barConfig ? root.barConfig.fontScale : undefined;
        const maximizeText = root.barConfig ? root.barConfig.maximizeWidgetText : undefined;
        return Theme.barTextSize(root.barThickness, fontScale, maximizeText);
    }

    function processCommand(proc) {
        const command = String(proc && proc.command || "");
        if (command.length > 0)
            return command.trim();
        const fullCommand = String(proc && (proc.fullCommand || proc.command) || "");
        if (fullCommand.length <= 0)
            return "unknown";
        const firstToken = fullCommand.split(/\s+/)[0] || fullCommand;
        const slashParts = firstToken.split("/");
        return slashParts[slashParts.length - 1] || firstToken;
    }

    // ── Horizontal bar pill ───────────────────────────────────
    horizontalBarPill: Component {
        MouseArea {
            implicitWidth: hContentRow.implicitWidth + 24
            implicitHeight: root.barThickness
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.pillRightClickAction();
                else
                    root.pillClickAction();
            }

            Row {
                id: hContentRow
                anchors.centerIn: parent
                spacing: 4

                Rectangle {
                    width: Math.max(24, root.barThickness * 1.2)
                    height: Math.max(8, root.barThickness - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Math.min(4, height / 2)
                    color: Theme.surfaceContainerHigh
                    clip: true

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Math.max(2, root.animatedMemoryUsage / 100 * parent.height)
                        radius: Math.min(4, parent.height / 2)
                        color: root.barColor

                        Behavior on height {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                DankIcon {
                    name: "sd_card"
                    size: Theme.iconSize - 4
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.animatedMemoryUsage.toFixed(0) + "%"
                    color: Theme.widgetTextColor
                    font.pixelSize: Math.max(8, root.overallTextSize())
                    font.weight: Font.Medium
                }
            }
        }
    }

    // ── Vertical bar pill ─────────────────────────────────────
    verticalBarPill: Component {
        MouseArea {
            implicitWidth: vContentColumn.implicitWidth + 16
            implicitHeight: root.barThickness
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.pillRightClickAction();
                else
                    root.pillClickAction();
            }

            Column {
                id: vContentColumn
                anchors.centerIn: parent
                spacing: 2

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.animatedMemoryUsage.toFixed(0) + "%"
                    color: Theme.widgetTextColor
                    font.pixelSize: Math.max(7, root.overallTextSize() - 1)
                    font.weight: Font.Medium
                }

                Rectangle {
                    width: Math.max(12, root.barThickness * 0.4)
                    height: Math.max(30, root.barThickness * 1.2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: Math.min(4, width / 2)
                    color: Theme.surfaceContainerHigh
                    clip: true

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Math.max(2, root.animatedMemoryUsage / 100 * parent.height)
                        radius: Math.min(4, parent.width / 2)
                        color: root.barColor

                        Behavior on height {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
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
        var popout = null;
        var pill = null;
        for (var i = 0; i < root.children.length; i++) {
            var child = root.children[i];
            if (typeof child.setTriggerPosition === "function")
                popout = child;
            if (typeof child.mapToItem === "function" && child.width !== undefined && child.width > 0 && typeof child.setTriggerPosition !== "function")
                pill = child;
        }
        if (popout && pill) {
            var globalPos = pill.mapToItem(null, 0, 0);
            var screen = root.parentScreen || Screen;
            var pos = SettingsData.getPopupTriggerPosition(globalPos, screen, root.barThickness, pill.width, 8, 0, null);
            popout.setTriggerPosition(pos.x, pos.y, pos.width, root.section, screen, 0, root.barThickness, 8, null);
            popout.toggle();
        }
    }

    // ── Popout content ────────────────────────────────────────
    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Memory Monitor"
            detailsText: root.animatedMemoryUsage.toFixed(0) + "% used  |  " +
                DgopService.formatSystemMemory(DgopService.usedMemoryKB) + " / " +
                DgopService.formatSystemMemory(DgopService.totalMemoryKB)
            showCloseButton: false

            Column {
                width: parent.width
                anchors.margins: 8
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacingM

                // ── Memory usage card ──────────────────
                Rectangle {
                    width: parent.width
                    height: 80
                    color: Theme.surfaceContainerHigh
                    radius: Theme.cornerRadius
                    border.width: 1
                    border.color: Theme.outline

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingXS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "sd_card"
                                size: Theme.iconSize
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "Memory Usage"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Item {
                                width: parent.width - Theme.iconSize - Theme.spacingS - usagePctLabel.implicitWidth - Theme.spacingS
                                height: 1
                            }

                            StyledText {
                                id: usagePctLabel
                                text: root.animatedMemoryUsage.toFixed(0) + "%"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 8
                            radius: 4
                            color: Theme.surfaceContainerHighest

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * root.animatedMemoryUsage / 100
                                radius: 4
                                color: root.barColor

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        StyledText {
                            width: parent.width
                            text: DgopService.formatSystemMemory(DgopService.usedMemoryKB) + " used  /  " +
                                  DgopService.formatSystemMemory(DgopService.totalMemoryKB) + " total"
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }

                // ── Process list header ──────────────────
                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "PID"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        width: 50
                    }

                    StyledText {
                        text: "Process"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        width: parent.width - 50 - 50 - 50 - 3 * Theme.spacingS
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: "CPU"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        width: 50
                        horizontalAlignment: Text.AlignRight
                    }

                    StyledText {
                        text: "MEM"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        width: 50
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // ── Process list ─────────────────────────
                ListView {
                    id: processList
                    width: parent.width
                    height: Math.min(300, root.memoryProcesses.length * 36)
                    model: root.memoryProcesses
                    clip: true
                    spacing: 0

                    delegate: Rectangle {
                        property var proc: modelData
                        width: parent.width
                        height: 36
                        color: procMouse.containsMouse ? Theme.primaryHoverLight : "transparent"
                        radius: Theme.cornerRadius

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: Theme.spacingS

                            StyledText {
                                width: 50
                                text: String(proc.pid || "")
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                width: parent.width - 50 - 50 - 50 - 3 * Theme.spacingS
                                text: root.processCommand(proc)
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                elide: Text.ElideMiddle
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                width: 50
                                text: (Number(proc.cpu) || 0).toFixed(1) + "%"
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                width: 50
                                text: (Number(proc.mem) || 0).toFixed(1) + "%"
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: procMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }
    popoutWidth: 380
    popoutHeight: 0
}
