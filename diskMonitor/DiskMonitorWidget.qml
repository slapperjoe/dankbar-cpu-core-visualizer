import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets
import QtQuick.Layouts 6.7
import io.github.dankmachines.dankmaterialshell.theming 1.0 as Theme

PluginComponent {
    id: root

    // ── Properties ─────────────────────────────────────────────
    property var pluginData: Plugins.PluginStorage
    property bool isDesktopWidget: false

    // Disk settings
    property int barWidth: 24
    property int barGap: 4
    property int cornerRadius: 6
    property string colorMode: "vivid"
    property int smoothingPercent: 15
    property int probeInterval: 3000
    property var selectedDiskMountPaths: []

    readonly property real smoothingFactor: Math.pow(0.5, smoothingPercent / 100.0)
    readonly property real animationDuration: 120
    readonly property real fillOverlayOpacity: 0.96
    readonly property real sectionGap: barGap
    readonly property real padding: 12

    readonly property var diskMountList: Array.isArray(DgopService.diskMounts) ? DgopService.diskMounts : []
    readonly property var selectedDiskMounts: {
        let exactMatches = [];
        let fallback = [];
        for (let i = 0; i < root.diskMountList.length; i++) {
            const mount = root.diskMountList[i];
            const mountPath = root.diskMountPath(mount);
            if (!mountPath || !root.diskMountHasUsage(mount))
                continue;

            if (root.selectedDiskMountPaths.indexOf(mountPath) !== -1) {
                exactMatches.push(mount);
            } else {
                fallback.push(mount);
            }
        }
        return exactMatches.length > 0 ? exactMatches : fallback;
    }

    readonly property string diskSelectionLabel: {
        if (root.selectedDiskMounts.length <= 0)
            return "Waiting for disk stats";
        let labels = [];
        for (let i = 0; i < root.selectedDiskMounts.length; i++)
            labels.push(root.diskMountPath(root.selectedDiskMounts[i]));
        return labels.join(", ");
    }

    readonly property real diskUsageValue: {
        if (root.selectedDiskMounts.length <= 0)
            return 0;
        let weightedUsed = 0;
        let weightedTotal = 0;
        for (let i = 0; i < root.selectedDiskMounts.length; i++) {
            const mount = root.selectedDiskMounts[i];
            const total = Number(mount && mount.total !== undefined ? mount.total : 0);
            const used = Number(mount && mount.used !== undefined ? mount.used : 0);
            weightedUsed += used;
            weightedTotal += total;
        }
        if (weightedTotal <= 0)
            return 0;
        return (weightedUsed / weightedTotal) * 100;
    }

    readonly property string diskUsageSubtitle: {
        if (root.selectedDiskMounts.length <= 0)
            return "Waiting for disk stats";
        if (root.selectedDiskMounts.length === 1) {
            const mount = root.selectedDiskMounts[0];
            const total = Number(mount && mount.total !== undefined ? mount.total : 0);
            if (total > 0)
                return root.diskMountPath(mount) + "  " + root.formatStorage(mount.used) + " / " + root.formatStorage(total);
        }
        return root.diskSelectionLabel;
    }

    readonly property string diskUsageTooltipText: {
        if (root.selectedDiskMounts.length <= 0)
            return "Waiting for disk stats";
        let parts = [];
        for (let i = 0; i < root.selectedDiskMounts.length; i++) {
            const mount = root.selectedDiskMounts[i];
            let part = root.diskMountPath(mount) + " " + root.diskMountPercent(mount).toFixed(0) + "%";
            const total = Number(mount && mount.total !== undefined ? mount.total : 0);
            if (total > 0)
                part += "  |  " + root.formatStorage(mount.used) + " / " + root.formatStorage(total);
            parts.push(part);
        }
        return parts.join("   ");
    }

    // Animated disk usages
    property var animatedDiskUsages: []

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

    // Timers
    Timer {
        id: animationTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: root.syncAnimatedDiskUsage(true)
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
        root.barWidth = root.pluginData.numberSetting("barWidth", 24);
        root.barGap = root.pluginData.numberSetting("barGap", 4);
        root.smoothingPercent = root.pluginData.numberSetting("smoothingPercent", 15);
        root.probeInterval = root.pluginData.numberSetting("probeInterval", 3000);
        root.probeIntervalMs = Math.max(500, Math.min(30000, root.probeInterval));
        root.smoothingPercent = Math.max(1, Math.min(99, root.smoothingPercent));
        root.barWidth = Math.max(8, Math.min(80, root.barWidth));
        root.barGap = Math.max(1, Math.min(20, root.barGap));
        root.cornerRadius = Math.max(2, Math.min(20, root.pluginData.numberSetting("cornerRadius", 6)));
        root.selectedDiskMountPaths = root.pluginData.arraySetting("selectedDiskMountPaths", ["/"]);

        DgopService.addRef(["diskmounts"]);
        root.syncAnimatedDiskUsage(true);
    }

    Component.onDestruction: {
        DgopService.removeRef(["diskmounts"]);
    }

    // ── Functions ──────────────────────────────────────────────
    function clampUsage(value) {
        return Math.max(0, Math.min(100, Number(value) || 0));
    }

    function diskMountPath(mount) {
        if (!mount)
            return "";
        return String(mount.path || mount.device || "");
    }

    function diskMountPercent(mount) {
        if (!mount)
            return 0;
        const total = Number(mount.total || 0);
        const used = Number(mount.used || 0);
        if (total <= 0)
            return 0;
        return (used / total) * 100;
    }

    function diskMountHasUsage(mount) {
        if (!mount)
            return false;
        return (mount.total !== undefined && mount.total > 0);
    }

    function formatStorage(bytes) {
        if (bytes === undefined || bytes === null)
            return "0 B";
        const val = Number(bytes);
        if (val >= 1024 * 1024 * 1024)
            return (val / (1024 * 1024 * 1024)).toFixed(1) + " TB";
        if (val >= 1024 * 1024)
            return (val / (1024 * 1024)).toFixed(1) + " GB";
        if (val >= 1024)
            return (val / 1024).toFixed(1) + " MB";
        return Math.round(val) + " B";
    }

    function syncUsageValue(current, target, force) {
        if (force || Number.isNaN(current))
            return target;
        const delta = target - current;
        if (Math.abs(delta) < 0.35)
            return target;
        return current + delta * root.smoothingFactor;
    }

    function syncAnimatedDiskUsage(force) {
        let next = root.animatedDiskUsages ? root.animatedDiskUsages.slice() : [];
        const diskCount = root.selectedDiskMounts.length;
        for (let d = 0; d < diskCount; d++) {
            const diskTarget = root.diskMountUsageFor(d);
            const diskCurrent = Number(next[d]);
            next[d] = root.syncUsageValue(diskCurrent, diskTarget, force);
        }
        next.length = diskCount;
        root.animatedDiskUsages = next;
    }

    function diskMountUsageFor(index) {
        if (index < 0 || index >= root.selectedDiskMounts.length)
            return 0;
        return root.clampUsage(root.diskMountPercent(root.selectedDiskMounts[index]));
    }

    function colorFor(index) {
        if (root.colorMode === "soft")
            return root.softPalette[(index * 7 + 3) % root.softPalette.length];
        return root.vividPalette[(index * 7 + 3) % root.vividPalette.length];
    }

    function cardFillWidth(index, cardWidth) {
        const usage = root.animatedDiskUsages[index] || 0;
        return (root.clampUsage(usage) / 100) * cardWidth;
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

        width: root.isDesktopWidget ? 480 : (root.barConfig ? root.barConfig.widgetWidth || 480 : 480)
        height: root.isDesktopWidget ? 200 : (root.barConfig ? root.barThickness || 40 : 200)

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

                // Header
                Row {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "storage"
                        size: Theme.iconSize
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Disk Monitor"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                    }
                }

                // Disk bars
                Row {
                    id: diskBars
                    Layout.fillWidth: true
                    spacing: root.barGap

                    Repeater {
                        model: root.selectedDiskMounts

                        delegate: Rectangle {
                            width: root.barWidth
                            height: 120
                            radius: root.cornerRadius
                            color: Theme.surfaceContainerHigh
                            clip: true

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: parent.width
                                height: Math.max(2, (root.animatedDiskUsages[index] || 0) / 100 * parent.height)
                                radius: root.cornerRadius
                                color: root.colorFor(index)
                                opacity: root.fillOverlayOpacity

                                Behavior on height {
                                    NumberAnimation {
                                        duration: root.animationDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }
                }

                // Disk labels
                Row {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.selectedDiskMounts

                        delegate: Column {
                            spacing: 2

                            StyledText {
                                text: root.diskMountPath(modelData) || "Unknown"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: root.diskMountUsageFor(index).toFixed(0) + "%"
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall - 1
                            }
                        }
                    }
                }

                // Disk detail
                StyledText {
                    Layout.fillWidth: true
                    text: root.diskUsageTooltipText
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall - 1
                    wrapMode: Text.WordWrap
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

                Repeater {
                    model: root.selectedDiskMounts

                    delegate: Item {
                        width: root.barWidth
                        height: parent.height

                        Rectangle {
                            width: parent.width
                            height: root.verticalHeightFor(index, parent.height)
                            anchors.bottom: parent.bottom
                            radius: Math.min(root.cornerRadius, width / 2)
                            color: root.colorFor(index)
                            opacity: root.fillOverlayOpacity

                            Behavior on height {
                                NumberAnimation {
                                    duration: root.animationDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    visible: true

                    DankIcon {
                        name: "storage"
                        size: Theme.iconSize
                        color: Theme.widgetTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: metricLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.diskUsageValue.toFixed(0) + "%"
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

    function verticalHeightFor(index, totalHeight) {
        const usage = root.animatedDiskUsages[index] || 0;
        return Math.max(2, root.clampUsage(usage) / 100 * totalHeight);
    }
}
