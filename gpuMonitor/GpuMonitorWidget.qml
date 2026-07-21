import QtQuick
import Quickshell.Io
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
    property int barWidth: 7
    property int barPadding: 4
    property int minBarHeight: 2
    property int cornerRadius: 2

    // ── Palettes ──────────────────────────────────────────────────
    readonly property var vividColors: ["#2DD4FF", "#FF2D6D"]
    readonly property var softColors: ["#9ABAEF", "#EF9A9A"]

    // ── GPU data ─────────────────────────────────────────────────
    property var _sysfsGpus: []
    readonly property var gpuList: {
        const list = Array.isArray(DgopService.availableGpus) ? DgopService.availableGpus.slice() : [];
        let out = [];
        for (let i = 0; i < list.length; i++) {
            const g = list[i];
            if (!g || !(g.displayName || g.fullName || g.name || g.pciId)) continue;
            const hasData = (Number(g.utilization || 0) > 0) || (Number(g.temperature || 0) > 0);
            if (hasData) out.push(g);
        }
        if (out.length === 0 && root._sysfsGpus.length > 0)
            out = root._sysfsGpus.slice();
        return out;
    }
    readonly property int gpuCount: root.gpuList.length
    property var animatedGpuUsages: []
    property var targetGpuUsages: []

    readonly property real smoothingFactor: Math.max(0.08, Math.min(0.85, smoothingPercent / 100))

    function colorFor(index) {
        const pal = root.colorMode === "vivid" ? root.vividColors : root.softColors;
        return pal[Math.max(0, index) % pal.length];
    }
    function gpuUsage(index) {
        if (index < 0 || index >= root.gpuList.length) return 0;
        const g = root.gpuList[index];
        const util = Number(g.utilization || 0);
        if (util > 0) return Math.max(0, Math.min(100, util));
        const temp = Number(g.temperature || 0);
        if (temp > 0) return Math.max(0, Math.min(100, temp));
        return 0;
    }
    function gpuMetricLabel(index) {
        if (index < 0 || index >= root.gpuList.length) return "—";
        const g = root.gpuList[index];
        const util = Number(g.utilization || 0);
        if (util > 0) return "Util";
        const temp = Number(g.temperature || 0);
        if (temp > 0) return "Temp";
        return "—";
    }
    function gpuMetricText(index) {
        if (index < 0 || index >= root.gpuList.length) return "—";
        const g = root.gpuList[index];
        const util = Number(g.utilization || 0);
        if (util > 0) return root.gpuUsage(index).toFixed(0) + "%";
        const temp = Number(g.temperature || 0);
        if (temp > 0) return Math.round(temp) + "°C";
        return "—";
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

    function _fetchSysfsGpus() {
        var script = "for card in /sys/class/drm/card[0-9]*/device; do busy=\"$card/gpu_busy_percent\"; [ -f \"$busy\" ] || continue; util=$(cat \"$busy\"); temp=0; for hw in \"$card\"/hwmon/hwmon*; do t=$(cat \"$hw/temp1_input\" 2>/dev/null); [ -n \"$t\" ] && { temp=$t; break; }; done; pci=$(grep -o 'PCI_ID=.*' \"$card/uevent\" 2>/dev/null | cut -d= -f2); driver=$(grep -o 'DRIVER=.*' \"$card/uevent\" 2>/dev/null | cut -d= -f2); pci_addr=$(basename \"$(readlink \"$card\")\"); name=$(lspci -s \"$pci_addr\" 2>/dev/null | sed 's/.*\\[//;s/\\].*//;s/.*\\/ *//'); [ -z \"$name\" ] && name=\"GPU\"; power=0; for hw in \"$card\"/hwmon/hwmon*; do p=$(cat \"$hw/power1_input\" 2>/dev/null); [ -n \"$p\" ] && { power=$p; break; }; done; vram_total=$(cat \"$card/mem_info_vram_total\" 2>/dev/null || echo 0); vram_used=$(cat \"$card/mem_info_vram_used\" 2>/dev/null || echo 0); gtt_total=$(cat \"$card/mem_info_gtt_total\" 2>/dev/null || echo 0); gtt_used=$(cat \"$card/mem_info_gtt_used\" 2>/dev/null || echo 0); echo \"GPU|\"$name\"|\"$driver\"|\"$pci\"|\"$util\"|\"$temp\"|\"$power\"|\"$vram_total\"|\"$vram_used\"|\"$gtt_total\"|\"$gtt_used; done";
        Proc.runCommand("sysfsGpu", ["sh", "-c", script],
            function(output, exitCode) {
                if (exitCode !== 0 || !output) return;
                var gpus = [];
                var lines = output.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.indexOf("GPU|") !== 0) continue;
                    var parts = line.split("|");
                    if (parts.length < 9) continue;
                    gpus.push({
                        displayName: parts[1] || "GPU",
                        fullName: parts[1] || "",
                        name: parts[1] || "GPU " + i,
                        driver: parts[2] || "",
                        pciId: parts[3] || "",
                        utilization: parseFloat(parts[4]) || 0,
                        temperature: Math.round((parseFloat(parts[5]) || 0) / 1000),
                        power: Math.round((parseFloat(parts[6]) || 0) / 1000000),
                        vramTotal: parseInt(parts[7]) || 0,
                        vramUsed: parseInt(parts[8]) || 0,
                        gttTotal: parseInt(parts[9]) || 0,
                        gttUsed: parseInt(parts[10]) || 0
                    });
                }
                if (gpus.length > 0) {
                    root._sysfsGpus = gpus;
                    root.targetGpuUsages = root.gpuList.map(function(g) {
                        var util = Number(g.utilization || 0);
                        if (util > 0) return Math.max(0, Math.min(100, util));
                        var temp = Number(g.temperature || 0);
                        if (temp > 0) return Math.max(0, Math.min(100, temp));
                        return 0;
                    });
                }
            }, 50, 5000);
    }

    // ── Lifecycle ────────────────────────────────────────────────
    Component.onCompleted: {
        root.probeInterval = Math.max(500, Math.min(10000, Math.round(pluginData["probeInterval"] != null ? pluginData["probeInterval"] : 3000)));
        root.colorMode = pluginData["colorMode"] || "vivid";
        root.smoothingPercent = Math.max(1, Math.min(99, Math.round(pluginData["smoothingPercent"] != null ? pluginData["smoothingPercent"] : 15)));
        root.barWidth = Math.max(2, Math.round(pluginData["barWidth"] !== undefined ? pluginData["barWidth"] : 7));
        root.barPadding = Math.max(0, Math.round(pluginData["barPadding"] !== undefined ? pluginData["barPadding"] : 4));
        root.minBarHeight = Math.max(0, Math.round(pluginData["minBarHeight"] !== undefined ? pluginData["minBarHeight"] : 2));
        root.cornerRadius = Math.max(0, Math.round(pluginData["cornerRadius"] !== undefined ? pluginData["cornerRadius"] : 2));
        DgopService.addRef(["gpu"]);
        root.targetGpuUsages = [];
        root.syncAnimatedGpuUsage(true);
        DgopService.updateAllStats();
        root._fetchSysfsGpus();
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
            root._fetchSysfsGpus();
            var dgopGpus = DgopService.availableGpus;
            if (Array.isArray(dgopGpus) && dgopGpus.length > 0) {
                var hasData = dgopGpus.some(function(g) { return Number(g.utilization || 0) > 0 || Number(g.temperature || 0) > 0; });
                if (hasData) {
                    root.targetGpuUsages = root.gpuList.map(function(g) {
                        var util = Number(g.utilization || 0);
                        if (util > 0) return Math.max(0, Math.min(100, util));
                        var temp = Number(g.temperature || 0);
                        if (temp > 0) return Math.max(0, Math.min(100, temp));
                        return 0;
                    });
                    root.syncAnimatedGpuUsage(false);
                }
            }
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
        root.barWidth = Math.max(2, Math.round(pluginData["barWidth"] !== undefined ? pluginData["barWidth"] : 7));
        root.barPadding = Math.max(0, Math.round(pluginData["barPadding"] !== undefined ? pluginData["barPadding"] : 4));
        root.minBarHeight = Math.max(0, Math.round(pluginData["minBarHeight"] !== undefined ? pluginData["minBarHeight"] : 2));
        root.cornerRadius = Math.max(0, Math.round(pluginData["cornerRadius"] !== undefined ? pluginData["cornerRadius"] : 2));
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
        Item {
            implicitWidth: hContentRow.implicitWidth + 24
            implicitHeight: root.barThickness

            Row {
                id: hContentRow
                spacing: 0
                y: root.barPadding + 5
                height: Math.max(root.minBarHeight, root.barThickness - (root.barPadding + 5) * 2)
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: root.barWidth
                    height: parent.height
                    visible: root.gpuCount > 0
                    radius: root.cornerRadius
                    color: "#000000"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(root.minBarHeight, (root.animatedGpuUsages[0] || 0) / 100 * parent.height)
                        radius: root.cornerRadius
                        color: root.colorFor(0)

                        Behavior on height {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Item {
                    visible: root.gpuCount > 0
                    width: Math.ceil(gpuPctMetrics.advanceWidth) + 4
                    height: hGpuLabel.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: hGpuLabel
                        anchors.centerIn: parent
                        text: root.gpuMetricText(0)
                        color: Theme.widgetTextColor
                        font.pixelSize: root.overallTextSize()
                        font.weight: Font.Bold
                    }
                }

                StyledText {
                    visible: root.gpuCount === 0
                    text: "—"
                    width: Math.ceil(gpuPctMetrics.advanceWidth) + 4
                    color: Theme.widgetTextColor
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ── Vertical bar pill ────────────────────────────────────────
    verticalBarPill: Component {
        Item {
            implicitWidth: vContentRow.implicitWidth + 24
            implicitHeight: root.barThickness

            Row {
                id: vContentRow
                spacing: 0
                y: root.barPadding
                height: Math.max(root.minBarHeight, root.barThickness - root.barPadding * 2)
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: root.barWidth
                    height: parent.height
                    visible: root.gpuCount > 0
                    radius: root.cornerRadius
                    color: "#000000"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(root.minBarHeight, (root.animatedGpuUsages[0] || 0) / 100 * parent.height)
                        radius: root.cornerRadius
                        color: root.colorFor(0)

                        Behavior on height {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                StyledText {
                    visible: root.gpuCount > 0
                    text: root.gpuMetricText(0)
                    color: Theme.widgetTextColor
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    visible: root.gpuCount === 0
                    text: "—"
                    width: Math.ceil(gpuPctMetrics.advanceWidth) + 4
                    color: Theme.widgetTextColor
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Medium
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
                        property var gpu: root.gpuList[index]
                        width: parent.width; height: 66; radius: Theme.cornerRadius
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
                        Column {
                            anchors.fill: parent; anchors.margins: Theme.spacingS
                            spacing: 2
                            Row {
                                width: parent.width; spacing: Theme.spacingM
                                StyledText {
                                    text: root.gpuName(index); color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    width: parent.width - 80 - 80 - 3 * Theme.spacingM
                                }
                                StyledText {
                                    text: root.gpuMetricText(index); color: Theme.surfaceText
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
                            Row {
                                visible: gpu !== undefined
                                width: parent.width; spacing: Theme.spacingM
                                StyledText {
                                    visible: gpu && gpu.power > 0
                                    text: gpu ? gpu.power + "W" : ""
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 2
                                }
                                StyledText {
                                    visible: gpu && gpu.vramTotal > 0
                                    text: gpu ? "VRAM " + (gpu.vramUsed / 1073741824).toFixed(1) + "/" + (gpu.vramTotal / 1073741824).toFixed(0) + " GB" : ""
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 2
                                }
                                StyledText {
                                    visible: gpu && gpu.gttTotal > 0
                                    text: gpu ? "GTT " + (gpu.gttUsed / 1073741824).toFixed(1) + "/" + (gpu.gttTotal / 1073741824).toFixed(0) + " GB" : ""
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 2
                                }
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
