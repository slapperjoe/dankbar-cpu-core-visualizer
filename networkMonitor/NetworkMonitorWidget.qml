import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // ── Properties ─────────────────────────────────────────────
    property var pluginData: Plugins.PluginStorage
    property bool isDesktopWidget: false

    // Network settings
    property int chartWidth: 200
    property int chartHeight: 80
    property int historySize: 60
    property int probeInterval: 2000
    property string colorMode: "vivid"

    // Network data
    property var downloadHistory: []
    property var uploadHistory: []

    readonly property real downloadPeak: {
        let peak = 0;
        for (let i = 0; i < root.downloadHistory.length; i++) {
            if (root.downloadHistory[i] > peak)
                peak = root.downloadHistory[i];
        }
        return peak;
    }

    readonly property real uploadPeak: {
        let peak = 0;
        for (let i = 0; i < root.uploadHistory.length; i++) {
            if (root.uploadHistory[i] > peak)
                peak = root.uploadHistory[i];
        }
        return peak;
    }

    readonly property real globalPeak: Math.max(root.downloadPeak || 0, root.uploadPeak || 0, 1)

    readonly property string throughputLabel: {
        const dl = root.downloadHistory.length > 0 ? root.downloadHistory[root.downloadHistory.length - 1] : 0;
        const ul = root.uploadHistory.length > 0 ? root.uploadHistory[root.uploadHistory.length - 1] : 0;
        return "↓ " + root.formatBandwidth(dl) + "  ↑ " + root.formatBandwidth(ul);
    }

    readonly property string throughputTooltip: {
        const dl = root.downloadHistory.length > 0 ? root.downloadHistory[root.downloadHistory.length - 1] : 0;
        const ul = root.uploadHistory.length > 0 ? root.uploadHistory[root.uploadHistory.length - 1] : 0;
        return "Download: " + root.formatBandwidth(dl) + "\nUpload: " + root.formatBandwidth(ul);
    }

    // Palettes
    property var vividPalette: ["#2DD4FF", "#2DFF8C"]
    property var softPalette: ["#9ABAEF", "#ACEFAA"]

    readonly property string downloadColor: root.colorMode === "soft" ? root.softPalette[0] : root.vividPalette[0]
    readonly property string uploadColor: root.colorMode === "soft" ? root.softPalette[1] : root.vividPalette[1]

    // Timer
    Timer {
        id: probeTimer
        interval: root.probeIntervalMs
        running: true
        repeat: true
        onTriggered: {
            DgopService.updateAllStats();
            root.updateNetworkHistory();
        }
    }

    property int probeIntervalMs: probeInterval

    Component.onCompleted: {
        root.isDesktopWidget = (root.barConfig === undefined || root.barConfig === null);
        root.colorMode = root.pluginData.stringSetting("colorMode", "vivid");
        root.probeInterval = root.pluginData.numberSetting("probeInterval", 2000);
        root.probeIntervalMs = Math.max(500, Math.min(30000, root.probeInterval));
        root.chartWidth = root.pluginData.numberSetting("chartWidth", 200);
        root.chartHeight = root.pluginData.numberSetting("chartHeight", 80);
        root.historySize = root.pluginData.numberSetting("historySize", 60);

        DgopService.addRef(["network"]);
        root.downloadHistory = [];
        root.uploadHistory = [];
    }

    Component.onDestruction: {
        DgopService.removeRef(["network"]);
    }

    // ── Functions ──────────────────────────────────────────────
    function formatBandwidth(bytesPerSec) {
        const val = Number(bytesPerSec || 0);
        if (val >= 1024 * 1024)
            return (val / (1024 * 1024)).toFixed(1) + " MB/s";
        if (val >= 1024)
            return (val / 1024).toFixed(1) + " KB/s";
        return Math.round(val) + " B/s";
    }

    function updateNetworkHistory() {
        const networkStats = DgopService.networkStats || {};
        const dlBytes = Number(networkStats.downloadBytesPerSec || 0);
        const ulBytes = Number(networkStats.uploadBytesPerSec || 0);

        root.downloadHistory.push(dlBytes);
        root.uploadHistory.push(ulBytes);

        if (root.downloadHistory.length > root.historySize) {
            root.downloadHistory = root.downloadHistory.slice(-root.historySize);
            root.uploadHistory = root.uploadHistory.slice(-root.historySize);
        }
    }

    function overallTextSize() {
        const fontScale = root.barConfig ? root.barConfig.fontScale : undefined;
        const maximizeText = root.barConfig ? root.barConfig.maximizeWidgetText : undefined;
        return Theme.barTextSize(root.barThickness, fontScale, maximizeText);
    }

    readonly property real barThickness: root.barConfig ? root.barConfig.thickness : 40
    readonly property real padding: 12

    // ── Layout ────────────────────────────────────────────────
    Item {
        id: container

        width: root.isDesktopWidget ? 480 : (root.barConfig ? root.barConfig.widgetWidth || 480 : 480)
        height: root.isDesktopWidget ? 240 : (root.barConfig ? root.barThickness || 40 : 240)

        // Desktop widget
        Rectangle {
            visible: root.isDesktopWidget
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
                        name: "network"
                        size: Theme.iconSize
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Network Monitor"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                    }
                }

                // Throughput label
                StyledText {
                    Layout.fillWidth: true
                    text: root.throughputLabel
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                // Chart area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.chartHeight
                    color: Theme.surfaceContainerHigh
                    radius: Theme.cornerRadius
                    border.width: 1
                    border.color: Theme.outline
                    clip: true

                    Canvas {
                        id: chartCanvas
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getRenderingContext();
                            ctx.clearRect(0, 0, width, height);

                            // Grid lines
                            ctx.strokeStyle = Theme.outline;
                            ctx.lineWidth = 1;
                            const gridLines = 5;
                            for (let i = 0; i < gridLines; i++) {
                                const y = i * (height / gridLines);
                                ctx.beginPath();
                                ctx.moveTo(0, y);
                                ctx.lineTo(width, y);
                                ctx.stroke();
                            }

                            if (root.downloadHistory.length < 2 || root.globalPeak <= 0)
                                return;

                            const barWidth = width / (root.historySize);

                            // Download line
                            ctx.strokeStyle = root.downloadColor;
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            for (let i = 0; i < root.downloadHistory.length; i++) {
                                const x = i * barWidth;
                                const y = height - (root.downloadHistory[i] / root.globalPeak) * height;
                                if (i === 0)
                                    ctx.moveTo(x, y);
                                else
                                    ctx.lineTo(x, y);
                            }
                            ctx.stroke();

                            // Upload line
                            ctx.strokeStyle = root.uploadColor;
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            for (let i = 0; i < root.uploadHistory.length; i++) {
                                const x = i * barWidth;
                                const y = height - (root.uploadHistory[i] / root.globalPeak) * height;
                                if (i === 0)
                                    ctx.moveTo(x, y);
                                else
                                    ctx.lineTo(x, y);
                            }
                            ctx.stroke();
                        }
                    }
                }

                // Legend
                Row {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    Row {
                        spacing: Theme.spacingXS
                        Rectangle { width: 12; height: 12; radius: 2; color: root.downloadColor }
                        StyledText { text: "Download"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
                    }

                    Row {
                        spacing: Theme.spacingXS
                        Rectangle { width: 12; height: 12; radius: 2; color: root.uploadColor }
                        StyledText { text: "Upload"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
                    }
                }

                // Tooltip text
                StyledText {
                    Layout.fillWidth: true
                    text: root.throughputTooltip
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall - 1
                    wrapMode: Text.WordWrap
                }
            }
        }

        // DankBar widget
        Rectangle {
            visible: !root.isDesktopWidget
            anchors.fill: parent
            color: "transparent"

            Row {
                anchors.fill: parent
                anchors.margins: root.padding
                spacing: Theme.spacingS

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    DankIcon {
                        name: "network"
                        size: Theme.iconSize
                        color: Theme.widgetTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: metricLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.throughputLabel
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
