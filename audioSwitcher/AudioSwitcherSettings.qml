import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets
import Quickshell.Services.Pipewire

PluginSettings {
    id: root
    pluginId: "audioSwitcher"

    property var audioSinks: []
    property var enabledSinks: []

    Timer {
        id: sinksTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            try {
                var sinks = AudioService.getAvailableSinks();
                if (sinks && Array.isArray(sinks)) {
                    root.audioSinks = sinks;
                    var stored = pluginData["audioQuickSwitchEnabledSinks"];
                    var enabledNames = [];
                    if (stored && Array.isArray(stored)) {
                        enabledNames = stored;
                    } else if (typeof stored === "string" && stored.length > 0) {
                        enabledNames = [stored];
                    } else {
                        enabledNames = root.audioSinks.map(function(s) { return s.name; });
                    }
                    root.enabledSinks = enabledNames;
                    sinksTimer.stop();
                }
            } catch (e) {
                // Keep retrying
            }
        }
    }

    property bool sinksLoaded: root.audioSinks.length > 0

    function sinkLabel(sink) {
        return AudioService.displayName(sink) || sink.description || sink.name;
    }

    function isSinkActive(sink) {
        if (!sink) return false;
        var current = AudioService.sink;
        if (!current) return false;
        // AudioService.sink can be a sink object or a string name
        var currentName = typeof current === "string" ? current : (current.name || null);
        return sink.name === currentName;
    }

    function toggleSink(name) {
        var index = root.enabledSinks.indexOf(name);
        var copy = root.enabledSinks.slice();
        if (index >= 0) {
            copy.splice(index, 1);
        } else {
            copy.push(name);
        }
        root.enabledSinks = copy;
        pluginData["audioQuickSwitchEnabledSinks"] = copy.slice();
    }

    StyledText {
        width: parent.width
        text: "Audio Switcher Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Sinks detected: " + root.audioSinks.length
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        Repeater {
            model: root.audioSinks

            delegate: Rectangle {
                property var sink: modelData
                property bool isActive: root.isSinkActive(sink)
                width: parent.width
                height: 48
                radius: Theme.cornerRadius
                opacity: isActive ? 0.5 : 1.0
                color: root.enabledSinks.includes(sink.name) ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (parent.isActive) return;
                        root.toggleSink(parent.sink.name);
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Rectangle {
                        width: Theme.iconSize
                        height: width
                        radius: 3
                        border.width: 1
                        border.color: Theme.outline
                        color: root.enabledSinks.includes(sink.name) ? Theme.primary : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: "check"
                            size: Theme.iconSize - 4
                            color: "white"
                            filled: true
                            visible: root.enabledSinks.includes(sink.name)
                        }
                    }

                    StyledText {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.iconSize + Theme.spacingM
                        text: root.sinkLabel(sink)
                        color: root.enabledSinks.includes(sink.name) ? Theme.primary : Theme.surfaceText
                        font.weight: root.enabledSinks.includes(sink.name) ? Font.Medium : Font.Normal
                    }
                }
            }
        }
    }
}
