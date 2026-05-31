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
    property var lastSelectedSink: null
    property var quickSwitchSinks: []
    property var enabledSinks: []
    property int _badgeRefresh: 0

    property string currentDeviceName: {
        var sink = root.lastSelectedSink || AudioService.sink;
        if (sink) {
            return AudioService.displayName(sink) || sink.description || "Audio output";
        }
        return "No audio output";
    }

    property string currentDeviceIcon: {
        var sink = root.lastSelectedSink || AudioService.sink;
        if (!sink)
            return "speaker";
        const icon = String(AudioService.sinkIcon(sink) || "speaker");
        if (icon === "tv") return "monitor";
        if (icon === "headset") return "headset";
        return "speaker";
    }

    function refreshAudioSinks() {
        const sinks = AudioService.getAvailableSinks();
        if (Array.isArray(sinks)) {
            root.audioSinks = sinks;
            root.logToFile("Found " + root.audioSinks.length + " sinks");

            // Load persisted enabled sinks
            var stored = pluginData["audioQuickSwitchEnabledSinks"];
            var enabledNames = [];
            if (stored && Array.isArray(stored)) {
                enabledNames = stored;
            } else if (typeof stored === "string" && stored.length > 0) {
                enabledNames = [stored];
            } else {
                // Default: all sinks enabled
                enabledNames = sinks.map(function(s) { return s.name; });
            }
            root.enabledSinks = enabledNames;

            // quickSwitchSinks = intersection of audioSinks and enabledSinks
            root.quickSwitchSinks = sinks.filter(function(s) {
                return s.name && enabledNames.includes(s.name);
            });

            // Track active sink index within the full list
            for (let i = 0; i < root.audioSinks.length; i++) {
                if (AudioService.sink && root.audioSinks[i].name === AudioService.sink.name) {
                    root.activeSinkIndex = i;
                    root.logToFile("Active sink: " + i + " - " + AudioService.displayName(AudioService.sink));
                    root.updateBarBadges();
                    return;
                }
            }

            // If no active sink found, still update badges
            root.updateBarBadges();
        } else {
            root.audioSinks = [];
            root.quickSwitchSinks = [];
            root.enabledSinks = [];
            root.logToFile("AudioService not available");
            root.updateBarBadges();
        }
        root.activeSinkIndex = 0;
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


    function isSinkActive(sink) {
        if (!sink) return false;
        // Check against last selected sink first (immediate UI feedback)
        if (root.lastSelectedSink && sink.name && root.lastSelectedSink.name === sink.name)
            return true;
        // Fall back to AudioService.sink
        return Boolean(AudioService.sink && sink.name && AudioService.sink.name && sink.name === AudioService.sink.name);
    }

    function selectAudioOutput(sink) {
        if (!sink) return false;
        Pipewire.preferredDefaultAudioSink = sink;
        root.lastSelectedSink = sink;
        root.logToFile("Selected: " + sink.name);
        return true;
    }

    function cycleToNextSink() {
        var sinks = root.quickSwitchSinks;
        if (!sinks || sinks.length === 0) return false;

        // Find current index within quickSwitchSinks
        var currentIndex = 0;
        var currentSink = root.lastSelectedSink || AudioService.sink;
        if (currentSink) {
            for (var i = 0; i < sinks.length; i++) {
                if (sinks[i].name === currentSink.name) {
                    currentIndex = i;
                    break;
                }
            }
        }

        var nextIndex = (currentIndex + 1) % sinks.length;
        var nextSink = sinks[nextIndex];
        Pipewire.preferredDefaultAudioSink = nextSink;
        root.lastSelectedSink = nextSink;
        root.logToFile("Cycled to: " + (nextSink.name || "unknown"));
        return true;
    }

    function sinkIconName(sink) {
        if (!sink) return "speaker";
        const icon = String(AudioService.sinkIcon(sink) || "speaker");
        if (icon === "tv") return "monitor";
        if (icon === "headset") return "headset";
        return "speaker";
    }

    // Returns 1-based index within quickSwitchSinks, or 0 if not in pool
    function sinkCycleIndex(sink) {
        if (!sink || !sink.name) return 0;
        var pool = root.quickSwitchSinks;
        for (var i = 0; i < pool.length; i++) {
            if (pool[i].name === sink.name) {
                return i + 1;
            }
        }
        return 0;
    }

    // Update bar badge state (called on init and on sink change)
    function updateBarBadge() {
        var sink = root.lastSelectedSink || AudioService.sink;
        return sink ? root.sinkCycleIndex(sink) : 0;
    }

    // Called after sinks are loaded to force-badge update on the bar pills
    function updateBarBadges() {
        root._badgeRefresh += 1;
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
                id: barIcon
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 7
                name: root.currentDeviceIcon
                size: Math.min(root.barThickness - 12, Theme.iconSize + 2)
                color: Theme.widgetTextColor
                filled: true
            }

            // Numbered badge — positioned as sibling of the icon
            Rectangle {
                id: barBadge
                objectName: "barBadge"
                property int badgeIdx: root.updateBarBadge()
                // Force re-evaluation when sinks are refreshed
                property int _force: root._badgeRefresh
                visible: badgeIdx > 0
                anchors.bottom: barIcon.bottom
                anchors.right: barIcon.right
                anchors.bottomMargin: 0
                anchors.rightMargin: 0
                width: 16
                height: width
                radius: width / 2
                color: Theme.primary
                border.width: 1
                border.color: Theme.surfaceContainerHigh

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenterOffset: -1
                    anchors.verticalCenterOffset: 1
                    text: String(parent.badgeIdx)
                    color: Theme.surfaceContainerHigh
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.logToFile("[AudioSwitcher] Left-click: cycling to next sink");
                    root.cycleToNextSink();
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
                id: vBarIcon
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3
                name: root.currentDeviceIcon
                size: Math.min(parent.width - 12, Theme.iconSize + 2)
                color: Theme.widgetTextColor
                filled: true
            }

            Rectangle {
                id: vBarBadge
                objectName: "vBarBadge"
                property int badgeIdx: root.updateBarBadge()
                property int _force: root._badgeRefresh
                visible: badgeIdx > 0
                anchors.bottom: vBarIcon.bottom
                anchors.right: vBarIcon.right
                anchors.bottomMargin: 0
                anchors.rightMargin: 0
                width: 16
                height: width
                radius: width / 2
                color: Theme.primary
                border.width: 1
                border.color: Theme.surfaceContainerHigh

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenterOffset: -1
                    anchors.verticalCenterOffset: 1
                    text: String(parent.badgeIdx)
                    color: Theme.surfaceContainerHigh
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.logToFile("[AudioSwitcher] Left-click: cycling to next sink");
                    root.cycleToNextSink();
                }
            }
        }
    }

    pillClickAction: function() {
        root.cycleToNextSink();
    }

    pillRightClickAction: function(posX, posY, posWidth, sectionName, currentScreen) {
        root.logToFile("[AudioSwitcher] Right-click: opening popout");
        root.openPopout();
    }

    function openPopout() {
        var popout = null;
        var pill = null;
        for (var i = 0; i < root.children.length; i++) {
            var child = root.children[i];
            if (typeof child.setTriggerPosition === "function") {
                popout = child;
            }
            if (typeof child.mapToItem === "function" && child.width !== undefined && child.width > 0 && typeof child.setTriggerPosition !== "function") {
                pill = child;
            }
        }
        if (popout && pill) {
            var globalPos = pill.mapToItem(null, 0, 0);
            var screen = root.parentScreen || Screen;
            var barPosition = axis?.edge === "left" ? 2 : (axis?.edge === "right" ? 3 : (axis?.edge === "top" ? 0 : 1));
            var pos = SettingsData.getPopupTriggerPosition(globalPos, screen, barThickness, pill.width, barSpacing, barPosition, barConfig);
            popout.setTriggerPosition(pos.x, pos.y, pos.width, root.section, screen, barPosition, barThickness, barSpacing, barConfig);
            popout.toggle();
        }
    }

    function toggleSinkEnabled(sink) {
        // Toggle whether this sink is included in the auto-cycle pool
        var enabled = root.enabledSinks;
        var index = enabled.indexOf(sink.name);
        if (index >= 0) {
            // Don't disable the currently active sink
            if (root.isSinkActive(sink)) {
                root.logToFile("Cannot disable currently active sink: " + sink.name);
                return;
            }
            enabled.splice(index, 1);
        } else {
            enabled.push(sink.name);
        }
        // Persist to pluginData
        var copy = enabled.slice();
        pluginData["audioQuickSwitchEnabledSinks"] = copy;
        root.enabledSinks = copy;
        // Re-filter quickSwitchSinks
        root.quickSwitchSinks = root.audioSinks.filter(function(s) {
            return s.name && copy.includes(s.name);
        });
        root.logToFile("Enabled sinks: " + copy);
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Audio Outputs"
            detailsText: "Left-click widget to cycle | Checkboxes control cycling pool"
            showCloseButton: true

            Column {
                id: contentColumn
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: root.audioSinks

                    delegate: Rectangle {
                        required property var sink
                        width: parent.width
                        height: 48
                        radius: Theme.cornerRadius
                        color: root.isSinkActive(sink) ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 2
                            radius: 1
                            color: root.isSinkActive(parent.sink) ? Theme.primary : "transparent"
                            visible: root.isSinkActive(parent.sink)
                        }

                        Row {
                            id: sinkRow
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingM

                            // Custom checkbox (CheckBox type not available)
                            Rectangle {
                                id: checkboxBox
                                width: Theme.iconSize
                                height: width
                                radius: 3
                                border.width: 1
                                border.color: root.isSinkActive(parent.sink) ? Theme.primary : Theme.outline
                                color: root.enabledSinks.includes(parent.sink.name) ? Theme.primary : "transparent"

                                MouseArea {
                                    id: checkboxClick
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !root.isSinkActive(parent.sink)
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.toggleSinkEnabled(parent.sink);
                                    }
                                }

                                // Checkmark icon when enabled
                                DankIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "check"
                                    size: Theme.iconSize - 4
                                    color: "white"
                                    filled: true
                                    visible: root.enabledSinks.includes(parent.sink.name)
                                }
                            }

                            Row {
                                id: sinkInfo
                                anchors.left: checkboxBox.right
                                anchors.right: parent.right
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingXS
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingM

                                DankIcon {
                                    id: sinkIconItem
                                    width: Theme.iconSize
                                    height: width
                                    name: root.sinkIconName(parent.sink)
                                    color: root.isSinkActive(parent.sink) ? Theme.primary : Theme.surfaceText
                                    filled: true
                                }

                                // Cycle position badge
                                Rectangle {
                                    id: sinkBadgeItem
                                    property int cycleIdx: root.sinkCycleIndex(parent.sink)
                                    property int _force: root._badgeRefresh
                                    visible: cycleIdx > 0
                                    anchors.left: sinkIconItem.right
                                    anchors.bottom: sinkIconItem.bottom
                                    anchors.leftMargin: -8
                                    anchors.bottomMargin: -2
                                    width: 16
                                    height: width
                                    radius: width / 2
                                    color: Theme.primary
                                    border.width: 1
                                    border.color: root.isSinkActive(parent.sink) ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.horizontalCenterOffset: -1
                                        anchors.verticalCenterOffset: 1
                                        text: String(parent.cycleIdx)
                                        color: Theme.surfaceContainerHigh
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectAudioOutput(parent.sink);
                                        popout.closePopout();
                                    }

                                    StyledText {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: Theme.iconSize + Theme.spacingM
                                        anchors.rightMargin: 0
                                        text: root.sinkLabel(parent.sink)
                                        color: Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: root.isSinkActive(parent.sink) ? Font.Medium : Font.Normal
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 380
    popoutHeight: 0
}