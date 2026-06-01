import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "cpuCoreVisualizer"

    StyledText {
        width: parent.width
        text: "CPU Core Visualizer"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Per-core CPU usage bars for DankBar."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    // ── Probe interval ────────────────────────────────────────────────
    StyledText {
        width: parent.width
        text: "Probe Interval"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM

        Slider {
            id: probeSlider
            width: parent.width - 80
            from: 250
            to: 5000
            stepSize: 250
            value: Number(pluginData["probeInterval"] !== undefined ? pluginData["probeInterval"] : 1000)
            anchors.verticalCenter: parent.verticalCenter
            onValueChanged: {
                pluginData["probeInterval"] = Math.round(value);
                console.log("cpu-settings: wrote probeInterval=" + Math.round(value));
            }
        }

        StyledText {
            text: Math.round(probeSlider.value) + " ms"
            width: 70
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
        }
    }

    // ── Smoothing ─────────────────────────────────────────────────────
    StyledText {
        width: parent.width
        text: "Animation Smoothing"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM

        Slider {
            id: smoothingSlider
            width: parent.width - 80
            from: 8
            to: 85
            stepSize: 1
            value: Number(pluginData["smoothingPercent"] !== undefined ? pluginData["smoothingPercent"] : 28)
            anchors.verticalCenter: parent.verticalCenter
            onValueChanged: {
                pluginData["smoothingPercent"] = Math.round(value);
                console.log("cpu-settings: wrote smoothingPercent=" + Math.round(value));
            }
        }

        StyledText {
            text: Math.round(smoothingSlider.value) + "%"
            width: 70
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
        }
    }

    // ── Color mode toggle ─────────────────────────────────────────────
    StyledText {
        width: parent.width
        text: "Vivid Colours"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    Switch {
        checked: pluginData["colorMode"] !== "soft"
        onToggled: {
            pluginData["colorMode"] = checked ? "vivid" : "soft";
            console.log("cpu-settings: wrote colorMode=" + pluginData["colorMode"]);
        }
    }

    // ── Show overall percentage toggle ─────────────────────────────────
    StyledText {
        width: parent.width
        text: "Show Overall Percentage"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    Switch {
        checked: pluginData["showOverallPercentage"] !== false
        onToggled: pluginData["showOverallPercentage"] = checked
    }
}
