import QtQuick
import Quickshell.Services.Pipewire
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var audioSinks: []
    property int activeSinkIndex: 0

    readonly property string currentDeviceName: {
        if (root.audioSinks.length <= 0)
            return "No sinks";
        const sink = root.audioSinks[root.activeSinkIndex] || root.audioSinks[0];
        return sink ? (sink.description || sink.name || "Unknown") : "Unknown";
    }

    Timer {
        id: refreshTimer
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refreshAudioSinks()
    }

    Component.onCompleted: {
        root.logToFile("[AudioSwitcher] Loading plugin...");
        root.refreshAudioSinks();
        root.logToFile("[AudioSwitcher] Loaded");
    }

    Component.onDestruction: {
        refreshTimer.running = false;
    }

    // Log to stderr (visible in journalctl for DMS)
    function logToFile(message) {
        console.error("[AudioSwitcher]", message);
    }

    function refreshAudioSinks() {
        if (Pipewire && Pipewire.nodes) {
            root.audioSinks = Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream);
            console.error("[AudioSwitcher] Found", root.audioSinks.length, "sinks");
        } else {
            root.audioSinks = [];
            console.error("[AudioSwitcher] Pipewire not available");
            return;
        }
        for (let i = 0; i < root.audioSinks.length; i++) {
            if (Pipewire.defaultAudioSink && root.audioSinks[i].name === Pipewire.defaultAudioSink.name) {
                root.activeSinkIndex = i;
                console.error("[AudioSwitcher] Active sink:", i, "-", root.audioSinks[i].description || root.audioSinks[i].name);
                return;
            }
        }
        root.activeSinkIndex = 0;
    }

    function switchToSink(index) {
        if (index < 0 || index >= root.audioSinks.length)
            return;
        const sink = root.audioSinks[index];
        Pipewire.preferredDefaultAudioSink = sink;
        root.activeSinkIndex = index;
        if (pluginService && pluginService.savePluginData)
            pluginService.savePluginData(pluginId, "lastSink", sink.name);
        console.error("[AudioSwitcher] Switched to:", sink.description || sink.name);
    }

    // ── Bar Widget ────────────────────────────────────────
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: "volume_up"
                size: Theme.iconSize
                color: Theme.widgetTextColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentDeviceName
                color: Theme.widgetTextColor
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    // Left-click: cycle to next sink
    pillClickAction: function() {
        if (root.audioSinks.length < 2) {
            ToastService.showInfo("Need at least 2 sinks to cycle");
            return;
        }
        const nextIndex = (root.activeSinkIndex + 1) % root.audioSinks.length;
        root.switchToSink(nextIndex);
    }

    // Right-click: show sink list popout
    // Called from BasePill.onRightClicked; params are already computed
    pillRightClickAction: function(posX, posY, posWidth, sectionName, currentScreen) {
        root.logToFile("[AudioSwitcher] pillRightClickAction called at " + posX + ", " + posY);
        // pluginPopout is defined in PluginComponent.qml — find it via children
        var popout = null;
        for (var i = 0; i < root.children.length; i++) {
            if (typeof root.children[i].setTriggerPosition === "function") {
                popout = root.children[i];
                break;
            }
        }
        if (popout) {
            var barPosition = axis?.edge === "left" ? 2 : (axis?.edge === "right" ? 3 : (axis?.edge === "top" ? 0 : 1));
            popout.setTriggerPosition(posX, posY, posWidth, sectionName, currentScreen, barPosition, barThickness, barSpacing, barConfig);
            popout.toggle();
            root.logToFile("[AudioSwitcher] Popout toggled");
        } else {
            root.logToFile("[AudioSwitcher] ERROR: popout not found in children");
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Audio Output Devices"
            detailsText: "Click to switch"
            showCloseButton: true

            ListView {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                model: root.audioSinks

                delegate: Rectangle {
                    width: parent.width
                    height: 48
                    radius: Theme.cornerRadius
                    color: (index === root.activeSinkIndex) ? Theme.primary : Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outline

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.switchToSink(index);
                            popout.closePopout();
                        }

                        StyledText {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            text: modelData.description || modelData.name || "Unknown"
                            color: (index === root.activeSinkIndex) ? Theme.primaryText : Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 350
    popoutHeight: 400
}
