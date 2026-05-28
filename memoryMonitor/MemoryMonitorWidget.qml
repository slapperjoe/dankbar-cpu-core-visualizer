import Qt 6.7
import QtQuick 2.15
import QtQuick.Layouts 6.7
import io.github.dankmachines.dankmaterialshell.theming 1.0 as Theme
import io.github.dankmachines.dankmaterialshell.plugins 1.0 as DankPlugins

PluginComponent {
    id: root

    // ── Properties ─────────────────────────────────────────────
    property var pluginData: DankPlugins.PluginStorage
    property bool isDesktopWidget: false

    // Memory settings
    property int barWidth: 48
    property int barGap: 4
    property int cornerRadius: 6
    property string colorMode: "vivid"
    property int smoothingPercent: 15
    property int probeInterval: 3000
    property int sectionPadding: 12

    // Process listing state
    property string memoryProcessFilter: "all"
    property string memoryProcessSearchText: ""
    property string processSortKey: "memory"
    property bool processSortAscending: false
    property bool pauseMemoryProcessUpdates: false

    readonly property real smoothingFactor: Math.pow(0.5, smoothingPercent / 100.0)
    readonly property real animationDuration: 120
    readonly property real fillOverlayOpacity: 0.96
    readonly property real sectionGap: barGap
    readonly property real padding: sectionPadding
    readonly property real memoryUsageValue: root.clampUsage(Number(DgopService.memoryUsage || 0))

    // Animated memory usage
    property real animatedMemoryUsage: 0

    // Palettes
    property var vividPalette: [
        "#FF2D2D", "#FF6D2D", "#FFB02D", "#2DFF2D", "#2DFFD4", "#2DD4FF",
        "#5C2DFF", "#D42DFF", "#FF2DC4", "#FF8C2D", "#8CFF2D", "#2DB4FF",
        "#B42DFF", "#FF2D8C", "#2DFF8C", "#FFD42D", "#2D8CFF", "#D42D8C",
        "#8C2DFF", "#2DFFB4", "#FF4D2D", "#4DFF2D", "#2DFFB4", "#4D2DFF",
        "#FF2D6D", "#6DFF2D", "#2DB4D4", "#D42DB4", "#B42DFF", "#FF6D2D",
        "#2DD4B4", "#6D2DFF"
    ]
    property var softPalette: [
        "#EF9A9A", "#EFB39A", "#EFCB9A", "#9AEF9A", "#9AEFDF", "#9ADCEF",
        "#A09AEF", "#DFAE9A", "#EF9AC4", "#EFAC9A", "#ACEF9A", "#9ABAEF",
        "#B09AEE", "#EF9AAC", "#9AEFAC", "#EFD49A", "#9A9BEE", "#AA9AEF",
        "#9AEEB0", "#EFACAA", "#ACEFAA", "#9AEFCB", "#AA9AEE", "#EF9AB0",
        "#AC9AEF", "#9AEFBC", "#DFAA9A", "#B09ADE"
    ]

    readonly property var memoryProcesses: Array.isArray(DgopService.memoryProcesses) ? DgopService.memoryProcesses : []

    readonly property var filteredMemoryProcesses: {
        const procs = root.memoryProcesses;
        if (!Array.isArray(procs) || procs.length === 0)
            return [];

        let filtered = [];
        for (let i = 0; i < procs.length; i++) {
            const proc = procs[i];
            if (!proc)
                continue;

            if (root.memoryProcessFilter === "user" && proc.user) {
                if (String(proc.user).toLowerCase() !== QSysInfo.machineHostName())
                    continue;
            }

            if (root.memoryProcessSearchText.length > 0) {
                const cmd = String(proc.command || "");
                const fullCmd = String(proc.fullCommand || "");
                const search = root.memoryProcessSearchText.toLowerCase();
                if (cmd.toLowerCase().indexOf(search) === -1 && fullCmd.toLowerCase().indexOf(search) === -1)
                    continue;
            }
            filtered.push(proc);
        }
        return filtered;
    }

    property var cachedMemoryProcesses: []
    onFilteredMemoryProcessesChanged: {
        if (!root.pauseMemoryProcessUpdates)
            root.cachedMemoryProcesses = root.filteredMemoryProcesses;
    }
    onPauseMemoryProcessUpdatesChanged: {
        if (!root.pauseMemoryProcessUpdates)
            root.cachedMemoryProcesses = root.filteredMemoryProcesses;
    }
    onMemoryProcessSearchTextChanged: root.cachedMemoryProcesses = root.filteredMemoryProcesses
    onMemoryProcessFilterChanged: root.cachedMemoryProcesses = root.filteredMemoryProcesses
    onProcessSortKeyChanged: root.cachedMemoryProcesses = root.filteredMemoryProcesses
    onProcessSortAscendingChanged: root.cachedMemoryProcesses = root.filteredMemoryProcesses

    readonly property var sortedMemoryProcesses: {
        const procs = Array.isArray(root.cachedMemoryProcesses) ? root.cachedMemoryProcesses.slice() : [];
        const asc = root.processSortAscending;

        procs.sort((left, right) => {
            let result = 0;
            switch (root.processSortKey) {
                case "cpu":
                    result = (Number(right.cpu) || 0) - (Number(left.cpu) || 0);
                    break;
                case "memory":
                    result = (Number(right.memoryKB) || 0) - (Number(left.memoryKB) || 0);
                    break;
                case "pid":
                    result = (Number(left.pid) || 0) - (Number(right.pid) || 0);
                    break;
                default:
                    const cmdL = String(left && left.command || "").toLowerCase();
                    const cmdR = String(right && right.command || "").toLowerCase();
                    result = cmdL.localeCompare(cmdR);
                    break;
            }
            return asc ? result : -result;
        });
        return procs;
    }

    // Timers
    Timer {
        id: animationTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: root.syncAnimatedMemoryUsage(true)
    }

    Timer {
        id: probeTimer
        interval: root.probeIntervalMs
        running: true
        repeat: true
        onTriggered: DgopService.updateAllStats()
    }

    property int probeIntervalMs: probeInterval

    Component.onCompleted: {
        root.isDesktopWidget = (root.barConfig === undefined || root.barConfig === null);
        root.colorMode = root.pluginData.stringSetting("colorMode", "vivid");
        root.barWidth = root.pluginData.numberSetting("barWidth", 48);
        root.barGap = root.pluginData.numberSetting("barGap", 4);
        root.smoothingPercent = root.pluginData.numberSetting("smoothingPercent", 15);
        root.probeInterval = root.pluginData.numberSetting("probeInterval", 3000);
        root.probeIntervalMs = Math.max(500, Math.min(30000, root.probeInterval));
        root.smoothingPercent = Math.max(1, Math.min(99, root.smoothingPercent));
        root.barWidth = Math.max(8, Math.min(80, root.barWidth));
        root.barGap = Math.max(1, Math.min(20, root.barGap);
        root.cornerRadius = Math.max(2, Math.min(20, root.pluginData.numberSetting("cornerRadius", 6));

        DgopService.addRef(["memory", "processes"]);
        root.syncAnimatedMemoryUsage(true);
    }

    Component.onDestruction: {
        DgopService.removeRef(["memory", "processes"]);
    }

    // ── Functions ──────────────────────────────────────────────
    function clampUsage(value) {
        return Math.max(0, Math.min(100, Number(value) || 0);
    }

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

    function colorFor(index) {
        if (root.colorMode === "soft")
            return root.softPalette[index % root.softPalette.length];
        return root.vividPalette[index % root.vividPalette.length];
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

    function processFullCommand(proc) {
        return String(proc && (proc.fullCommand || proc.command) || "");
    }

    function overallTextSize() {
        const fontScale = root.barConfig ? root.barConfig.fontScale : undefined;
        const maximizeText = root.barConfig ? root.barConfig.maximizeWidgetText : undefined;
        return Theme.barTextSize(root.barThickness, fontScale, maximizeText);
    }

    readonly property real barThickness: root.barConfig ? root.barConfig.thickness : 40
    readonly property real widgetThickness: root.barConfig ? root.barThickness : 160

    // ── Layout ────────────────────────────────────────────────
    Item {
        id: container

        width: root.isDesktopWidget ? 500 : (root.barConfig ? root.barConfig.widgetWidth || 500 : 500)
        height: root.isDesktopWidget ? 400 : (root.barConfig ? root.barThickness || 40 : 400)

        // Desktop widget
        visible: root.isDesktopWidget
        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.width: 1
            border.color: Theme.outline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                // Memory usage card
                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outline
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        radius: Theme.cornerRadius - 2
                        color: Theme.surfaceContainer
                        height: parent.height - Theme.spacingM * 2
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: parent.width - Theme.spacingM * 2

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            spacing: Theme.spacingXS

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "sd_card"
                                    size: Theme.iconSize
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: "Memory"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: root.animatedMemoryUsage.toFixed(0) + "%"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
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
                                    color: root.colorFor(0)
                                    opacity: root.fillOverlayOpacity

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: root.animationDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            StyledText {
                                width: parent.width
                                text: {
                                    const total = Number(DgopService.totalMemoryKB || 0);
                                    if (total <= 0)
                                        return "Waiting for memory stats";
                                    return DgopService.formatSystemMemory(DgopService.usedMemoryKB) + " used  /  " + DgopService.formatSystemMemory(total) + " total";
                                }
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }
                    }
                }

                // Process list
                Column {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS

                        TextMetrics {
                            id: pidColumnMetrics
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            text: "PID"
                        }

                        TextMetrics {
                            id: cpuColumnMetrics
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            text: "CPU %"
                        }

                        TextMetrics {
                            id: memColumnMetrics
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            text: "MEM %"
                        }
                    }

                    ListView {
                        id: processList
                        width: parent.width
                        Layout.fillHeight: true
                        model: root.sortedMemoryProcesses
                        delegate: Rectangle {
                            width: parent.width
                            height: 56
                            radius: Theme.cornerRadius
                            color: processMouse.containsMouse ? Theme.primaryHoverLight : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingS
                                spacing: Theme.spacingS

                                StyledText {
                                    width: Math.ceil(pidColumnMetrics.advanceWidth)
                                    text: String(modelData.pid || "")
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.processCommand(modelData)
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    elide: Text.ElideMiddle
                                }

                                StyledText {
                                    width: Math.ceil(cpuColumnMetrics.advanceWidth)
                                    text: (modelData.cpu || 0).toFixed(1) + "%"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    horizontalAlignment: Text.AlignRight
                                }

                                StyledText {
                                    width: Math.ceil(memColumnMetrics.advanceWidth)
                                    text: (modelData.mem || 0).toFixed(1) + "%"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    horizontalAlignment: Text.AlignRight
                                }

                                MouseArea {
                                    id: processMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }
        }

        // DankBar widget
        visible: !root.isDesktopWidget
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Row {
                anchors.fill: parent
                anchors.margins: root.padding
                spacing: root.barGap

                Rectangle {
                    width: root.barWidth
                    height: parent.height
                    radius: Math.min(root.cornerRadius, width / 2)
                    color: Theme.surfaceContainerHigh
                    clip: true

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width
                        height: Math.max(2, root.animatedMemoryUsage / 100 * parent.height)
                        radius: Math.min(root.cornerRadius, width / 2)
                        color: root.colorFor(0)
                        opacity: root.fillOverlayOpacity

                        Behavior on height {
                            NumberAnimation {
                                duration: root.animationDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    visible: true

                    DankIcon {
                        name: "sd_card"
                        size: Theme.iconSize
                        color: Theme.widgetTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: metricLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.animatedMemoryUsage.toFixed(0) + "%"
                        color: Theme.widgetTextColor
                        font.pixelSize: root.overallTextSize()
                        font.weight: Font.Medium
                    }
                }
            }

            HoverHandler {
                onHoveredChanged: {
                    root.barHovered = hovered;
                }
            }
        }
    }
}
