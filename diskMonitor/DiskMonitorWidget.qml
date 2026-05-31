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
        // Use percent directly from dgop output
        let totalPercent = 0;
        let count = 0;
        for (let i = 0; i < root.selectedDiskMounts.length; i++) {
            const mount = root.selectedDiskMounts[i];
            const p = root.diskMountPercent(mount);
            if (p >= 0) {
                totalPercent += p;
                count++;
            }
        }
        if (count <= 0)
            return 0;
        return totalPercent / root.selectedDiskMounts.length;
    }

    readonly property string diskUsageSubtitle: {
        if (root.selectedDiskMounts.length <= 0)
            return "Waiting for disk stats";
        if (root.selectedDiskMounts.length === 1) {
            const mount = root.selectedDiskMounts[0];
            const percent = root.diskMountPercent(mount);
            return root.diskMountPath(mount) + " " + percent.toFixed(0) + "%";
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
            part += "  |  " + (mount.used || "0") + " / " + (mount.size || "0");
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
        onTriggered: {
            DgopService.updateAllStats();
            root.syncAnimatedDiskUsage(false);
        }
    }

    property int probeIntervalMs: probeInterval

    Component.onCompleted: {
        root.isDesktopWidget = (root.barConfig === undefined || root.barConfig === null);
        root._applyPluginData();
        DgopService.addRef(["cpu", "memory", "disk", "processes", "network", "gpu"]);
        DgopService.updateAllStats();
        root.syncAnimatedDiskUsage(true);
        root._badgeRefresh += 1;
    }

    Component.onDestruction: {
        DgopService.removeRef(["cpu", "memory", "disk", "processes", "network", "gpu"]);
    }

    // Re-apply settings when pluginData changes (e.g., user changes settings)
    onPluginDataChanged: root._applyPluginData()

    function _applyPluginData() {
        root.colorMode = pluginData["colorMode"] || "vivid";
        root.barWidth = Math.max(8, Math.min(80, Number(pluginData["barWidth"]) || 24));
        root.barGap = Math.max(1, Math.min(20, Number(pluginData["barGap"]) || 4));
        root.smoothingPercent = Math.max(1, Math.min(99, Number(pluginData["smoothingPercent"]) || 15));
        root.cornerRadius = Math.max(2, Math.min(20, Number(pluginData["cornerRadius"]) || 6));
        root.probeInterval = Math.max(500, Math.min(30000, Number(pluginData["probeInterval"]) || 3000));
        root.probeIntervalMs = root.probeInterval;
        root.popoutTriggerMode = pluginData["popoutTriggerMode"] || "click";
        var storedPaths = pluginData["selectedDiskMountPaths"];
        if (Array.isArray(storedPaths) && storedPaths.length > 0) {
            // Clean up invalid paths like "//", "///", etc.
            var validPaths = storedPaths.filter(function(p) {
                if (!p || p.trim().length === 0) return false;
                // Reject paths with multiple consecutive slashes (artifacts of the old bug)
                if (p.indexOf("//") !== -1) return false;
                return true;
            });
            root.selectedDiskMountPaths = validPaths.length > 0 ? validPaths : ["/"];
        } else {
            root.selectedDiskMountPaths = ["/"];
        }
    }

    // ── Functions ──────────────────────────────────────────────
    function clampUsage(value) {
        return Math.max(0, Math.min(100, Number(value) || 0));
    }

    function diskMountPath(mount) {
        if (!mount)
            return "";
        // dgop returns {device, mount, fstype, size, used, avail, percent}
        if (mount.mount !== undefined && mount.mount !== null && String(mount.mount).length > 0)
            return String(mount.mount);
        return String(mount.device || "");
    }

    function diskMountPercent(mount) {
        if (!mount)
            return 0;
        // dgop provides percent as "9%" - parse directly
        if (mount.percent !== undefined && mount.percent !== null) {
            const parsed = Number(String(mount.percent).replace("%", ""));
            if (!Number.isNaN(parsed))
                return parsed;
        }
        // Fallback: compute from size/used (these are strings like "429.3G")
        const total = root.parseStorage(mount.size);
        const used = root.parseStorage(mount.used);
        if (total > 0)
            return (used / total) * 100;
        return 0;
    }

    function diskMountHasUsage(mount) {
        if (!mount)
            return false;
        // dgop may provide percent, or just size/used
        if (mount.percent !== undefined && mount.percent !== null)
            return true;
        // Fallback: if size or used is present, consider it valid
        if (mount.size || mount.used)
            return true;
        return false;
    }

    function parseStorage(str) {
        if (!str || typeof str !== "string")
            return 0;
        const match = str.match(/^([\d.]+)([A-Z])$/);
        if (!match)
            return 0;
        const num = parseFloat(match[1]);
        const unit = match[2].toUpperCase();
        const multipliers = { "B": 1, "K": 1024, "M": 1024*1024, "G": 1024*1024*1024, "T": 1024*1024*1024*1024 };
        return num * (multipliers[unit] || 1);
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

    // ── Reactive handlers ─────────────────────────────────
    onSelectedDiskMountsChanged: {
        root.syncAnimatedDiskUsage(root.animatedDiskUsages.length !== root.selectedDiskMounts.length);
    }

    // ── Popout trigger setting ────────────────────────────
    property string popoutTriggerMode: "click"

    // ── Pill badge ────────────────────────────────────────
    property int _badgeRefresh: 0
    function updateBarBadge() {
        return Math.round(root.diskUsageValue);
    }

    horizontalBarPill: Component {
        MouseArea {
            id: hMouseArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Size to fit content + padding
            implicitWidth: hContentRow.implicitWidth + 24
            implicitHeight: root.barThickness

            onEntered: {
                if (root.popoutTriggerMode === "hover")
                    root.openPopout();
            }

            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    root.pillRightClickAction();
                } else if (root.popoutTriggerMode === "click") {
                    root.openPopout();
                }
            }

            Row {
                id: hContentRow
                anchors.centerIn: parent
                spacing: -6

                DankIcon {
                    name: "storage"
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
            id: vMouseArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            implicitWidth: vContentRow.implicitWidth + 24
            implicitHeight: root.barThickness

            onEntered: {
                if (root.popoutTriggerMode === "hover")
                    root.openPopout();
            }

            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    root.pillRightClickAction();
                } else if (root.popoutTriggerMode === "click") {
                    root.openPopout();
                }
            }

            Row {
                id: vContentRow
                anchors.centerIn: parent
                spacing: -6

                DankIcon {
                    name: "storage"
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

    // ── Popout triggers ────────────────────────────────
    pillClickAction: function() {
        if (root.popoutTriggerMode === "click") {
            root.openPopout();
        }
    }

    pillRightClickAction: function() {
        root.openPopout();
    }

    property var _popoutInstance: null

    function openPopout() {
        // Use PluginComponent's showPopout if available
        if (typeof root.showPopout === "function") {
            root.showPopout(root.popoutContent);
        } else if (!root._popoutInstance || !root._popoutInstance.visible) {
            var popout = root.popoutContent.createObject(root, {"parent": root});
            if (popout) {
                root._popoutInstance = popout;
                popout.show();
            }
        } else {
            root._popoutInstance.toggle();
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Disk Monitor"
            detailsText: root.diskUsageTooltipText
            showCloseButton: false

            Column {
                width: parent.width
                anchors.margins: 8
                spacing: Theme.spacingM

                Repeater {
                    model: root.selectedDiskMounts

                    delegate: Rectangle {
                        width: parent.width
                        height: 44
                        radius: Theme.cornerRadius
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            // Bar background
                            Rectangle {
                                width: parent.width - 120
                                height: 10
                                radius: 5
                                color: Theme.withAlpha(Theme.surfaceVariant, Theme.popupTransparency)

                                // Bar fill
                                Rectangle {
                                    width: (root.animatedDiskUsages[index] || 0) / 100 * parent.width
                                    height: parent.height
                                    radius: 5
                                    color: root.colorFor(index)
                                    opacity: 0.96
                                }
                            }

                            StyledText {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.diskMountPath(modelData) + "  " + (root.animatedDiskUsages[index] || 0).toFixed(0) + "%"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    text: "Waiting for disk stats"
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignCenter
                    visible: root.selectedDiskMounts.length === 0
                }
            }
        }
    }

    popoutWidth: 360
    popoutHeight: 0
}