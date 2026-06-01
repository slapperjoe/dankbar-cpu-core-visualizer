import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "cpuCoreVisualizer"
    property int _v: 0

    function saveSetting(key, value) {
        pluginData[key] = value;
        root.saveValue(key, value);
    }

    function setProbeInterval(ms) { saveSetting("probeInterval", ms); _v += 1; }
    function setSmoothing(pct) { saveSetting("smoothingPercent", pct); _v += 1; }
    function toggleColor() {
        saveSetting("colorMode", root.loadValue("colorMode", "vivid") === "soft" ? "vivid" : "soft");
        _v += 1;
    }
    function toggleShowPct() {
        saveSetting("showOverallPercentage", root.loadValue("showOverallPercentage", true) === false ? true : false);
        _v += 1;
    }

    // ── Dropdown helper: cycles through options ─────────────────
    property var probeOptions: [250, 500, 1000, 2000, 3000, 5000]
    property var smoothOptions: [8, 15, 28, 50, 70, 85]

    function cycleNumber(key, options, defaultValue) {
        var cur = root.loadValue(key, defaultValue);
        var idx = options.indexOf(Number(cur));
        if (idx < 0) idx = options.indexOf(defaultValue);
        var next = options[(idx + 1) % options.length];
        saveSetting(key, next);
        _v += 1;
    }
    function probeLabel() {
        var ms = root.loadValue("probeInterval", 1000);
        return ms >= 1000 ? (ms/1000).toFixed(ms===5000?0:ms===3000?0:ms===2000?0:1) + "s" : ms + "ms";
    }
    function formatProbeLabel(ms) {
        if (ms === 250) return "250ms";
        if (ms === 500) return "500ms";
        if (ms === 1000) return "1s";
        if (ms === 2000) return "2s";
        if (ms === 3000) return "3s";
        if (ms === 5000) return "5s";
        return ms + "ms";
    }
    function smoothLabel() {
        var pct = root.loadValue("smoothingPercent", 28);
        return pct + "%";
    }

    Column {
        width: parent.width
        anchors.margins: 12
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.spacingM
        topPadding: Theme.spacingM

        // ── Probe interval dropdown ────────────────────────────
        Rectangle {
            width: parent.width; height: 46; radius: Theme.cornerRadius
            color: probeRowMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh
            border.width: 1; border.color: Theme.outline
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingM
                spacing: Theme.spacingM
                StyledText {
                    text: "Probe Interval"; color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.5
                }
                StyledText {
                    text: { root._v; return root.formatProbeLabel(root.loadValue("probeInterval", 1000)); }
                    color: Theme.primary; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item { width: parent.width * 0.05; height: 1 }
                StyledText {
                    text: "▾"; color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: probeRowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.cycleNumber("probeInterval", root.probeOptions, 1000);
                }
            }
        }

        // ── Smoothing dropdown ──────────────────────────────────
        Rectangle {
            width: parent.width; height: 46; radius: Theme.cornerRadius
            color: smoothRowMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh
            border.width: 1; border.color: Theme.outline
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingM
                spacing: Theme.spacingM
                StyledText {
                    text: "Smoothing"; color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.5
                }
                StyledText {
                    text: { root._v; return root.loadValue("smoothingPercent", 28) + "%"; }
                    color: Theme.primary; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item { width: parent.width * 0.05; height: 1 }
                StyledText {
                    text: "▾"; color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: smoothRowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.cycleNumber("smoothingPercent", root.smoothOptions, 28);
                }
            }
        }

        // ── Vivid colours toggle ────────────────────────────────
        Rectangle {
            width: parent.width; height: 46; radius: Theme.cornerRadius
            color: colorMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh
            border.width: 1; border.color: Theme.outline
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingM
                spacing: Theme.spacingM
                StyledText {
                    text: "Vivid Colours"; color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.5
                }
                Rectangle {
                    width: 40; height: 22; radius: 11; anchors.verticalCenter: parent.verticalCenter
                    color: { root._v; root.loadValue("colorMode", "vivid") !== "soft" ? Theme.primary : Theme.surfaceContainerHighest; }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        x: { root._v; root.loadValue("colorMode", "vivid") !== "soft" ? 19 : 3; }
                        y: 2
                        color: Theme.surfaceContainerHigh
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                }
            }
            MouseArea {
                id: colorMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleColor()
            }
        }

        // ── Show percentage toggle ──────────────────────────────
        Rectangle {
            width: parent.width; height: 46; radius: Theme.cornerRadius
            color: pctMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh
            border.width: 1; border.color: Theme.outline
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingM
                spacing: Theme.spacingM
                StyledText {
                    text: "Show Percentage"; color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.5
                }
                Rectangle {
                    width: 40; height: 22; radius: 11; anchors.verticalCenter: parent.verticalCenter
                    color: { root._v; root.loadValue("showOverallPercentage", true) !== false ? Theme.primary : Theme.surfaceContainerHighest; }
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        x: { root._v; root.loadValue("showOverallPercentage", true) !== false ? 19 : 3; }
                        y: 2
                        color: Theme.surfaceContainerHigh
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                }
            }
            MouseArea {
                id: pctMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleShowPct()
            }
        }
    }
}
