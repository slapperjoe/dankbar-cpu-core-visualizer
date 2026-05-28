import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // ── Palettes ──────────────────────────────────────────────────────
    property var vividPalette: ["#ff003c", "#ff4f00", "#ff7a00", "#ffb000", "#ffd400", "#f5ff00", "#c8ff00", "#8dff00", "#53ff00", "#00ff1e", "#00ff6a", "#00ffae", "#00ffd5", "#00e5ff", "#00b3ff", "#0080ff", "#0057ff", "#3040ff", "#5c2dff", "#7d1fff", "#9d00ff", "#c200ff", "#e100ff", "#ff00e1", "#ff00b8", "#ff008f", "#ff0066", "#ff335f", "#ff5c5c", "#ff7f50", "#ff9f1c", "#ffcf33"]
    property var softPalette: ["#ff8aa5", "#ffac7a", "#ffc27a", "#ffd86e", "#fff07a", "#dcff8a", "#b8ff94", "#8eff9d", "#7fffb8", "#7fffd8", "#80f3ff", "#82dcff", "#86c3ff", "#90acff", "#a595ff", "#bc8cff", "#d38bff", "#ea8cff", "#ff8fe8", "#ff93cf", "#ff95b5", "#ff9c9c", "#ffb091", "#ffc188", "#ffd487", "#f1e88f", "#d7f39a", "#bbeea8", "#a6e8bf", "#9be1d4", "#a2d8e6", "#b4cfee"]

    // ── Settings ──────────────────────────────────────────────────────
    property int barWidth: Math.max(2, Math.round(numberSetting("barWidth", 4)))
    property int barGap: Math.max(0, Math.round(numberSetting("barGap", 2)))
    property int maxVisibleCores: Math.max(1, Math.round(numberSetting("maxVisibleCores", 32)))
    property int minBarHeight: Math.max(0, Math.round(numberSetting("minBarHeight", 2)))
    property int animationDuration: Math.max(120, Math.round(numberSetting("animationDuration", 650)))
    property int cornerRadius: Math.max(0, Math.round(numberSetting("cornerRadius", 2)))
    property int probeInterval: Math.max(250, Math.round(numberSetting("probeInterval", 1000)))
    property real smoothingFactor: Math.max(0.08, Math.min(0.85, numberSetting("smoothingPercent", 28) / 100))
    property string rawColorMode: stringSetting("colorMode", "vivid")
    property string colorMode: (root.rawColorMode === "soft" || root.rawColorMode === "mono" || root.rawColorMode === "base") ? "soft" : "vivid"
    property real fillOverlayOpacity: root.colorMode === "soft" ? 0.22 : 0.24
    property bool showOverallPercentage: boolSetting("showOverallPercentage", true)

    // ── State ─────────────────────────────────────────────────────────
    property var rawCoreUsage: Array.isArray(DgopService.perCoreUsage) ? DgopService.perCoreUsage : []
    property var animatedCpuUsage: []
    property bool barHovered: false

    // ── Host detection (DankBar vs desktop widget) ────────────────────
    readonly property bool isDesktopWidget: root.barConfig === undefined || root.barConfig === null
    readonly property string axisEdge: root.axis && root.axis.edge ? String(root.axis.edge) : ""

    // ── Derived ───────────────────────────────────────────────────────
    readonly property real totalCpuUsage: root.clampUsage(Number(DgopService.cpuUsage || 0))
    readonly property int displayedCoreCount: {
        const total = root.rawCoreUsage.length;
        if (total <= 0)
            return 1;
        return Math.min(root.maxVisibleCores, total);
    }

    // ── Shared helpers ──────────────────────────────────────────────────
    function clampUsage(value) {
        if (Number.isNaN(value))
            return 0;
        return Math.max(0, Math.min(100, value));
    }

    function numberSetting(key, fallback) {
        if (pluginData && pluginData[key] !== undefined && pluginData[key] !== null) {
            const value = Number(pluginData[key]);
            if (!Number.isNaN(value))
                return value;
        }
        return fallback;
    }

    function stringSetting(key, fallback) {
        if (pluginData && pluginData[key] !== undefined && pluginData[key] !== null)
            return String(pluginData[key]);
        return fallback;
    }

    function boolSetting(key, fallback) {
        if (pluginData && pluginData[key] !== undefined && pluginData[key] !== null)
            return Boolean(pluginData[key]);
        return fallback;
    }

    function usageFor(index) {
        if (index < 0 || index >= root.rawCoreUsage.length)
            return 0;
        const value = Number(root.rawCoreUsage[index]);
        if (Number.isNaN(value))
            return 0;
        return Math.max(0, Math.min(100, value));
    }

    function colorFor(index) {
        const palette = root.colorMode === "vivid" ? root.vividPalette : root.softPalette;
        return palette[Math.max(0, index) % palette.length];
    }

    function usageLabel(index) {
        const usage = root.usageFor(index);
        if (usage >= 90)
            return "Hottest";
        if (usage >= 70)
            return "High";
        if (usage >= 40)
            return "Moderate";
        if (usage >= 10)
            return "Low";
        return "Idle";
    }

    function hottestCoreIndex() {
        if (root.rawCoreUsage.length <= 0)
            return 0;
        let hottest = 0;
        let maxUsage = -1;
        for (let i = 0; i < root.displayedCoreCount; i++) {
            const usage = root.usageFor(i);
            if (usage > maxUsage) {
                maxUsage = usage;
                hottest = i;
            }
        }
        return hottest;
    }

    function syncUsageValue(current, target, force) {
        if (force || Number.isNaN(current))
            return target;
        const delta = target - current;
        if (Math.abs(delta) < 0.35)
            return target;
        return current + delta * root.smoothingFactor;
    }

    function syncAnimatedUsage(force) {
        let next = root.animatedCpuUsage ? root.animatedCpuUsage.slice() : [];
        const targetLength = root.rawCoreUsage.length;
        for (let i = 0; i < targetLength; i++) {
            const target = root.usageFor(i);
            const current = Number(next[i]);
            next[i] = root.syncUsageValue(current, target, force);
        }
        next.length = targetLength;
        root.animatedCpuUsage = next;
    }

    function cpuRatioFor(index) {
        const usage = root.usageFor(index);
        return usage / 100;
    }

    // ── Tooltip / popout ──────────────────────────────────────────────
    function tooltipText() {
        const hottest = root.hottestCoreIndex();
        const hottestUsage = root.usageFor(hottest).toFixed(0);
        let text = "CPU\nOverall: " + root.totalCpuUsage.toFixed(0) + "%\nHottest: Core " + hottest + " at " + hottestUsage + "%";
        return text;
    }

    function shortSummaryText() {
        let parts = ["CPU"];
        for (let i = 0; i < root.displayedCoreCount; i++) {
            const usage = root.usageFor(i);
            parts.push("C" + i + ": " + usage.toFixed(0) + "%");
        }
        return parts.join("  |  ");
    }

    // ── Lifecycle ──────────────────────────────────────────────────────
    Component.onCompleted: {
        DgopService.addRef(["cpu"]);
        root.syncAnimatedUsage(true);
        DgopService.updateAllStats();
    }
    Component.onDestruction: {
        probeTimer.stop();
        animationTimer.stop();
        DgopService.removeRef(["cpu"]);
    }

    // ── Timers ─────────────────────────────────────────────────────────
    Timer {
        id: probeTimer
        interval: root.probeInterval
        running: true
        repeat: true
        onTriggered: {
            DgopService.updateAllStats();
            root.syncAnimatedUsage(false);
        }
    }

    Timer {
        id: animationTimer
        interval: Math.max(32, root.animationDuration / 16)
        running: true
        repeat: true
        onTriggered: {
            root.syncAnimatedUsage(false);
        }
    }

    // ── Layout ─────────────────────────────────────────────────────────
    // ── DankBar mode ──────────────────────────────────────────────────
    Group {
        visible: !root.isDesktopWidget
        implicitWidth: horizontalBar.implicitWidth
        implicitHeight: root.barThickness || 30

        component horizontalBar: Row {
            spacing: root.barGap
            Repeater {
                model: root.displayedCoreCount
                delegate: Rectangle {
                    width: root.barWidth
                    height: parent.height
                    radius: root.cornerRadius
                    color: root.colorFor(index)
                    opacity: root.fillOverlayOpacity

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "white"
                        opacity: 0.15
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(root.minBarHeight, root.animatedCpuUsage[index] / 100 * parent.height)
                        radius: parent.radius
                        color: parent.color
                        opacity: parent.opacity

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
    }

    // ── Desktop widget mode ───────────────────────────────────────────
    Group {
        visible: root.isDesktopWidget
        implicitWidth: 320
        implicitHeight: 160

        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius
            border.width: 1
            border.color: Theme.outline
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                StyledText {
                    width: parent.width
                    text: "CPU Cores"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                }

                Flow {
                    width: parent.width
                    height: parent.height - 30
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.displayedCoreCount

                        delegate: Rectangle {
                            width: Math.max(100, (parent.width - Theme.spacingS * 2) / 3)
                            height: 48
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Theme.outline
                            clip: true

                            // Fill bar
                            Rectangle {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                width: root.cpuRatioFor(index) * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: root.colorFor(index)
                                opacity: root.fillOverlayOpacity

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            // Dot indicator
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: Theme.widgetTextColor
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.top: parent.top
                                anchors.topMargin: Theme.spacingM
                            }

                            // Core label
                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM + 14
                                anchors.top: parent.top
                                anchors.topMargin: Theme.spacingS
                                text: "Core " + index
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                            }

                            // Usage percentage
                            StyledText {
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingM
                                anchors.top: parent.top
                                anchors.topMargin: Theme.spacingS
                                text: root.usageFor(index).toFixed(0) + "%"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                            }

                            // Usage label
                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Theme.spacingS
                                text: root.usageLabel(index) + (index === root.hottestCoreIndex() ? "  |  hottest" : "")
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall - 1
                            }
                        }
                    }
                }
            }
        }
    }
}
