import Qt 6.7
import QtQuick 2.15
import QtQuick.Layouts 6.7
import io.github.quicksilver.quickshell 1.0 as Quickshell
import io.github.dankmachines.dankmaterialshell.theming 1.0 as Theme
import io.github.dankmachines.dankmaterialshell.plugins 1.0 as DankPlugins
import io.github.dankmachines.dankmaterialshell.quickshell 1.0 as QuickshellInt
import io.github.dankmachines.dankmaterialshell.stdio 1.0 as Stdio

PluginComponent {
    id: root

    // ── Properties ─────────────────────────────────────────────
    property var pluginData: DankPlugins.PluginStorage
    property var gpuTelemetry: []
    property var displayGpuTelemetry: []
    property var gpuProcesses: []
    property var topGpuProcesses: []
    property var animatedGpuUsages: []
    property var monitoredGenericGpuPciIds: []
    property bool hasRichGpuTelemetry: false
    property bool nvidiaSmiAvailable: false
    property bool nvidiaSmiPollingEnabled: false
    property bool useGenericGpuFallback: false
    property bool isDesktopWidget: false

    property var primaryGpu: gpuTelemetry.length > 0 ? gpuTelemetry[0] : null
    property var primaryGenericGpu: genericGpuTelemetry.length > 0 ? genericGpuTelemetry[0] : null
    property var genericGpuTelemetry: Array.isArray(DgopService) ? (DgopService.genericGpuTelemetry || []) : []

    // Settings
    property int barWidth: 24
    property int barGap: 4
    property int cornerRadius: 6
    property string colorMode: "vivid"
    property int smoothingPercent: 15
    property int probeInterval: 3000
    property int sectionPadding: 12
    property string barLayout: "horizontal"

    readonly property real smoothingFactor: Math.pow(0.5, smoothingPercent / 100.0)
    readonly property real animationDuration: 120
    readonly property real fillOverlayOpacity: 0.96
    readonly property real sectionGap: barGap
    readonly property real padding: sectionPadding

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
    property int probeIntervalMs: probeInterval

    Timer {
        id: animationTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: root.syncAnimatedGpuUsage(true)
    }

    Timer {
        id: probeTimer
        interval: root.probeIntervalMs
        running: true
        repeat: true
        onTriggered: {
            DgopService.updateAllStats();
            root.refreshGpuTelemetry();
        }
    }

    Component.onCompleted: {
        root.isDesktopWidget = (root.barConfig === undefined || root.barConfig === null);
        root.nvidiaSmiPollingEnabled = root.pluginData.boolSetting("nvidiaSmiPollingEnabled", true);
        root.useGenericGpuFallback = root.pluginData.boolSetting("useGenericGpuFallback", true);
        root.colorMode = root.pluginData.stringSetting("colorMode", "vivid");
        root.barWidth = root.pluginData.numberSetting("barWidth", 24);
        root.barGap = root.pluginData.numberSetting("barGap", 4);
        root.smoothingPercent = root.pluginData.numberSetting("smoothingPercent", 15);
        root.probeInterval = root.pluginData.numberSetting("probeInterval", 3000);
        root.probeIntervalMs = Math.max(500, Math.min(30000, root.probeInterval));
        root.smoothingPercent = Math.max(1, Math.min(99, root.smoothingPercent));
        root.barWidth = Math.max(8, Math.min(80, root.barWidth));
        root.barGap = Math.max(1, Math.min(20, root.barGap));
        root.barLayout = root.pluginData.stringSetting("barLayout", "horizontal");
        root.cornerRadius = Math.max(2, Math.min(20, root.pluginData.numberSetting("cornerRadius", 6));

        DgopService.addRef(["gpu"]);
        root.syncAnimatedGpuUsage(true);
    }

    Component.onDestruction: {
        DgopService.removeRef(["gpu"]);
        if (nvidiaGpuStatsProcess.running)
            nvidiaGpuStatsProcess.running = false;
        if (nvidiaGpuAppsProcess.running)
            nvidiaGpuAppsProcess.running = false;
    }

    // ── nvidia-smi processes ─────────────────────────────────
    Quickshell.Io {
        id: nvidiaGpuStatsProcess
        command: "nvidia-smi"
        arguments: ["--query-gpu=index,uuid,name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw,power.limit,clock.grafix,clock.mem,utilization.enc,utilization.dec", "--format=csv"]
        running: false
        repeat: true
        interval: 1000
        stdout: Stdio.StdioCollector {
            onStreamFinished: root.parseNvidiaGpuStats(text)
        }
    }

    Quickshell.Io {
        id: nvidiaGpuAppsProcess
        command: "nvidia-smi"
        arguments: ["--query-compute-apps=gpu,pid,processName,usedMemory", "--format=csv"]
        running: false
        repeat: true
        interval: 2000
        stdout: Stdio.StdioCollector {
            onStreamFinished: root.parseNvidiaGpuApps(text)
        }
    }

    // ── Functions ──────────────────────────────────────────────
    function nvidiaNumber(value, fallback) {
        if (value === undefined || value === null || value === "")
            return fallback;
        const num = Number(String(value).replace(/[^0-9.\-]/g, ""));
        return Number.isNaN(num) ? fallback : num;
    }

    function clampUsage(value) {
        return Math.max(0, Math.min(100, Number(value) || 0));
    }

    function gpuUsageFor(index) {
        if (root.hasRichGpuTelemetry) {
            if (index < 0 || index >= root.gpuTelemetry.length)
                return 0;
            const richGpu = root.gpuTelemetry[index];
            return root.clampUsage(root.nvidiaNumber(richGpu && richGpu.utilization !== undefined ? richGpu.utilization : 0, 0));
        }
        if (!root.useGenericGpuFallback || index < 0 || index >= root.genericGpuTelemetry.length)
            return 0;
        return root.clampUsage(root.gpuTemperature(root.genericGpuTelemetry[index]));
    }

    function gpuTemperature(gpu) {
        return Number(gpu && gpu.temperature || 0);
    }

    function gpuName(gpu) {
        return String(gpu && gpu.name || "Unknown GPU");
    }

    function gpuVendor(gpu) {
        return String(gpu && gpu.vendor || "");
    }

    function gpuDriver(gpu) {
        return String(gpu && gpu.driver || "");
    }

    function gpuPciId(gpu) {
        return String(gpu && gpu.pciId || "");
    }

    function formatGpuMemory(miB) {
        if (miB === undefined || miB === null)
            return "0 B";
        const val = Number(miB);
        if (val >= 1024)
            return (val / 1024).toFixed(1) + " GB";
        return Math.round(val) + " MiB";
    }

    function gpuTemperatureColor(temp) {
        if (temp >= 85)
            return Theme.error;
        if (temp >= 65)
            return Theme.warning;
        return Theme.info;
    }

    function parseNvidiaGpuStats(text) {
        const lines = String(text || "").split(/\r?\n/).map(line => line.trim()).filter(line => line.length > 0);
        let nextGpus = [];
        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split(",").map(part => part.trim());
            if (parts.length < 13)
                continue;

            const memoryUsedMiB = root.nvidiaNumber(parts[5], 0);
            const memoryTotalMiB = root.nvidiaNumber(parts[6], 0);
            const memoryUsagePercent = memoryTotalMiB > 0 ? root.clampUsage((memoryUsedMiB / memoryTotalMiB) * 100) : 0;
            nextGpus.push({
                "index": Math.max(0, Math.round(root.nvidiaNumber(parts[0], i)),
                "uuid": parts[1],
                "name": parts[2] || "NVIDIA GPU",
                "temperature": root.nvidiaNumber(parts[3], 0),
                "utilization": root.clampUsage(root.nvidiaNumber(parts[4], 0)),
                "memoryUsedMiB": memoryUsedMiB,
                "memoryTotalMiB": memoryTotalMiB,
                "memoryUsagePercent": memoryUsagePercent,
                "powerDrawWatts": root.nvidiaNumber(parts[7], 0),
                "powerLimitWatts": root.nvidiaNumber(parts[8], 0),
                "graphicsClockMHz": root.nvidiaNumber(parts[9], 0),
                "memoryClockMHz": root.nvidiaNumber(parts[10], 0),
                "encoderUtilization": root.clampUsage(root.nvidiaNumber(parts[11], 0)),
                "decoderUtilization": root.clampUsage(root.nvidiaNumber(parts[12], 0))
            });
        }

        root.gpuTelemetry = nextGpus;
        root.nvidiaSmiAvailable = nextGpus.length > 0;
        root.hasRichGpuTelemetry = root.nvidiaSmiAvailable;
        root.displayGpuTelemetry = root.hasRichGpuTelemetry
            ? root.gpuTelemetry
            : (root.useGenericGpuFallback ? root.genericGpuTelemetry : []);
    }

    function parseNvidiaGpuApps(text) {
        const lines = String(text || "").split(/\r?\n/).map(line => line.trim()).filter(line => line.length > 0 && line.indexOf("No running processes found") === -1);
        let nextProcesses = [];
        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split(",").map(part => part.trim());
            if (parts.length < 4)
                continue;

            const gpuUuid = parts[0];
            const gpu = root.gpuTelemetry.find(entry => entry.uuid === gpuUuid);
            nextProcesses.push({
                "gpuUuid": gpuUuid,
                "gpuName": gpu ? gpu.name : "GPU",
                "pid": Math.max(0, Math.round(root.nvidiaNumber(parts[1], 0)),
                "processName": parts[2] || "",
                "usedMemoryMiB": root.nvidiaNumber(parts[3], 0)
            });
        }

        root.gpuProcesses = nextProcesses;
        root.topGpuProcesses = root.gpuProcesses.sort((a, b) => b.usedMemoryMiB - a.usedMemoryMiB).slice(0, 10);
    }

    function syncUsageValue(current, target, force) {
        if (force || Number.isNaN(current))
            return target;
        const delta = target - current;
        if (Math.abs(delta) < 0.35)
            return target;
        return current + delta * root.smoothingFactor;
    }

    function syncAnimatedGpuUsage(force) {
        let next = root.animatedGpuUsages ? root.animatedGpuUsages.slice() : [];
        const gpuCount = Array.isArray(root.displayGpuTelemetry) ? root.displayGpuTelemetry.length : 0;
        for (let g = 0; g < gpuCount; g++) {
            const target = root.gpuUsageFor(g);
            const current = Number(next[g]);
            next[g] = root.syncUsageValue(current, target, force);
        }
        next.length = gpuCount;
        root.animatedGpuUsages = next;
    }

    function colorFor(index) {
        if (root.colorMode === "soft")
            return root.softPalette[index % root.softPalette.length];
        return root.vividPalette[index % root.vividPalette.length];
    }

    function sectionColorFor(index) {
        return root.colorFor(index);
    }

    function cardFillWidth(index, cardWidth) {
        const usage = root.animatedGpuUsages[index] || 0;
        return (root.clampUsage(usage) / 100) * cardWidth;
    }

    // ── Layout ────────────────────────────────────────────────
    Item {
        id: container

        width: root.isDesktopWidget ? 400 : (root.barConfig ? root.barConfig.widgetWidth || 400 : 400)
        height: root.isDesktopWidget ? 160 : (root.barConfig ? root.barThickness || 40 : 160)

        // Desktop widget wrapper
        visible: root.isDesktopWidget
        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.width: 1
            border.color: Theme.outline

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                StyledText {
                    width: parent.width
                    text: "GPU Monitor"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                }

                Row {
                    id: gpuBars
                    width: parent.width
                    spacing: root.barGap

                    Repeater {
                        model: root.displayGpuTelemetry

                        delegate: Rectangle {
                            width: root.barWidth
                            height: 100
                            radius: root.cornerRadius
                            color: Theme.surfaceContainerHigh
                            clip: true

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: parent.width
                                height: Math.max(2, (root.animatedGpuUsages[index] || 0) / 100 * parent.height)
                                radius: root.cornerRadius
                                color: root.sectionColorFor(index)
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

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.displayGpuTelemetry

                        delegate: StyledText {
                            width: parent.width / Math.max(1, root.displayGpuTelemetry.length)
                            text: {
                                if (root.hasRichGpuTelemetry) {
                                    const gpu = modelData;
                                    return gpu.name + " " + root.clampUsage(Number(gpu.utilization || 0)).toFixed(0) + "%";
                                }
                                return root.gpuName(modelData) + " " + Math.round(root.gpuTemperature(modelData)) + "°C";
                            }
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
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

                Repeater {
                    model: root.displayGpuTelemetry

                    delegate: Item {
                        width: root.barWidth
                        height: parent.height

                        Rectangle {
                            width: parent.width
                            height: root.verticalHeightFor(index, parent.height)
                            anchors.bottom: parent.bottom
                            radius: Math.min(root.cornerRadius, width / 2)
                            color: root.sectionColorFor(index)
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
                        name: "developer_board"
                        size: Theme.iconSize
                        color: Theme.widgetTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: metricLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (root.hasRichGpuTelemetry)
                                return root.primaryGpu ? root.gpuUsageValue.toFixed(0) + "%" : "—";
                            if (root.useGenericGpuFallback)
                                return root.primaryGenericGpu ? Math.round(root.gpuTemperature(root.primaryGenericGpu)) + "°C" : "—";
                            return "—";
                        }
                        color: Theme.widgetTextColor
                        font.pixelSize: root.overallTextSize()
                        font.weight: Font.Medium
                    }
                }
            }
        }

        HoverHandler {
            onHoveredChanged: {
                root.barHovered = hovered;
            }
        }
    }

    function verticalHeightFor(index, totalHeight) {
        const usage = root.animatedGpuUsages[index] || 0;
        return Math.max(2, root.clampUsage(usage) / 100 * totalHeight);
    }

    function overallTextSize() {
        const fontScale = root.barConfig ? root.barConfig.fontScale : undefined;
        const maximizeText = root.barConfig ? root.barConfig.maximizeWidgetText : undefined;
        return Theme.barTextSize(root.barThickness, fontScale, maximizeText);
    }

    readonly property real widgetThickness: root.barConfig ? root.barThickness : 160
    readonly property real barThickness: root.barConfig ? root.barConfig.thickness : 40
    readonly property real gpuUsageValue: root.primaryGpu ? root.clampUsage(root.nvidiaNumber(root.primaryGpu.utilization, 0)) : 0

    TextMetrics {
        id: overallPercentageMetrics
        font.pixelSize: root.overallTextSize()
        font.weight: Font.Medium
        text: "100%"
    }
}
