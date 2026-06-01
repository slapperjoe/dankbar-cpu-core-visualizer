import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "gpuMonitor"

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
                color: pluginData["probeInterval"] === msValue || (pluginData["probeInterval"] === undefined && msValue === 3000) ? Theme.primary : Theme.surfaceContainerHigh
                border.width: 1; border.color: Theme.outline
                StyledText {
                    anchors.centerIn: parent; text: msValue >= 1000 ? (msValue/1000)+"s" : msValue+"ms"
                    color: pluginData["probeInterval"] === msValue || (pluginData["probeInterval"] === undefined && msValue === 3000) ? Theme.surfaceContainerHigh : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pluginData["probeInterval"] = msValue }
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
                color: pluginData["smoothingPercent"] === pctValue || (pluginData["smoothingPercent"] === undefined && pctValue === 15) ? Theme.primary : Theme.surfaceContainerHigh
                border.width: 1; border.color: Theme.outline
                StyledText {
                    anchors.centerIn: parent; text: pctValue + "%"
                    color: pluginData["smoothingPercent"] === pctValue || (pluginData["smoothingPercent"] === undefined && pctValue === 15) ? Theme.surfaceContainerHigh : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pluginData["smoothingPercent"] = pctValue }
            }
        }
    }

    StyledText {
        width: parent.width; text: "Vivid Colours"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Rectangle {
        width: parent.width; height: 36; radius: Theme.cornerRadius
        color: pluginData["colorMode"] !== "soft" ? Theme.primary : Theme.surfaceContainerHigh
        border.width: 1; border.color: Theme.outline
        StyledText {
            anchors.centerIn: parent; text: pluginData["colorMode"] !== "soft" ? "Vivid (on)" : "Soft (off)"
            color: pluginData["colorMode"] !== "soft" ? Theme.surfaceContainerHigh : Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall; font.weight: Font.Medium
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: pluginData["colorMode"] = pluginData["colorMode"] === "soft" ? "vivid" : "soft"
        }
    }
}
