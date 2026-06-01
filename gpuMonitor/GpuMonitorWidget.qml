import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // ── Settings (loaded once, refreshed via poller) ──────────────
    property int probeInterval: 3000
    property string colorMode: "vivid"
    property int smoothingPercent: 15
    property int _colorVersion: 0

    // ── Palettes ──────────────────────────────────────────────────
    readonly property var vividColors: ["#2DD4FF", "#FF2D6D"]
    readonly property var softColors: ["#9ABAEF", "#EF9A9A"]

    // ── GPU data ─────────────────────────────────────────────────
    readonly property var gpuList: {
        const list = Array.isArray(DgopService.availableGpus) ? DgopService.availableGpus.slice() : [];
        let out = [];
        for (let i = 0; i < list.length; i++) {
            const g = list[i];
            if (g && (g.displayName || g.fullName || g.name || g.pciId))
                out.push(g);
        }
        return out;
    }
    readonly property int gpuCount: root.gpuList.length
    property var animatedGpuUsages: []
    property var targetGpuUsages: []

    readonly property real smoothingFactor: Math.pow(0.5, smoothingPercent / 100.0)

    function colorFor(index) {
        const pal = root.colorMode === "vivid" ? root.vividColors : root.softColors;
        return pal[Math.max(0, index) % pal.length];
    }
    function gpuUsage(index) {
        if (index < 0 || index >= root.gpuList.length) return 0;
        return Math.max(0, Math.min(100, Number(root.gpuList[index].utilization || 0)));
    }
    function gpuName(index) {
        if (index < 0 || index >= root.gpuList.length) return "GPU";
        const g = root.gpuList[index];
        return String(g.displayName || g.fullName || g.name || "GPU " + index);
    }
    function gpuTemperature(index) {
        if (index < 0 || index >= root.gpuList.length) return 0;
        return Number(root.gpuList[index].temperature || 0);
    }

    function syncUsageValue(current, target, force) {
        if (force || Number.isNaN(current)) return target;
        const delta = target - current;
        if (Math.abs(delta) < 0.35) return target;
        return current + delta * root.smoothingFactor;
    }
    function syncAnimatedGpuUsage(force) {
        let next = root.animatedGpuUsages ? root.animatedGpuUsages.slice() : [];
        const targets = root.targetGpuUsages;
        const count = Math.max(targets.length, root.gpuCount);
        for (let i = 0; i < count; i++) {
            const t = i < targets.length ? targets[i] : root.gpuUsage(i);
            const c = Number(next[i]);
            next[i] = root.syncUsageValue(c, t, force);
        }
        next.length = count;
        root.animatedGpuUsages = next;
    }
    function overallTextSize() {
        const fs = root.barConfig ? root.barConfig.fontScale : undefined;
        const mx = root.barConfig ? root.barConfig.maximizeWidgetText : undefined;
        return Theme.barTextSize(root.barThickness, fs, mx);
    }

    // ── Lifecycle ────────────────────────────────────────────────
    Component.onCompleted: {
        root.probeInterval = Math.max(500, Math.min(10000, Math.round(pluginData["probeInterval"] != null ? pluginData["probeInterval"] : 3000)));
        root.colorMode = pluginData["colorMode"] || "vivid";
        root.smoothingPercent = Math.max(1, Math.min(99, Math.round(pluginData["smoothingPercent"] != null ? pluginData["smoothingPercent"] : 15)));
        DgopService.addRef(["gpu"]);
        root.targetGpuUsages = [];
        root.syncAnimatedGpuUsage(true);
        DgopService.updateAllStats();
    }
    Component.onDestruction: {
        probeTimer.stop();
        animationTimer.stop();
        settingsPoller.stop();
        DgopService.removeRef(["gpu"]);
    }

    Timer {
        id: probeTimer
        interval: root.probeInterval
        running: true
        repeat: true
        onTriggered: {
            DgopService.updateAllStats();
            root.targetGpuUsages = root.gpuList.map(function(g) { return Math.max(0, Math.min(100, Number(g.utilization || 0))); });
            root.syncAnimatedGpuUsage(false);
        }
    }
    Timer {
        id: animationTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: root.syncAnimatedGpuUsage(false)
    }
    Timer {
        id: settingsPoller
        interval: 250
        running: true
        repeat: true
        onTriggered: root.reloadSettings()
    }

    function reloadSettings() {
        root.probeInterval = Math.max(500, Math.min(10000, Math.round(pluginData["probeInterval"] != null ? pluginData["probeInterval"] : 3000)));
        root.colorMode = pluginData["colorMode"] || "vivid";
        root.smoothingPercent = Math.max(1, Math.min(99, Math.round(pluginData["smoothingPercent"] != null ? pluginData["smoothingPercent"] : 15)));
        root._colorVersion += 1;
    }

    // ── TextMetrics ──────────────────────────────────────────────
    TextMetrics {
        id: gpuPctMetrics
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Bold
        text: "100%"
    }

    // ── Horizontal bar pill ──────────────────────────────────────
    horizontalBarPill: Component {
        MouseArea {
            implicitWidth: hContentRow.implicitWidth + 24
            implicitHeight: root.barThickness
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) root.pillRightClickAction();
                else root.pillClickAction();
            }
            Row {
                id: hContentRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Repeater {
                    model: root.gpuCount
                    delegate: Rectangle {
                        property int _vc: root._colorVersion
                        width: 24; height: root.barThickness - 10
                        radius: 3
                        color: { _vc; root.colorFor(index); }
                        opacity: 0.85
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            anchors.left: parent.left; anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, (root.animatedGpuUsages[index] || 0) / 100 * parent.height)
                            radius: parent.radius; color: parent.color
                        }
                    }
                }
                Item {
                    visible: root.gpuCount > 0
                    width: Math.ceil(gpuPctMetrics.advanceWidth) + 4
                    height: hGpuLabel.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter
                    StyledText {
                        id: hGpuLabel; anchors.centerIn: parent
                        text: root.gpuUsage(0).toFixed(0) + "%"
                        color: "#FFFFFF"; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold
                    }
                }
                StyledText {
                    visible: root.gpuCount === 0; text: "—"
                    color: Theme.widgetTextColor
                    font.pixelSize: Math.max(8, root.overallTextSize()); font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ── Vertical bar pill ────────────────────────────────────────
    verticalBarPill: Component {
        MouseArea {
            implicitWidth: vContentRow.implicitWidth + 16
            implicitHeight: root.barThickness
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) root.pillRightClickAction();
                else root.pillClickAction();
            }
            Row {
                id: vContentRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Repeater {
                    model: root.gpuCount
                    delegate: Rectangle {
                        property int _vc: root._colorVersion
                        width: 24; height: root.barThickness - 10
                        radius: 3
                        color: { _vc; root.colorFor(index); }
                        opacity: 0.85
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            anchors.left: parent.left; anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, (root.animatedGpuUsages[index] || 0) / 100 * parent.height)
                            radius: parent.radius; color: parent.color
                        }
                    }
                }
                StyledText {
                    visible: root.gpuCount > 0
                    text: root.gpuUsage(0).toFixed(0) + "%"
                    color: "#FFFFFF"; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    visible: root.gpuCount === 0; text: "—"
                    color: Theme.widgetTextColor
                    font.pixelSize: Math.max(7, root.overallTextSize() - 1); font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    pillClickAction: function() { root.openPopout(); }
    pillRightClickAction: function(posX, posY, posWidth, sectionName, currentScreen) { root.openPopout(); }

    function openPopout() {
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
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "GPU Monitor"
            detailsText: root.gpuCount > 0 ? root.gpuCount + " GPU(s) detected" : "No GPUs detected"
            showCloseButton: false
            Column {
                width: parent.width
                anchors.margins: 8; anchors.left: parent.left; anchors.right: parent.right
                spacing: Theme.spacingS
                Repeater {
                    model: root.gpuCount
                    delegate: Rectangle {
                        property int gpuIndex: index
                        property real usage: root.gpuUsage(index)
                        property string gpuColor: root.colorFor(index)
                        property real temp: root.gpuTemperature(index)
                        width: parent.width; height: 52; radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh

                        Rectangle {
                            anchors.left: parent.left; anchors.bottom: parent.bottom
                            width: Math.max(4, (usage / 100) * parent.width)
                            height: parent.height; radius: parent.radius
                            color: gpuColor; opacity: 0.22
                        }
                        Rectangle {
                            anchors.left: parent.left; anchors.bottom: parent.bottom
                            anchors.right: parent.right; height: 2; radius: 1; color: gpuColor
                        }
                        Row {
                            anchors.fill: parent; anchors.margins: Theme.spacingS
                            spacing: Theme.spacingM
                            StyledText {
                                text: root.gpuName(index); color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                width: parent.width - 80 - 80 - 3 * Theme.spacingM
                            }
                            StyledText {
                                text: usage.toFixed(0) + "%"; color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                                width: 40; horizontalAlignment: Text.AlignRight
                            }
                            StyledText {
                                text: temp > 0 ? Math.round(temp) + "°C" : "—"
                                color: temp >= 80 ? "#FF2D2D" : temp >= 60 ? "#FFD42D" : Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall - 1
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36; horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
                StyledText {
                    visible: root.gpuCount === 0; width: parent.width
                    text: "No GPUs detected.\nDMS monitors available GPUs automatically."
                    color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
    popoutWidth: 380; popoutHeight: 0
}
