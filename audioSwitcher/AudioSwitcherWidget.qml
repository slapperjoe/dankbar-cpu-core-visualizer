import Qt 6.7
import QtQuick 2.15
import QtQuick.Layouts 6.7
import io.github.dankmachines.dankmaterialshell.theming 1.0 as Theme
import io.github.dankmachines.dankmaterialshell.plugins 1.0 as DankPlugins

PluginComponent {
    id: root

    // ── Properties ─────────────────────────────────────────────
    property var pluginData: DankPlugins.PluginStorage
    property bool isDesktopWidget: false

    // Audio settings
    property string defaultDevice: "auto"
    property bool showPanelOnClick: true

    // Audio sinks
    property var audioSinks: []
    property int activeSinkIndex: 0

    readonly property string currentDeviceName: {
        if (root.audioSinks.length <= 0)
            return "No sinks available";
        const sink = root.audioSinks[root.activeSinkIndex] || root.audioSinks[0];
        return sink ? (sink.description || sink.name || "Unknown") : "Unknown";
    }

    // Timer to refresh sinks
    Timer {
        id: refreshTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refreshAudioSinks()
    }

    Component.onCompleted: {
        root.isDesktopWidget = (root.barConfig === undefined || root.barConfig === null);
        root.defaultDevice = root.pluginData.stringSetting("defaultDevice", "auto");
        root.showPanelOnClick = root.pluginData.boolSetting("showPanelOnClick", true);
        root.refreshAudioSinks();
    }

    Component.onDestruction: {
        // No DgopService refs needed for audio
    }

    // ── Functions ──────────────────────────────────────────────
    function refreshAudioSinks() {
        root.audioSinks = AudioService && Array.isArray(AudioService.sinks) ? AudioService.sinks.slice() : [];
        // Find active sink
        for (let i = 0; i < root.audioSinks.length; i++) {
            if (root.audioSinks[i].isDefault) {
                root.activeSinkIndex = i;
                return;
            }
        }
        root.activeSinkIndex = 0;
    }

    function switchToSink(index) {
        if (index < 0 || index >= root.audioSinks.length)
            return;
        const sink = root.audioSinks[index];
        if (AudioService.setActiveSink)
            AudioService.setActiveSink(sink.name);
        root.activeSinkIndex = index;
        root.pluginData.setString("lastSink", sink.name);
    }

    function openAudioPanel() {
        if (AudioService.openPanel)
            AudioService.openPanel();
    }

    function overallTextSize() {
        const fontScale = root.barConfig ? root.barConfig.fontScale : undefined;
        const maximizeText = root.barConfig ? root.barConfig.maximizeWidgetText : undefined;
        return Theme.barTextSize(root.barThickness, fontScale, maximizeText);
    }

    readonly property real barThickness: root.barConfig ? root.barConfig.thickness : 40
    readonly property real padding: 12

    // ── Layout ────────────────────────────────────────────────
    Item {
        id: container

        width: root.isDesktopWidget ? 320 : (root.barConfig ? root.barConfig.widgetWidth || 320 : 320)
        height: root.isDesktopWidget ? 200 : (root.barConfig ? root.barThickness || 40 : 200)

        // Desktop widget
        visible: root.isDesktopWidget
        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.width: 1
            border.color: Theme.outline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                // Header
                Row {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "audio"
                        size: Theme.iconSize
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Audio Switcher"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                    }
                }

                // Current device
                StyledText {
                    Layout.fillWidth: true
                    text: "Current: " + root.currentDeviceName
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                // Sink list
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                            onClicked: root.switchToSink(index)

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

                // Open panel button
                MouseArea {
                    Layout.fillWidth: true
                    height: 40
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openAudioPanel()

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: Theme.outline

                        StyledText {
                            anchors.fill: parent
                            text: "Open Audio Settings"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        // DankBar widget
        visible: !root.isDesktopWidget
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Row {
                anchors.fill: parent
                anchors.margins: root.padding
                spacing: Theme.spacingS

                MouseArea {
                    width: parent.width
                    height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.showPanelOnClick) {
                            root.openAudioPanel();
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingXS
                        spacing: 2

                        DankIcon {
                            name: "audio"
                            size: Theme.iconSize
                            color: Theme.widgetTextColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            id: metricLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.currentDeviceName
                            color: Theme.widgetTextColor
                            font.pixelSize: root.overallTextSize()
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            HoverHandler {
                onHoveredChanged: {
                    root.barHovered = hovered;
                }
            }
        }
    }
}
