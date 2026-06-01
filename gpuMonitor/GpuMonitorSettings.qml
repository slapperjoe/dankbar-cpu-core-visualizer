import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "gpuMonitor"

    StyledText {
        width: parent.width
        text: "GPU Monitor"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }
    StyledText {
        width: parent.width
        text: "GPU usage bars and temperature monitoring."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width; text: "Probe Interval"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium
        color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Row {
        width: parent.width; spacing: Theme.spacingM
        Slider {
            id: probeSlider; width: parent.width - 80
            from: 500; to: 10000; stepSize: 500
            value: Number(pluginData["probeInterval"] != null ? pluginData["probeInterval"] : 3000)
            anchors.verticalCenter: parent.verticalCenter
            onValueChanged: pluginData["probeInterval"] = Math.round(value)
        }
        StyledText {
            text: Math.round(probeSlider.value) + " ms"; width: 70
            font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight
        }
    }

    StyledText {
        width: parent.width; text: "Smoothing"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium
        color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Row {
        width: parent.width; spacing: Theme.spacingM
        Slider {
            id: smoothSlider; width: parent.width - 80
            from: 1; to: 99; stepSize: 1
            value: Number(pluginData["smoothingPercent"] != null ? pluginData["smoothingPercent"] : 15)
            anchors.verticalCenter: parent.verticalCenter
            onValueChanged: pluginData["smoothingPercent"] = Math.round(value)
        }
        StyledText {
            text: Math.round(smoothSlider.value) + "%"; width: 70
            font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight
        }
    }

    StyledText {
        width: parent.width; text: "Vivid Colours"
        font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium
        color: Theme.surfaceText; topPadding: Theme.spacingM
    }
    Switch {
        checked: pluginData["colorMode"] !== "soft"
        onToggled: pluginData["colorMode"] = checked ? "vivid" : "soft"
    }
}
