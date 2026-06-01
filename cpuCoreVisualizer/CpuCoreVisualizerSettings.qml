import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "cpuCoreVisualizer"

    StyledText {
        width: parent.width
        text: "CPU Core Visualizer"
        font.pixelSize: Theme.fontSizeLarge; font.weight: Font.Bold; color: Theme.surfaceText
    }
    StyledText {
        width: parent.width
        text: "Per-core CPU usage bars for DankBar."
        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText; wrapMode: Text.WordWrap
    }

    // ── Probe interval ────────────────────────────────────────────────
    StyledText {
        width: parent.width; text: "Probe Interval"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Row {
        width: parent.width; spacing: Theme.spacingS
        Repeater {
            model: [250, 500, 1000, 2000, 3000, 5000]
            delegate: Rectangle {
                property int msValue: modelData
                width: (parent.width - 5 * Theme.spacingS) / 6; height: 36; radius: Theme.cornerRadius
                color: pluginData["probeInterval"] === msValue || (pluginData["probeInterval"] === undefined && msValue === 1000) ? Theme.primary : Theme.surfaceContainerHigh
                border.width: 1; border.color: Theme.outline
                StyledText {
                    anchors.centerIn: parent; text: msValue >= 1000 ? (msValue / 1000) + "s" : msValue + "ms"
                    color: pluginData["probeInterval"] === msValue || (pluginData["probeInterval"] === undefined && msValue === 1000) ? Theme.surfaceContainerHigh : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pluginData["probeInterval"] = msValue }
            }
        }
    }

    // ── Smoothing ─────────────────────────────────────────────────────
    StyledText {
        width: parent.width; text: "Animation Smoothing"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Row {
        width: parent.width; spacing: Theme.spacingS
        Repeater {
            model: [8, 15, 28, 50, 70, 85]
            delegate: Rectangle {
                property int pctValue: modelData
                width: (parent.width - 5 * Theme.spacingS) / 6; height: 36; radius: Theme.cornerRadius
                color: pluginData["smoothingPercent"] === pctValue || (pluginData["smoothingPercent"] === undefined && pctValue === 28) ? Theme.primary : Theme.surfaceContainerHigh
                border.width: 1; border.color: Theme.outline
                StyledText {
                    anchors.centerIn: parent; text: pctValue + "%"
                    color: pluginData["smoothingPercent"] === pctValue || (pluginData["smoothingPercent"] === undefined && pctValue === 28) ? Theme.surfaceContainerHigh : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pluginData["smoothingPercent"] = pctValue }
            }
        }
    }

    // ── Color mode ────────────────────────────────────────────────────
    StyledText {
        width: parent.width; text: "Vivid Colours"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Rectangle {
        width: parent.width; height: 36; radius: Theme.cornerRadius
        color: pluginData["colorMode"] !== "soft" ? Theme.primary : Theme.surfaceContainerHigh
        border.width: 1; border.color: Theme.outline
        StyledText {
            anchors.centerIn: parent
            text: pluginData["colorMode"] !== "soft" ? "Vivid (on)" : "Soft (off)"
            color: pluginData["colorMode"] !== "soft" ? Theme.surfaceContainerHigh : Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: pluginData["colorMode"] = pluginData["colorMode"] === "soft" ? "vivid" : "soft"
        }
    }

    // ── Show overall percentage ───────────────────────────────────────
    StyledText {
        width: parent.width; text: "Show Overall Percentage"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Rectangle {
        width: parent.width; height: 36; radius: Theme.cornerRadius
        color: pluginData["showOverallPercentage"] !== false ? Theme.primary : Theme.surfaceContainerHigh
        border.width: 1; border.color: Theme.outline
        StyledText {
            anchors.centerIn: parent
            text: pluginData["showOverallPercentage"] !== false ? "Visible" : "Hidden"
            color: pluginData["showOverallPercentage"] !== false ? Theme.surfaceContainerHigh : Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: pluginData["showOverallPercentage"] = pluginData["showOverallPercentage"] === false ? true : false
        }
    }
}
