import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "memoryMonitor"

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        // ── Header ──────────────────────────────────────────
        StyledText {
            width: parent.width
            text: "Memory Monitor Settings"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width
            text: "Configure polling, appearance, and animation for the memory usage monitor."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        // ── Probe Interval ──────────────────────────────────
        StyledText {
            text: "Probe Interval"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        StyledText {
            text: "How often to request fresh memory stats (ms)"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        Row {
            spacing: 8

            Slider {
                id: probeSlider
                from: 500
                to: 10000
                stepSize: 500
                value: pluginData["probeInterval"] || 3000
                onValueChanged: pluginData["probeInterval"] = value
            }

            StyledText {
                text: Math.round(probeSlider.value) + " ms"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                width: 60
            }
        }

        // ── Color Mode ──────────────────────────────────────
        StyledText {
            text: "Color Mode"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        StyledText {
            text: "Bar color palette: vivid (bright) or soft (muted)"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        Row {
            spacing: 8

            Button {
                text: "Vivid"
                checked: (pluginData["colorMode"] || "vivid") === "vivid"
                checkable: true
                onClicked: pluginData["colorMode"] = "vivid"
            }

            Button {
                text: "Soft"
                checked: (pluginData["colorMode"] || "vivid") === "soft"
                checkable: true
                onClicked: pluginData["colorMode"] = "soft"
            }
        }

        // ── Smoothing ───────────────────────────────────────
        StyledText {
            text: "Smoothing"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceText
        }

        StyledText {
            text: "Animation smoothing factor (higher = smoother but slower)"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        Row {
            spacing: 8

            Slider {
                id: smoothingSlider
                from: 1
                to: 99
                stepSize: 1
                value: pluginData["smoothingPercent"] || 15
                onValueChanged: pluginData["smoothingPercent"] = value
            }

            StyledText {
                text: Math.round(smoothingSlider.value) + "%"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                width: 40
            }
        }
    }
}
