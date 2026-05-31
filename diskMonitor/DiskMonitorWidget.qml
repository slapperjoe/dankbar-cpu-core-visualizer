import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets
import QtQuick.Layouts 6.7

PluginComponent {
    id: root

    // ── Properties ─────────────────────────────────────────────
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
        root.popoutTriggerMode = pluginData["popoutTriggerMode"] || "hover";
        root.colorMode = pluginData["colorMode"] || "vivid";
        root.barWidth = Number(pluginData["barWidth"]) || 24;
        root.barGap = Number(pluginData["barGap"]) || 4;
        root.smoothingPercent = Number(pluginData["smoothingPercent"]) || 15;
        root.probeInterval = Number(pluginData["probeInterval"]) || 3000;
        root.probeIntervalMs = Math.max(500, Math.min(30000, root.probeInterval));
        root.smoothingPercent = Math.max(1, Math.min(99, root.smoothingPercent));
        root.barWidth = Math.max(8, Math.min(80, root.barWidth));
        root.barGap = Math.max(1, Math.min(20, root.barGap));
        root.cornerRadius = Math.max(2, Math.min(20, Number(pluginData["cornerRadius"]) || 6));
        var storedPath = pluginData["selectedDiskMountPath"];
        if (storedPath && String(storedPath).length > 0) {
            root.selectedDiskMountPaths = [storedPath];
        } else {
            root.selectedDiskMountPaths = ["/"];
        }

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

    // ── Settings ────────────────────────────────────────────────
    property string popoutTriggerMode: "hover"

    // ── Pill badge ────────────────────────────────────────
    property int _badgeRefresh: 0
    function updateBarBadge() {
        return Math.round(root.diskUsageValue);
    }

    readonly property real barThickness: root.barConfig ? root.barConfig.thickness : 40

    horizontalBarPill: Component {
        MouseArea {
            id: hPillMouseArea
            implicitWidth: hContentRow.implicitWidth
            implicitHeight: hContentRow.implicitHeight
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: root.popoutTriggerMode === "hover"
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.pillRightClickAction()
                } else if (root.popoutTriggerMode === "click") {
                    root.openPopout();
                }
            }
            onEntered: {
                if (root.popoutTriggerMode === "hover") {
                    root.openPopout();
                }
            }

            Row {
                id: hContentRow
                spacing: -6

                DankIcon {
                    name: "harddisk"
                    size: Theme.iconSize - 6
                    color: "#FFFFFF"
                    filled: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    property int _force: root._badgeRefresh
                    visible: _force ? (root.updateBarBadge() > 0) : (root.updateBarBadge() > 0)
                    width: 14
                    height: width
                    radius: width / 2
                    color: Theme.primary
                    border.width: 1
                    border.color: Theme.surfaceContainerHigh

                    StyledText {
                        property int _force: parent._force
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenterOffset: -1
                        anchors.verticalCenterOffset: 1
                        text: String(_force ? root.updateBarBadge() : root.updateBarBadge())
                        color: Theme.surfaceContainerHigh
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        MouseArea {
            id: vPillMouseArea
            implicitWidth: vContentRow.implicitWidth
            implicitHeight: vContentRow.implicitHeight
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: root.popoutTriggerMode === "hover"
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.pillRightClickAction()
                } else if (root.popoutTriggerMode === "click") {
                    root.openPopout();
                }
            }
            onEntered: {
                if (root.popoutTriggerMode === "hover") {
                    root.openPopout();
                }
            }

            Row {
                id: vContentRow
                spacing: -6

                DankIcon {
                    name: "harddisk"
                    size: Theme.iconSize - 6
                    color: "#FFFFFF"
                    filled: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    property int _force: root._badgeRefresh
                    visible: _force ? (root.updateBarBadge() > 0) : (root.updateBarBadge() > 0)
                    width: 14
                    height: width
                    radius: width / 2
                    color: Theme.primary
                    border.width: 1
                    border.color: Theme.surfaceContainerHigh

                    StyledText {
                        property int _force: parent._force
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenterOffset: -1
                        anchors.verticalCenterOffset: 1
                        text: String(_force ? root.updateBarBadge() : root.updateBarBadge())
                        color: Theme.surfaceContainerHigh
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    pillRightClickAction: function(posX, posY, posWidth, sectionName, currentScreen) {
        root.openPopout();
    }

    function openPopout() {
        var popout = null;
        var pill = null;
        for (var i = 0; i < root.children.length; i++) {
            var child = root.children[i];
            if (typeof child.setTriggerPosition === "function") {
                popout = child;
            }
            if (typeof child.mapToItem === "function" && child.width !== undefined && child.width > 0 && typeof child.setTriggerPosition !== "function") {
                pill = child;
            }
        }
        if (popout && pill) {
            var globalPos = pill.mapToItem(null, 0, 0);
            var screen = root.parentScreen || Screen;
            var pos = SettingsData.getPopupTriggerPosition(globalPos, screen, root.barThickness, pill.width, 8, 0, null);
            popout.setTriggerPosition(pos.x, pos.y, pos.width, root.section, screen, 0, root.barThickness, 8, null);
            popout.toggle();
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Disk Monitor"
            detailsText: root.diskUsageTooltipText

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Repeater {
                    model: root.selectedDiskMounts

                    delegate: Row {
                        spacing: 8

                        Rectangle {
                            width: root.barWidth
                            height: 8
                            radius: 4
                            color: root.colorFor(index)

                            Rectangle {
                                anchors.fill: parent
                                anchors.rightMargin: (1 - (root.animatedDiskUsages[index] || 0) / 100) * parent.width
                                width: (root.animatedDiskUsages[index] || 0) / 100 * parent.width
                                height: parent.height
                                radius: 4
                                color: parent.color
                                opacity: 0.96
                            }
                        }

                        StyledText {
                            text: root.diskMountPath(modelData) + ": " + (root.animatedDiskUsages[index] || 0).toFixed(0) + "%"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 360
    popoutHeight: 220
}