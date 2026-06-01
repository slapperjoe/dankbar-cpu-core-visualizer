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
    function toggleColor() {
        saveSetting("colorMode", root.loadValue("colorMode", "vivid") === "soft" ? "vivid" : "soft");
        _v += 1;
    }
    function toggleShowPct() {
        saveSetting("showOverallPercentage", root.loadValue("showOverallPercentage", true) === false ? true : false);
        _v += 1;
    }

    property string expandedMenu: ""
    property var probeOptions: [250, 500, 1000, 2000, 3000, 5000]
    property var smoothOptions: [8, 15, 28, 50, 70, 85]
    property var opacityOptions: [0.05, 0.12, 0.22, 0.35, 0.50, 0.75]

    function formatProbe(ms) {
        if (ms === 250) return "250ms"; if (ms === 500) return "500ms";
        if (ms === 1000) return "1s"; if (ms === 2000) return "2s";
        if (ms === 3000) return "3s"; if (ms === 5000) return "5s";
        return ms + "ms";
    }

    Column {
        width: parent.width
        anchors.margins: 12; anchors.left: parent.left; anchors.right: parent.right
        spacing: 0; topPadding: Theme.spacingM

        // ── Probe interval dropdown ────────────────────────────
        Rectangle {
            width: parent.width; height: 44; color: "transparent"
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingS
                spacing: Theme.spacingM
                StyledText { text: "Probe Interval"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium; width: parent.width * 0.5; anchors.verticalCenter: parent.verticalCenter }
                Item { width: parent.width * 0.2; height: 1 }
                StyledText { text: { root._v; root.formatProbe(root.loadValue("probeInterval", 1000)); }; color: Theme.primary; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                StyledText { text: root.expandedMenu === "probe" ? "▴" : "▾"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.expandedMenu = root.expandedMenu === "probe" ? "" : "probe"; _v += 1; } }
        }
        Column {
            visible: root.expandedMenu === "probe"; width: parent.width
            Repeater {
                model: root.probeOptions
                delegate: Rectangle {
                    property int val: modelData
                    width: parent.width; height: 38; color: loadHover.containsMouse ? Theme.primaryHoverLight : "transparent"
                    border.width: 0; border.color: "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: { root._v; var cur = root.loadValue("probeInterval", 1000); return root.formatProbe(val) + (cur == val ? " ✓" : ""); }
                        color: { root._v; root.loadValue("probeInterval", 1000) == val ? Theme.primary : Theme.surfaceText; }
                        font.pixelSize: Theme.fontSizeSmall; font.weight: root.loadValue("probeInterval", 1000) == val ? Font.Medium : Font.Normal
                    }
                    MouseArea { id: loadHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.saveSetting("probeInterval", val); root.expandedMenu = ""; _v += 1; } }
                }
            }
        }

        // ── Smoothing dropdown ─────────────────────────────────
        Rectangle {
            width: parent.width; height: 44; color: "transparent"
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingS; spacing: Theme.spacingM
                StyledText { text: "Smoothing"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium; width: parent.width * 0.5; anchors.verticalCenter: parent.verticalCenter }
                Item { width: parent.width * 0.2; height: 1 }
                StyledText { text: { root._v; root.loadValue("smoothingPercent", 28) + "%"; }; color: Theme.primary; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                StyledText { text: root.expandedMenu === "smooth" ? "▴" : "▾"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.expandedMenu = root.expandedMenu === "smooth" ? "" : "smooth"; _v += 1; } }
        }
        Column {
            visible: root.expandedMenu === "smooth"; width: parent.width
            Repeater {
                model: root.smoothOptions
                delegate: Rectangle {
                    property int val: modelData
                    width: parent.width; height: 38; color: smoothHover.containsMouse ? Theme.primaryHoverLight : "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: { root._v; var cur = root.loadValue("smoothingPercent", 28); return val + "%" + (cur == val ? " ✓" : ""); }
                        color: { root._v; root.loadValue("smoothingPercent", 28) == val ? Theme.primary : Theme.surfaceText; }
                        font.pixelSize: Theme.fontSizeSmall; font.weight: root.loadValue("smoothingPercent", 28) == val ? Font.Medium : Font.Normal
                    }
                    MouseArea { id: smoothHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.saveSetting("smoothingPercent", val); root.expandedMenu = ""; _v += 1; } }
                }
            }
        }

        // ── Bar opacity dropdown ──────────────────────────────
        Rectangle {
            width: parent.width; height: 44; color: "transparent"
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingS; spacing: Theme.spacingM
                StyledText { text: "Bar Opacity"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium; width: parent.width * 0.5; anchors.verticalCenter: parent.verticalCenter }
                Item { width: parent.width * 0.2; height: 1 }
                StyledText { text: { root._v; var o = root.loadValue("barOpacity", 0.24); return Math.round(o * 100) + "%"; }; color: Theme.primary; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                StyledText { text: root.expandedMenu === "opacity" ? "▴" : "▾"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.expandedMenu = root.expandedMenu === "opacity" ? "" : "opacity"; _v += 1; } }
        }
        Column {
            visible: root.expandedMenu === "opacity"; width: parent.width
            Repeater {
                model: root.opacityOptions
                delegate: Rectangle {
                    property real val: modelData
                    width: parent.width; height: 38; color: opacityHover.containsMouse ? Theme.primaryHoverLight : "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: { root._v; var cur = root.loadValue("barOpacity", 0.24); return Math.round(val * 100) + "%" + (Math.abs(cur - val) < 0.01 ? " ✓" : ""); }
                        color: { root._v; Math.abs(root.loadValue("barOpacity", 0.24) - val) < 0.01 ? Theme.primary : Theme.surfaceText; }
                        font.pixelSize: Theme.fontSizeSmall; font.weight: Math.abs(root.loadValue("barOpacity", 0.24) - val) < 0.01 ? Font.Medium : Font.Normal
                    }
                    MouseArea { id: opacityHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.saveSetting("barOpacity", val); root.expandedMenu = ""; _v += 1; } }
                }
            }
        }

        // ── Vivid colours switch ──────────────────────────────
        Rectangle {
            width: parent.width; height: 44; color: "transparent"
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingS; spacing: Theme.spacingM
                StyledText { text: "Vivid Colours"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.55 }
                Rectangle { width: 40; height: 22; radius: 11; anchors.verticalCenter: parent.verticalCenter; color: { root._v; root.loadValue("colorMode", "vivid") !== "soft" ? Theme.primary : Theme.surfaceContainerHighest; }
                    Rectangle { width: 18; height: 18; radius: 9; y: 2; x: { root._v; root.loadValue("colorMode", "vivid") !== "soft" ? 19 : 3; }; color: Theme.surfaceContainerHigh; Behavior on x { NumberAnimation { duration: 150 } } }
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleColor() }
        }

        // ── Show percentage switch ──────────────────────────
        Rectangle {
            width: parent.width; height: 44; color: "transparent"
            Row {
                anchors.fill: parent; anchors.margins: Theme.spacingS; spacing: Theme.spacingM
                StyledText { text: "Show Percentage"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.55 }
                Rectangle { width: 40; height: 22; radius: 11; anchors.verticalCenter: parent.verticalCenter; color: { root._v; root.loadValue("showOverallPercentage", true) !== false ? Theme.primary : Theme.surfaceContainerHighest; }
                    Rectangle { width: 18; height: 18; radius: 9; y: 2; x: { root._v; root.loadValue("showOverallPercentage", true) !== false ? 19 : 3; }; color: Theme.surfaceContainerHigh; Behavior on x { NumberAnimation { duration: 150 } } }
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleShowPct() }
        }
    }
}
