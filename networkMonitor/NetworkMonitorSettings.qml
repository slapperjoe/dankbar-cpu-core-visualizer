import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "networkMonitor"
    title: "Network Monitor"

    property int _probeMs: pluginData.numberSetting("probeInterval", 1000)
    property string _colorMode: pluginData.stringSetting("colorMode", "vivid")
    property int _chartH: pluginData.numberSetting("chartHeight", 80)
    property int _pillW: pluginData.numberSetting("networkChartWidth", 80)
    property int _hist: pluginData.numberSetting("historySize", 60)
    property bool _grid: pluginData.boolSetting("showNetworkGrid", true)
    property real _lw: pluginData.numberSetting("networkLineWidth", 2)

    readonly property var probeOptions: [500, 1000, 2000, 3000, 5000, 10000]
    readonly property var chartHOptions: [40, 60, 80, 100, 120, 160, 200]
    readonly property var pillWOptions: [40, 60, 80, 100, 120, 160, 200]
    readonly property var histOptions: [10, 20, 30, 60, 90, 120]
    readonly property var lwOptions: [1, 1.5, 2, 3, 4]

    function cycleProbe() {
        const opts = root.probeOptions;
        const idx = opts.indexOf(root._probeMs);
        const next = idx >= 0 && idx < opts.length - 1 ? opts[idx + 1] : opts[0];
        root._probeMs = next;
        pluginData.setNumber("probeInterval", next);
    }
    function cycleChartH() {
        const opts = root.chartHOptions;
        const idx = opts.indexOf(root._chartH);
        const next = idx >= 0 && idx < opts.length - 1 ? opts[idx + 1] : opts[0];
        root._chartH = next;
        pluginData.setNumber("chartHeight", next);
    }
    function cyclePillW() {
        const opts = root.pillWOptions;
        const idx = opts.indexOf(root._pillW);
        const next = idx >= 0 && idx < opts.length - 1 ? opts[idx + 1] : opts[0];
        root._pillW = next;
        pluginData.setNumber("networkChartWidth", next);
    }
    function cycleHist() {
        const opts = root.histOptions;
        const idx = opts.indexOf(root._hist);
        const next = idx >= 0 && idx < opts.length - 1 ? opts[idx + 1] : opts[0];
        root._hist = next;
        pluginData.setNumber("historySize", next);
    }
    function cycleLW() {
        const opts = root.lwOptions;
        const idx = opts.indexOf(root._lw);
        const next = idx >= 0 && idx < opts.length - 1 ? opts[idx + 1] : opts[0];
        root._lw = next;
        pluginData.setNumber("networkLineWidth", next);
    }

    StyledText {
        width: parent.width
        text: "Network Monitor Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Tap any setting to cycle through values."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        // Probe Interval
        SettingRow {
            label: "Probe Interval"
            valueText: root._probeMs + " ms"
            onClicked: root.cycleProbe()
        }

        // Color Mode
        SettingRow {
            label: "Color Mode"
            valueText: root._colorMode === "soft" ? "Soft" : "Vivid"
            onClicked: {
                root._colorMode = root._colorMode === "vivid" ? "soft" : "vivid";
                pluginData.setString("colorMode", root._colorMode);
            }
        }

        // Chart Height
        SettingRow {
            label: "Chart Height"
            valueText: root._chartH + " px"
            onClicked: root.cycleChartH()
        }

        // Pill Chart Width
        SettingRow {
            label: "Pill Chart Width"
            valueText: root._pillW + " px"
            onClicked: root.cyclePillW()
        }

        // History Size
        SettingRow {
            label: "History Size"
            valueText: root._hist + " pts"
            onClicked: root.cycleHist()
        }

        // Grid Lines
        SettingRow {
            label: "Grid Lines"
            valueText: root._grid ? "Show" : "Hide"
            onClicked: {
                root._grid = !root._grid;
                pluginData.setBool("showNetworkGrid", root._grid);
            }
        }

        // Line Width
        SettingRow {
            label: "Line Width"
            valueText: root._lw + " px"
            onClicked: root.cycleLW()
        }
    }

    component SettingRow: Rectangle {
        property string label: ""
        property string valueText: ""
        signal clicked()

        width: parent.width
        height: 46
        radius: Theme.cornerRadius
        color: settingRowMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.outline

        Row {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            StyledText {
                width: parent.width * 0.45
                anchors.verticalCenter: parent.verticalCenter
                text: label
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                elide: Text.ElideRight
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: valueText
                color: Theme.primary
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: settingRowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
