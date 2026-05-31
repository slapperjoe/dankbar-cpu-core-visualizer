import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // ── Properties ─────────────────────────────────────────────
    property var downloadHistory: []
    property var uploadHistory: []
    property int probeIntervalMs: 1000
    property string colorMode: "vivid"
    property int chartHeight: 80
    property int historySize: 60
    property bool showGrid: true
    property real lineWidth: 2
    property int chartWidth: 80
    property int _chartRefresh: 0

    // ── Derived properties ─────────────────────────────────────
    property real currentDownloadRate: 0
    property real currentUploadRate: 0

    readonly property real downloadPeak: root.networkPeak(root.downloadHistory, root.currentDownloadRate)
    readonly property real uploadPeak: root.networkPeak(root.uploadHistory, root.currentUploadRate)
    readonly property real globalPeak: Math.max(root.downloadPeak, root.uploadPeak, 1)

    readonly property string throughputLabel: {
        return "↓ " + root.formatCompactSpeed(root.currentDownloadRate) + "  ↑ " + root.formatCompactSpeed(root.currentUploadRate);
    }

    readonly property string downloadColor: {
        if (root.colorMode === "soft") return "#9ABAEF";
        return "#2DD4FF";
    }
    readonly property string uploadColor: {
        if (root.colorMode === "soft") return "#EF9A9A";
        return "#FF2D2D";
    }

    // ── Settings load ──────────────────────────────────────────
    Component.onCompleted: {
        root.probeIntervalMs = Math.max(200, Math.min(2000, Math.round(pluginData["probeInterval"] || 1000)));
        root.colorMode = pluginData["colorMode"] || "vivid";
        root.chartHeight = Math.max(40, Math.min(200, Math.round(pluginData["chartHeight"] || 80)));
        root.historySize = Math.max(10, Math.min(120, Math.round(pluginData["historySize"] || 60)));
        root.showGrid = pluginData["showNetworkGrid"] !== undefined ? pluginData["showNetworkGrid"] : true;
        root.lineWidth = Math.max(1, Math.min(4, pluginData["networkLineWidth"] || 2));
        root.chartWidth = Math.max(40, Math.min(200, Math.round(pluginData["networkChartWidth"] || 80)));

        DgopService.addRef(["network"]);
        root.downloadHistory = [];
        root.uploadHistory = [];
    }

    Component.onDestruction: {
        DgopService.removeRef(["network"]);
    }

    // ── Probe timer ────────────────────────────────────────────
    Timer {
        id: probeTimer
        interval: root.probeIntervalMs
        running: true
        repeat: true
        onTriggered: {
            DgopService.updateAllStats();
            root.currentDownloadRate = Math.max(0, Number(DgopService.networkRxRate || 0));
            root.currentUploadRate = Math.max(0, Number(DgopService.networkTxRate || 0));
            root.appendNetworkHistorySample(root.currentDownloadRate, root.currentUploadRate);
            root._chartRefresh += 1;
        }
    }

    // ── Functions ──────────────────────────────────────────────
    function formatCompactSpeed(bytesPerSecond) {
        const val = Math.max(0, Number(bytesPerSecond || 0));
        if (val >= 1024 * 1024)
            return (val / (1024 * 1024)).toFixed(val >= 10 * 1024 * 1024 ? 0 : 1) + "M/s";
        if (val >= 1024)
            return (val / 1024).toFixed(val >= 10 * 1024 ? 0 : 1) + "K/s";
        return Math.round(val) + "B/s";
    }

    function formatFullSpeed(bytesPerSecond) {
        const val = Math.max(0, Number(bytesPerSecond || 0));
        if (val >= 1024 * 1024 * 1024)
            return (val / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
        if (val >= 1024 * 1024)
            return (val / (1024 * 1024)).toFixed(val >= 10 * 1024 * 1024 ? 0 : 1) + " MB/s";
        if (val >= 1024)
            return (val / 1024).toFixed(val >= 10 * 1024 ? 0 : 1) + " KB/s";
        return Math.round(val) + " B/s";
    }

    function networkPeak(values, currentValue) {
        let peak = Math.max(1, Number(currentValue || 0));
        const series = Array.isArray(values) ? values : [];
        for (let i = 0; i < series.length; i++)
            peak = Math.max(peak, Number(series[i] || 0));
        return peak;
    }

    function appendNetworkHistorySample(downloadRate, uploadRate) {
        let nextDownload = root.downloadHistory ? root.downloadHistory.slice() : [];
        let nextUpload = root.uploadHistory ? root.uploadHistory.slice() : [];
        nextDownload.push(Math.max(0, Number(downloadRate || 0)));
        nextUpload.push(Math.max(0, Number(uploadRate || 0)));
        if (nextDownload.length > root.historySize) {
            nextDownload = nextDownload.slice(-root.historySize);
            nextUpload = nextUpload.slice(-root.historySize);
        }
        root.downloadHistory = nextDownload;
        root.uploadHistory = nextUpload;
    }

    // ── NetworkHistoryChart (inline component) ─────────────────
    component NetworkHistoryChart: Canvas {
        property var downloadSeries: []
        property var uploadSeries: []
        property real downloadPeak: 1
        property real uploadPeak: 1
        property color downloadColor: "#2DD4FF"
        property color uploadColor: "#FF2D2D"
        property real strokeWidth: 2
        property bool gridVisible: true

        onDownloadSeriesChanged: requestPaint()
        onUploadSeriesChanged: requestPaint()
        onDownloadPeakChanged: requestPaint()
        onUploadPeakChanged: requestPaint()
        onDownloadColorChanged: requestPaint()
        onUploadColorChanged: requestPaint()
        onStrokeWidthChanged: requestPaint()
        onGridVisibleChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function drawSeries(ctx, series, peak, strokeColor) {
            if (!Array.isArray(series) || series.length <= 0)
                return;
            const inset = Math.min(Math.max(strokeWidth / 2, 0.5), Math.min(width, height) / 2);
            const drawableWidth = Math.max(0, width - inset * 2);
            const drawableHeight = Math.max(0, height - inset * 2);
            ctx.beginPath();
            ctx.lineWidth = strokeWidth;
            ctx.strokeStyle = strokeColor;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            for (let i = 0; i < series.length; i++) {
                const x = series.length <= 1 ? width / 2 : inset + (i / (series.length - 1)) * drawableWidth;
                const ratio = Math.max(0, Math.min(1, Number(series[i] || 0) / Math.max(1, peak)));
                const y = height - inset - ratio * drawableHeight;
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.stroke();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (gridVisible) {
                ctx.strokeStyle = Theme.outline;
                ctx.globalAlpha = 0.3;
                ctx.lineWidth = 1;
                for (let row = 1; row <= 3; row++) {
                    const y = (height / 4) * row;
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                    ctx.stroke();
                }
                ctx.globalAlpha = 1;
            }
            drawSeries(ctx, downloadSeries, downloadPeak, downloadColor);
            drawSeries(ctx, uploadSeries, uploadPeak, uploadColor);
        }
    }

    function overallTextSize() {
        const fontScale = root.barConfig ? root.barConfig.fontScale : undefined;
        const maximizeText = root.barConfig ? root.barConfig.maximizeWidgetText : undefined;
        return Theme.barTextSize(root.barThickness, fontScale, maximizeText);
    }

    readonly property real barThickness: root.barConfig ? root.barConfig.thickness : 40

    // ── Pill layouts ────────────────────────────────────────────
    horizontalBarPill: Component {
        MouseArea {
            implicitWidth: hContentRow.implicitWidth + 24
            implicitHeight: root.barThickness
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.pillRightClickAction();
                else
                    root.pillClickAction();
            }

            Row {
                id: hContentRow
                anchors.centerIn: parent
                spacing: 2

                // Download label
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↓ " + root.formatCompactSpeed(root.currentDownloadRate)
                    color: root.downloadColor
                    font.pixelSize: Math.max(8, root.overallTextSize())
                    font.weight: Font.Medium
                }

                // Mini chart
                Rectangle {
                    width: root.chartWidth
                    height: Math.max(12, root.barThickness - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Math.min(4, height / 2)
                    color: Theme.surfaceContainer
                    clip: true

                    NetworkHistoryChart {
                        anchors.fill: parent
                        anchors.margins: 2
                        downloadSeries: root.downloadHistory
                        uploadSeries: root.uploadHistory
                        downloadPeak: root.downloadPeak
                        uploadPeak: root.uploadPeak
                        downloadColor: root.downloadColor
                        uploadColor: root.uploadColor
                        strokeWidth: Math.max(1, root.lineWidth - 0.5)
                        gridVisible: false
                    }
                }

                // Upload label
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↑ " + root.formatCompactSpeed(root.currentUploadRate)
                    color: root.uploadColor
                    font.pixelSize: Math.max(8, root.overallTextSize())
                    font.weight: Font.Medium
                }
            }
        }
    }

    verticalBarPill: Component {
        MouseArea {
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            implicitWidth: vContentColumn.implicitWidth + 16
            implicitHeight: root.barThickness
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.pillRightClickAction();
                else
                    root.pillClickAction();
            }

            Column {
                id: vContentColumn
                anchors.centerIn: parent
                spacing: 1

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↓" + root.formatCompactSpeed(root.currentDownloadRate)
                    color: root.downloadColor
                    font.pixelSize: Math.max(7, root.overallTextSize() - 1)
                    font.weight: Font.Medium
                }

                Rectangle {
                    width: Math.max(24, root.chartWidth * 0.6)
                    height: Math.max(30, root.barThickness * 1.2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: Math.min(4, width / 3)
                    color: Theme.surfaceContainer
                    clip: true

                    NetworkHistoryChart {
                        anchors.fill: parent
                        anchors.margins: 2
                        downloadSeries: root.downloadHistory
                        uploadSeries: root.uploadHistory
                        downloadPeak: root.downloadPeak
                        uploadPeak: root.uploadPeak
                        downloadColor: root.downloadColor
                        uploadColor: root.uploadColor
                        strokeWidth: Math.max(1, root.lineWidth - 0.5)
                        gridVisible: false
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↑" + root.formatCompactSpeed(root.currentUploadRate)
                    color: root.uploadColor
                    font.pixelSize: Math.max(7, root.overallTextSize() - 1)
                    font.weight: Font.Medium
                }
            }
        }
    }

    pillClickAction: function() {
        root.openPopout();
    }

    pillRightClickAction: function(posX, posY, posWidth, sectionName, currentScreen) {
        root.openPopout();
    }

    function openPopout() {
        var popout = null;
        var pill = null;
        for (var i = 0; i < root.children.length; i++) {
            var child = root.children[i];
            if (typeof child.setTriggerPosition === "function")
                popout = child;
            if (typeof child.mapToItem === "function" && child.width !== undefined && child.width > 0 && typeof child.setTriggerPosition !== "function")
                pill = child;
        }
        if (popout && pill) {
            var globalPos = pill.mapToItem(null, 0, 0);
            var screen = root.parentScreen || Screen;
            var pos = SettingsData.getPopupTriggerPosition(globalPos, screen, root.barThickness, pill.width, 8, 0, null);
            popout.setTriggerPosition(pos.x, pos.y, pos.width, root.section, screen, 0, root.barThickness, 8, null);
            popout.toggle();
        }
    }

    // ── Popout Content ─────────────────────────────────────────
    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Network Monitor"
            detailsText: "↓ " + root.formatFullSpeed(root.currentDownloadRate) + "  |  ↑ " + root.formatFullSpeed(root.currentUploadRate)
            showCloseButton: false

            Column {
                width: parent.width
                anchors.margins: 8
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacingM

                // ── Chart ──────────────────────────────────
                Rectangle {
                    width: parent.width
                    height: root.chartHeight + 8
                    color: Theme.surfaceContainerHigh
                    radius: Theme.cornerRadius
                    border.width: 1
                    border.color: Theme.outline
                    clip: true

                    NetworkHistoryChart {
                        id: popoutChart
                        anchors.fill: parent
                        anchors.margins: 4
                        downloadSeries: root.downloadHistory
                        uploadSeries: root.uploadHistory
                        downloadPeak: root.downloadPeak
                        uploadPeak: root.uploadPeak
                        downloadColor: root.downloadColor
                        uploadColor: root.uploadColor
                        strokeWidth: root.lineWidth
                        gridVisible: root.showGrid
                    }
                }

                // ── Legend ────────────────────────────────
                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    Row {
                        spacing: Theme.spacingXS
                        Rectangle { width: 12; height: 12; radius: 2; color: root.downloadColor; anchors.verticalCenter: parent.verticalCenter }
                        StyledText {
                            text: "Download: " + root.formatFullSpeed(root.currentDownloadRate)
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: Theme.spacingXS
                        Rectangle { width: 12; height: 12; radius: 2; color: root.uploadColor; anchors.verticalCenter: parent.verticalCenter }
                        StyledText {
                            text: "Upload: " + root.formatFullSpeed(root.currentUploadRate)
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // ── Peak info ─────────────────────────────
                StyledText {
                    width: parent.width
                    text: "Peaks (recent): ↓ " + root.formatFullSpeed(root.downloadPeak) + "  |  ↑ " + root.formatFullSpeed(root.uploadPeak)
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall - 1
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
    popoutWidth: 380
    popoutHeight: 0
}
