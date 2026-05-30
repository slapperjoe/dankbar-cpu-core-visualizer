import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var audioSinks: []
    property int activeSinkIndex: 0

    readonly property string currentDeviceName: {
        if (AudioService.sink) {
            return AudioService.displayName(AudioService.sink) || AudioService.sink.description || "Audio output";
        }
        return "No audio output";
    }

    readonly property string currentDeviceIcon: {
        if (!AudioService.sink)
            return "speaker";
        const icon = String(AudioService.sinkIcon(AudioService.sink) || "speaker");
        if (icon === "tv") return "monitor";
        if (icon === "headset") return "headset";
        return "speaker";
    }

    readonly property var quickSwitchSinks: {
        const primary = pluginData["audioQuickSwitchPrimary"] || "";
        const secondary = pluginData["audioQuickSwitchSecondary"] || "";
        const configuredNames = [primary, secondary].filter(n => n && n.length > 0);
        if (configuredNames.length >= 2) {
            return root.audioSinks.filter(s => configuredNames.includes(s.name));
        }
        return root.audioSinks;
    }

    readonly property bool quickSwitchEnabled: pluginData["audioQuickSwitchEnabled"] === true || pluginData["audioQuickSwitchEnabled"] === "true"

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

    function logToFile(message) {
        console.error("[AudioSwitcher]", message);
        try {
            var logFile = new File("/tmp/dms-audioSwitcher.log");
            if (logFile.open(File.AppendOnly)) {
                logFile.writeLine("[" + new Date().toISOString() + "] " + message);
                logFile.close();
            }
        } catch(e) {
            // File logging failed, stderr still works
        }
    }

    function refreshAudioSinks() {
        const sinks = AudioService.getAvailableSinks();
        if (Array.isArray(sinks)) {
            root.audioSinks = sinks;
            console.error("[AudioSwitcher] Found", root.audioSinks.length, "sinks");
            for (let i = 0; i < root.audioSinks.length; i++) {
                if (AudioService.sink && root.audioSinks[i].name === AudioService.sink.name) {
                    root.activeSinkIndex = i;
                    console.error("[AudioSwitcher] Active sink:", i, "-", AudioService.displayName(AudioService.sink));
                    return;
                }
            }
        } else {
            root.audioSinks = [];
            console.error("[AudioSwitcher] AudioService not available");
        }
        root.activeSinkIndex = 0;
    }

    function isSinkActive(sink) {
        if (!sink) return false;
        return Boolean(AudioService.sink && sink.name && AudioService.sink.name && sink.name === AudioService.sink.name);
    }

    function selectAudioOutput(sink) {
        if (!sink) return false;
        Pipewire.preferredDefaultAudioSink = sink;
        root.activeSinkIndex = root.audioSinks.indexOf(sink);
        return true;
    }

    function sinkIconName(sink) {
        if (!sink) return "speaker";
        const icon = String(AudioService.sinkIcon(sink) || "speaker");
        if (icon === "tv") return "monitor";
        if (icon === "headset") return "headset";
        return "speaker";
    }

    function sinkLabel(sink) {
        if (!sink) return "No audio output";
        return AudioService.displayName(sink) || sink.description || sink.name || "Audio output";
    }

    // ── Bar Widget (icon-only, no text) ─────────────────────
    horizontalBarPill: Component {
        Rectangle {
            width: root.barThickness
            height: root.barThickness
            radius: Theme.cornerRadius
            color: pillMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

            DankIcon {
                anchors.centerIn: parent
                name: root.currentDeviceIcon
                size: Math.min(root.barThickness - 6, Theme.iconSize + 2)
                color: Theme.widgetTextColor
                filled: true
            }

            MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.logToFile("[AudioSwitcher] Left-click: opening popout");
                    root.openPopout();
                }
            }
        }
    }

    verticalBarPill: Component {
        Rectangle {
            width: root.barThickness
            height: width
            radius: Theme.cornerRadius
            color: pillMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

            DankIcon {
                anchors.centerIn: parent
                name: root.currentDeviceIcon
                size: Math.min(parent.width - 6, Theme.iconSize + 2)
                color: Theme.widgetTextColor
                filled: true
            }

            MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.logToFile("[AudioSwitcher] Left-click: opening popout");
                    root.openPopout();
                }
            }
        }
    }

    pillClickAction: function() {
        root.openPopout();
    }

    pillRightClickAction: function(posX, posY, posWidth, sectionName, currentScreen) {
        root.logToFile("[AudioSwitcher] Right-click: opening popout");
        root.openPopout();
    }

    function openPopout() {
        var popout = null;
        for (var i = 0; i < root.children.length; i++) {
            if (typeof root.children[i].setTriggerPosition === "function") {
                popout = root.children[i];
                break;
            }
        }
        if (popout) {
            var pill = root.isVertical ? root.verticalPill : root.horizontalPill;
            var globalPos = pill.mapToItem(null, 0, 0);
            var screen = root.parentScreen || Screen;
            var barPosition = axis?.edge === "left" ? 2 : (axis?.edge === "right" ? 3 : (axis?.edge === "top" ? 0 : 1));
            var pos = SettingsData.getPopupTriggerPosition(globalPos, screen, barThickness, pill.width, barSpacing, barPosition, barConfig);
            popout.setTriggerPosition(pos.x, pos.y, pos.width, root.section, screen, barPosition, barThickness, barSpacing, barConfig);
            popout.toggle();
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Audio Output Devices"
            detailsText: "Click to switch"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                Flow {
                    id: sinkFlow
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: root.quickSwitchSinks.length > 1

                    Repeater {
                        model: root.quickSwitchSinks

                        delegate: Rectangle {
                            required property var modelData
                            width: Math.max(110, Math.min(180, (sinkFlow.width - sinkFlow.spacing) / 2)
                            height: 52
                            radius: Theme.cornerRadius
                            color: root.isSinkActive(modelData) ? Theme.primaryHoverLight : Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: root.isSinkActive(modelData) ? Theme.primary : Theme.outline

                            DankRipple {
                                id: sinkRipple
                                cornerRadius: parent.radius
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: mouse => sinkRipple.trigger(mouse.x, mouse.y)
                                onClicked: {
                                    root.selectAudioOutput(parent.modelData);
                                    popout.closePopout();
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                spacing: Theme.spacingS

                                DankIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: root.sinkIconName(modelData)
                                    size: Theme.iconSize
                                    color: root.isSinkActive(modelData) ? Theme.primary : Theme.surfaceText
                                    filled: true
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - Theme.iconSize - Theme.spacingS
                                    text: root.sinkLabel(modelData)
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: root.isSinkActive(modelData) ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 72
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: root.currentDeviceIcon
                            size: Theme.iconSizeLarge
                            color: Theme.primary
                            filled: true
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Theme.iconSizeLarge - Theme.spacingM * 2
                            spacing: Theme.spacingXS

                            StyledText {
                                width: parent.width
                                text: root.currentDeviceName
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width
                                text: AudioService.sink ? AudioService.subtitle(AudioService.sink.name || "") : ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                elide: Text.ElideRight
                                visible: AudioService.sink && (AudioService.subtitle(AudioService.sink.name || "").length > 0)
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 350
    popoutHeight: 320
}