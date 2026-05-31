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
                    // Load persisted enabled sinks
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
                    // Stop retrying once we have data
                    sinksTimer.stop();
                }
            } catch (e) {
                // Keep retrying
            }
        }
    }

    // Custom function to toggle a sink's enabled state
    function toggleSink(name) {
        var index = root.enabledSinks.indexOf(name);
        if (index >= 0) {
            root.enabledSinks.splice(index, 1);
        } else {
            root.enabledSinks.push(name);
        }
        pluginData["audioQuickSwitchEnabledSinks"] = root.enabledSinks.slice();
    }

    // Settings content: list of all sinks with checkboxes
    content: ScrollView {
        width: parent.width
        height: parent.height

        Column {
            id: sinkList
            width: parent.width
            spacing: Theme.spacingS

            Repeater {
                model: root.audioSinks

                delegate: Rectangle {
                    required property var sink
                    width: parent.width
                    height: 48
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Row {
                        id: row
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        // Checkbox
                        Rectangle {
                            id: box
                            width: Theme.iconSize
                            height: width
                            radius: 3
                            border.width: 1
                            border.color: Theme.outline
                            color: root.enabledSinks.includes(parent.sink.name) ? Theme.primary : "transparent"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.toggleSink(parent.sink.name);
                                }
                            }

                            DankIcon {
                                anchors.centerIn: parent
                                name: "check"
                                size: Theme.iconSize - 4
                                color: "white"
                                filled: true
                                visible: root.enabledSinks.includes(parent.sink.name)
                            }
                        }

                        StyledText {
                            text: AudioService.displayName(parent.sink) || parent.sink.description || parent.sink.name
                            color: Theme.surfaceText
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
