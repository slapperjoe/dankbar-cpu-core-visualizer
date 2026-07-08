import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "gpuMonitor"

    property int _v: 0

    function setProbeInterval(ms) { pluginData["probeInterval"] = ms; saveValue("probeInterval", ms); _v += 1; }
    function setSmoothing(pct) { pluginData["smoothingPercent"] = pct; saveValue("smoothingPercent", pct); _v += 1; }
    function setBarWidth(w) { pluginData["barWidth"] = w; saveValue("barWidth", w); _v += 1; }
    function toggleColorMode() { var m = pluginData["colorMode"] === "soft" ? "vivid" : "soft"; pluginData["colorMode"] = m; saveValue("colorMode", m); _v += 1; }
    function isActive(key, value, fallbackValue) {
        _v;
        var stored = pluginData[key];
        if (stored === undefined) return value === fallbackValue;
        return stored === value;
    }

    StyledText {
        width: parent.width; text: "GPU Monitor"
        font.pixelSize: Theme.fontSizeLarge; font.weight: Font.Bold; color: Theme.surfaceText
    }
    StyledText {
        width: parent.width; text: "GPU usage bars and temperature monitoring."
        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText; wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width; text: "Probe Interval"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Row {
        width: parent.width; spacing: Theme.spacingS
        Repeater {
            model: [500, 1000, 2000, 3000, 5000, 10000]
            delegate: Rectangle {
                property int msValue: modelData
                width: (parent.width - 5 * Theme.spacingS) / 6; height: 36; radius: Theme.cornerRadius
                color: root.isActive("probeInterval", msValue, 3000) ? Theme.primary : Theme.surfaceContainerHigh
                border.width: 1; border.color: Theme.outline
                StyledText {
                    anchors.centerIn: parent; text: msValue >= 1000 ? (msValue/1000)+"s" : msValue+"ms"
                    color: root.isActive("probeInterval", msValue, 3000) ? Theme.surfaceContainerHigh : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setProbeInterval(msValue) }
            }
        }
    }

    StyledText {
        width: parent.width; text: "Smoothing"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Row {
        width: parent.width; spacing: Theme.spacingS
        Repeater {
            model: [5, 15, 30, 50, 70, 90]
            delegate: Rectangle {
                property int pctValue: modelData
                width: (parent.width - 5 * Theme.spacingS) / 6; height: 36; radius: Theme.cornerRadius
                color: root.isActive("smoothingPercent", pctValue, 15) ? Theme.primary : Theme.surfaceContainerHigh
                border.width: 1; border.color: Theme.outline
                StyledText {
                    anchors.centerIn: parent; text: pctValue + "%"
                    color: root.isActive("smoothingPercent", pctValue, 15) ? Theme.surfaceContainerHigh : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setSmoothing(pctValue) }
            }
        }
    }

    StyledText {
        width: parent.width; text: "Vivid Colours"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Rectangle {
        width: parent.width; height: 36; radius: Theme.cornerRadius
        color: { root._v; pluginData["colorMode"] !== "soft" ? Theme.primary : Theme.surfaceContainerHigh; }
        border.width: 1; border.color: Theme.outline
        StyledText {
            anchors.centerIn: parent
            text: { root._v; pluginData["colorMode"] !== "soft" ? "Vivid (on)" : "Soft (off)"; }
            color: { root._v; pluginData["colorMode"] !== "soft" ? Theme.surfaceContainerHigh : Theme.surfaceText; }
            font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleColorMode() }
    }

    StyledText {
        width: parent.width; text: "Bar Width"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Row {
        width: parent.width; spacing: Theme.spacingS
        Repeater {
            model: [3, 5, 7, 9, 11, 14]
            delegate: Rectangle {
                property int wValue: modelData
                width: (parent.width - 5 * Theme.spacingS) / 6; height: 36; radius: Theme.cornerRadius
                color: root.isActive("barWidth", wValue, 7) ? Theme.primary : Theme.surfaceContainerHigh
                border.width: 1; border.color: Theme.outline
                StyledText {
                    anchors.centerIn: parent; text: wValue + "px"
                    color: root.isActive("barWidth", wValue, 4) ? Theme.surfaceContainerHigh : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setBarWidth(wValue) }
            }
        }
    }


}
