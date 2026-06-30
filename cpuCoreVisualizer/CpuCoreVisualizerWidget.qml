import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // ── Palettes ──────────────────────────────────────────────────────
    property var vividPalette: ["#ff003c", "#ff4f00", "#ff7a00", "#ffb000", "#ffd400", "#f5ff00", "#c8ff00", "#8dff00", "#53ff00", "#00ff1e", "#00ff6a", "#00ffae", "#00ffd5", "#00e5ff", "#00b3ff", "#0080ff", "#0057ff", "#3040ff", "#5c2dff", "#7d1fff", "#9d00ff", "#c200ff", "#e100ff", "#ff00e1", "#ff00b8", "#ff008f", "#ff0066", "#ff335f", "#ff5c5c", "#ff7f50", "#ff9f1c", "#ffcf33"]
    property var softPalette: ["#ff8aa5", "#ffac7a", "#ffc27a", "#ffd86e", "#fff07a", "#dcff8a", "#b8ff94", "#8eff9d", "#7fffb8", "#7fffd8", "#80f3ff", "#82dcff", "#86c3ff", "#90acff", "#a595ff", "#bc8cff", "#d38bff", "#ea8cff", "#ff8fe8", "#ff93cf", "#ff95b5", "#ff9c9c", "#ffb091", "#ffc188", "#ffd487", "#f1e88f", "#d7f39a", "#bbeea8", "#a6e8bf", "#9be1d4", "#a2d8e6", "#b4cfee"]

    // ── Settings (loaded once at startup) ─────────────────────────────
    property int barWidth: 4
    property int barGap: 2
    property int barPadding: 4
    property int maxVisibleCores: 32
    property int minBarHeight: 2
    property int cornerRadius: 2
    property int probeInterval: 1000
    property real smoothingFactor: 0.28
    property string colorMode: "vivid"
    property bool showOverallPercentage: true
    property real fillOverlayOpacity: 0.24
    property int _colorVersion: 0

    // ── State ─────────────────────────────────────────────────────────
    readonly property var rawCoreUsage: {
        const perCore = DgopService.perCoreCpuUsage;
        if (Array.isArray(perCore) && perCore.length > 0)
            return perCore;
        return [DgopService.cpuUsage || 0];
    }
    property var animatedCpuUsage: []
    property var targetCoreUsage: []  // snapshot target, updated at probe time

    // ── Derived ───────────────────────────────────────────────────────
    readonly property real totalCpuUsage: root.clampUsage(Number(DgopService.cpuUsage || 0))
    readonly property int displayedCoreCount: {
        const total = root.rawCoreUsage.length;
        if (total <= 0)
            return 1;
        return Math.min(root.maxVisibleCores, total);
    }

    // ── Helpers ───────────────────────────────────────────────────────
    function clampUsage(value) {
        if (Number.isNaN(value))
            return 0;
        return Math.max(0, Math.min(100, value));
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
        if (usage >= 90) return "Hottest";
        if (usage >= 70) return "High";
        if (usage >= 40) return "Moderate";
        if (usage >= 10) return "Low";
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
        const targets = root.targetCoreUsage;
        const targetLength = targets.length || root.rawCoreUsage.length;
        for (let i = 0; i < targetLength; i++) {
            const target = i < targets.length ? root.clampUsage(Number(targets[i] || 0)) : root.usageFor(i);
            const current = Number(next[i]);
            next[i] = root.syncUsageValue(current, target, force);
        }
        next.length = targetLength;
        root.animatedCpuUsage = next;
    }

    // ── Tooltip / summary ─────────────────────────────────────────────
    function tooltipText() {
        const hottest = root.hottestCoreIndex();
        const hottestUsage = root.usageFor(hottest).toFixed(0);
        return "CPU\nOverall: " + root.displayCpuUsage.toFixed(0) + "%\nHottest: Core " + hottest + " at " + hottestUsage + "%";
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
        root.barWidth = Math.max(2, Math.round(pluginData["barWidth"] !== undefined ? pluginData["barWidth"] : 4));
        root.barGap = Math.max(0, Math.round(pluginData["barGap"] !== undefined ? pluginData["barGap"] : 2));
        root.barPadding = Math.max(0, Math.round(pluginData["barPadding"] !== undefined ? pluginData["barPadding"] : 4));
        root.maxVisibleCores = Math.max(1, Math.round(pluginData["maxVisibleCores"] !== undefined ? pluginData["maxVisibleCores"] : 32));
        root.minBarHeight = Math.max(0, Math.round(pluginData["minBarHeight"] !== undefined ? pluginData["minBarHeight"] : 2));
        root.cornerRadius = Math.max(0, Math.round(pluginData["cornerRadius"] !== undefined ? pluginData["cornerRadius"] : 2));
        root.probeInterval = Math.max(250, Math.min(5000, Math.round(pluginData["probeInterval"] !== undefined ? pluginData["probeInterval"] : 1000)));
        root.smoothingFactor = Math.max(0.08, Math.min(0.85, ((pluginData["smoothingPercent"] !== undefined ? pluginData["smoothingPercent"] : 28) / 100)));
        root.colorMode = (pluginData["colorMode"] === "soft") ? "soft" : "vivid";
        root.fillOverlayOpacity = (Number(pluginData["barOpacity"]) || (root.colorMode === "soft" ? 22 : 24)) / 100;
        root.showOverallPercentage = pluginData["showOverallPercentage"] !== false;
        DgopService.addRef(["cpu"]);
        root.targetCoreUsage = root.rawCoreUsage.slice();
        root.displayCpuUsage = root.clampUsage(Number(DgopService.cpuUsage || 0));
        root.syncAnimatedUsage(true);
        DgopService.updateAllStats();
    }
    Component.onDestruction: {
        probeTimer.stop();
        animationTimer.stop();
        settingsPoller.stop();
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
            root.targetCoreUsage = root.rawCoreUsage.slice();
            root.displayCpuUsage = root.clampUsage(Number(DgopService.cpuUsage || 0));
            root.syncAnimatedUsage(false);
        }
    }

    Timer {
        id: animationTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            root.syncAnimatedUsage(false);
        }
    }

    Timer {
        id: settingsPoller
        interval: 250
        running: true
        repeat: true
        onTriggered: root.reloadSettings()
    }

    function reloadSettings() {
        var p = function(key, def) {
            var v = pluginData[key];
            if (v !== undefined && v !== null) return v;
            if (typeof root.loadValue === "function") return root.loadValue(key, def);
            return def;
        };
        root.probeInterval = Math.max(250, Math.min(5000, Math.round(p("probeInterval", 1000))));
        root.smoothingFactor = Math.max(0.08, Math.min(0.85, (p("smoothingPercent", 28) / 100)));
        root.colorMode = (p("colorMode", "vivid") === "soft") ? "soft" : "vivid";
        root.fillOverlayOpacity = (Number(p("barOpacity", root.colorMode === "soft" ? 22 : 24)) / 100);
        root.showOverallPercentage = p("showOverallPercentage", true) !== false;
        root._colorVersion += 1;
    }

    // ── Display values (snapshotted, not live) ────────────────────────
    property real displayCpuUsage: 0  // snapshot of totalCpuUsage for stable display
    TextMetrics {
        id: cpuPercentMetrics
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Bold
        text: "100%"  // worst-case width
    }

    // ── Horizontal bar pill ───────────────────────────────────────────
    horizontalBarPill: Component {
        Item {
            id: hPillMouse
            implicitWidth: hContentRow.implicitWidth + 24
            implicitHeight: root.barThickness

            Row {
                id: hContentRow
                spacing: root.barGap
                y: root.barPadding + 5
                height: Math.max(root.minBarHeight, root.barThickness - (root.barPadding + 5) * 2)
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: root.displayedCoreCount
                    delegate: Item {
                        property int _vc: root._colorVersion
                        width: root.barWidth
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            radius: root.cornerRadius
                            color: { _vc; root.colorFor(index); }
                            opacity: { _vc; root.fillOverlayOpacity; }
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(root.minBarHeight, (root.animatedCpuUsage[index] || 0) / 100 * parent.height)
                            radius: root.cornerRadius
                            color: { _vc; root.colorFor(index); }
                        }
                    }
                }

                Item {
                    visible: root.showOverallPercentage
                    width: Math.ceil(cpuPercentMetrics.advanceWidth) + 4
                    height: hPercentLabel.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: hPercentLabel
                        anchors.centerIn: parent
                        text: root.displayCpuUsage.toFixed(0) + "%"
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }

    // ── Vertical bar pill ─────────────────────────────────────────────
    verticalBarPill: Component {
        Item {
            id: vPillMouse
            implicitWidth: vContentRow.implicitWidth + 24
            implicitHeight: root.barThickness

            Row {
                id: vContentRow
                spacing: root.barGap
                y: root.barPadding
                height: Math.max(root.minBarHeight, root.barThickness - root.barPadding * 2)
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                        model: root.displayedCoreCount
                        delegate: Item {
                            property int _vc: root._colorVersion
                            width: root.barWidth
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                radius: root.cornerRadius
                                color: { _vc; root.colorFor(index); }
                                opacity: { _vc; root.fillOverlayOpacity; }
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.max(root.minBarHeight, (root.animatedCpuUsage[index] || 0) / 100 * parent.height)
                                radius: root.cornerRadius
                                color: { _vc; root.colorFor(index); }
                            }
                        }
                    }

                    Item {
                        visible: root.showOverallPercentage
                        width: Math.ceil(cpuPercentMetrics.advanceWidth) + 4
                        height: vPercentLabel.implicitHeight
                        anchors.verticalCenter: parent.verticalCenter

                        StyledText {
                            id: vPercentLabel
                            anchors.centerIn: parent
                            text: root.displayCpuUsage.toFixed(0) + "%"
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }
                    }
            }
        }
    }

    // ── Click actions ─────────────────────────────────────────────────
    pillClickAction: function() {
        root.reloadSettings();
        root.openPopout();
    }

    pillRightClickAction: function(posX, posY, posWidth, sectionName, currentScreen) {
        root.reloadSettings();
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

    // ── Popout ────────────────────────────────────────────────────────
    readonly property int popoutMaxRows: 5
    readonly property int popoutColumns: Math.max(1, Math.ceil(root.displayedCoreCount / root.popoutMaxRows))

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "CPU Cores"
            detailsText: "Overall: " + root.displayCpuUsage.toFixed(0) + "%  |  " + root.displayedCoreCount + " cores"
            showCloseButton: false

            Flow {
                width: parent.width
                anchors.margins: 8
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacingS

                Repeater {
                    model: root.displayedCoreCount

                    delegate: Rectangle {
                        property int _vc: root._colorVersion
                        property int coreIndex: index
                        property real coreUsage: root.usageFor(index)
                        property string coreColor: { _vc; root.colorFor(index); }
                        property string coreLabel: root.usageLabel(index)
                        property bool isHottest: index === root.hottestCoreIndex()
                        property real cellWidth: Math.max(100, (parent.width - Theme.spacingS * (root.popoutColumns - 1)) / root.popoutColumns)

                        width: cellWidth
                        height: 44
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh

                        // Background fill bar
                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            width: Math.max(4, (coreUsage / 100) * parent.width)
                            height: parent.height
                            radius: parent.radius
                            color: coreColor
                            opacity: { _vc; root.fillOverlayOpacity; }
                        }

                        // Active indicator bar at bottom
                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            height: 2
                            radius: 1
                            color: coreColor
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            spacing: Theme.spacingS

                            StyledText {
                                text: "C" + coreIndex
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: isHottest ? Font.Bold : Font.Normal
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                            }

                            StyledText {
                                text: coreUsage.toFixed(0) + "%"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                                width: 32
                                horizontalAlignment: Text.AlignRight
                            }

                            StyledText {
                                text: coreLabel + (isHottest ? "" : "")
                                color: isHottest ? coreColor : Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall - 1
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                width: cellWidth - 28 - 32 - 3 * Theme.spacingS
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 480
    popoutHeight: 0
}
