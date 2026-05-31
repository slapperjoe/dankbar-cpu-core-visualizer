import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "diskMonitor"

    StyledText {
        width: parent.width
        text: "Disk Monitor"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Disk mount usage monitoring."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    // ── Disk Mounts ────────────────────────────────────
    readonly property var diskMountList: Array.isArray(DgopService.diskMounts) ? DgopService.diskMounts : []

    readonly property var diskMountOptions: {
        let options = [];
        if (!Array.isArray(root.diskMountList) || root.diskMountList.length <= 0)
            return [{ label: "No disk stats available", value: "/" }];
        for (let i = 0; i < root.diskMountList.length; i++) {
            const mount = root.diskMountList[i];
            const path = mount.mount || mount.device || "/";
            options.push({ label: path, value: path });
        }
        return options;
    }

    // Selected mounts list (display with remove buttons)
    ListSetting {
        id: mountList
        settingKey: "selectedDiskMountPaths"
        label: "Monitored Mounts"
        description: "Currently selected disk mounts"
        defaultValue: ["/"]
        delegate: listDelegate
    }

    // Add mount dropdown
    SelectionSetting {
        id: addMountPicker
        settingKey: "selectedDiskMountPath"
        label: "Add Disk Mount"
        description: "Pick a mount to add to the monitored list"
        options: root.diskMountOptions
        defaultValue: ""
    }

    // When a new mount is picked, add it to the list
    Connections {
        target: addMountPicker
        function onValueChanged() {
            const val = addMountPicker.value;
            if (val && val !== "") {
                mountList.addItem(val);
                // Reset picker to empty
                addMountPicker.value = "";
            }
        }
    }

    Component {
        id: listDelegate
        Row {
            width: parent.width
            height: 40
            spacing: Theme.spacingM

            StyledText {
                text: modelData
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            Rectangle {
                width: 60
                height: 28
                color: removeArea.containsMouse ? Theme.errorHover : Theme.error
                radius: Theme.cornerRadius

                StyledText {
                    anchors.centerIn: parent
                    text: "Remove"
                    color: Theme.errorText
                    font.pixelSize: Theme.fontSizeSmall
                }

                MouseArea {
                    id: removeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mountList.removeItem(index)
                    }
                }
            }
        }
    }

    // ── Polling ───────────────────────────────────────
    SliderSetting {
        settingKey: "probeInterval"
        label: "Probe Interval"
        description: "How often to request fresh disk stats (ms)"
        defaultValue: 3000
        minimum: 500
        maximum: 30000
        unit: "ms"
    }

    // ── Appearance ────────────────────────────────────
    SelectionSetting {
        settingKey: "colorMode"
        label: "Color Mode"
        description: "Vivid or soft palette for disk bars"
        options: ["vivid", "soft"]
        defaultValue: "vivid"
    }

    SliderSetting {
        settingKey: "barWidth"
        label: "Bar Width"
        description: "Width of each disk bar in pixels"
        defaultValue: 24
        minimum: 8
        maximum: 80
        unit: "px"
    }

    SliderSetting {
        settingKey: "barGap"
        label: "Bar Gap"
        description: "Spacing between disk bars"
        defaultValue: 4
        minimum: 1
        maximum: 20
        unit: "px"
    }

    SliderSetting {
        settingKey: "cornerRadius"
        label: "Corner Radius"
        description: "Rounding of the disk bar corners"
        defaultValue: 6
        minimum: 2
        maximum: 20
        unit: "px"
    }

    // ── Interaction ────────────────────────────────────
    SelectionSetting {
        settingKey: "popoutTriggerMode"
        label: "Popout Trigger"
        description: "How to open the detail popout"
        options: ["hover", "click"]
        defaultValue: "click"
    }

    // ── Animation ─────────────────────────────────────
    SliderSetting {
        settingKey: "smoothingPercent"
        label: "Animation Smoothing"
        description: "Lower values glide more; higher values snap faster"
        defaultValue: 15
        minimum: 1
        maximum: 99
        unit: "%"
    }
}
