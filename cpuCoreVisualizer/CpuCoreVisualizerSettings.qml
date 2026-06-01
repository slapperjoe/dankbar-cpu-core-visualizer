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

    StyledText {
        width: parent.width
        text: "How often CPU stats are refreshed."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
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
            value: Number(pluginData["probeInterval"]) || 1000
            anchors.verticalCenter: parent.verticalCenter
            onValueChanged: {
                pluginData["probeInterval"] = Math.round(value);
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

    StyledText {
        width: parent.width
        text: "Lower values glide more; higher values snap faster."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
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
            value: Number(pluginData["smoothingPercent"]) || 28
            anchors.verticalCenter: parent.verticalCenter
            onValueChanged: {
                pluginData["smoothingPercent"] = Math.round(value);
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

    // ── Color mode ────────────────────────────────────────────────────
    StyledText {
        width: parent.width
        text: "Colour Mode"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    Row {
        width: parent.width
        spacing: Theme.spacingS

        Rectangle {
            width: (parent.width - Theme.spacingS) / 2
            height: 36
            radius: Theme.cornerRadius
            color: pluginData["colorMode"] === "vivid" || pluginData["colorMode"] === undefined ? Theme.primary : Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outline

            StyledText {
                anchors.centerIn: parent
                text: "Vivid"
                color: pluginData["colorMode"] === "vivid" || pluginData["colorMode"] === undefined ? Theme.surfaceContainerHigh : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    pluginData["colorMode"] = "vivid";
                }
            }
        }

        Rectangle {
            width: (parent.width - Theme.spacingS) / 2
            height: 36
            radius: Theme.cornerRadius
            color: pluginData["colorMode"] === "soft" ? Theme.primary : Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outline

            StyledText {
                anchors.centerIn: parent
                text: "Soft"
                color: pluginData["colorMode"] === "soft" ? Theme.surfaceContainerHigh : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    pluginData["colorMode"] = "soft";
                }
            }
        }
    }

    // ── Show overall percentage ───────────────────────────────────────
    StyledText {
        width: parent.width
        text: "Show Overall Percentage"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    Row {
        width: parent.width
        spacing: Theme.spacingS

        Rectangle {
            width: (parent.width - Theme.spacingS) / 2
            height: 36
            radius: Theme.cornerRadius
            color: pluginData["showOverallPercentage"] !== false ? Theme.primary : Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outline

            StyledText {
                anchors.centerIn: parent
                text: "Show"
                color: pluginData["showOverallPercentage"] !== false ? Theme.surfaceContainerHigh : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    pluginData["showOverallPercentage"] = true;
                }
            }
        }

        Rectangle {
            width: (parent.width - Theme.spacingS) / 2
            height: 36
            radius: Theme.cornerRadius
            color: pluginData["showOverallPercentage"] === false ? Theme.primary : Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outline

            StyledText {
                anchors.centerIn: parent
                text: "Hide"
                color: pluginData["showOverallPercentage"] === false ? Theme.surfaceContainerHigh : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    pluginData["showOverallPercentage"] = false;
                }
            }
        }
    }
}
