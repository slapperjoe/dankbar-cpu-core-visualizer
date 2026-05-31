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
            const mountPath = (mount.mount && String(mount.mount).length > 0) ? String(mount.mount) :
                               (mount.device && String(mount.device).length > 0) ? String(mount.device) : "/";
            // Skip if path looks invalid
            if (!mountPath || mountPath.indexOf("//") !== -1)
                continue;
            options.push({ label: mountPath, value: mountPath });
        }
        if (options.length === 0)
            return [{ label: "No disk stats available", value: "/" }];
        return options;
    }

    // ── Selected mounts as pills ─────────────────────────
    property var selectedMountPaths: []

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            width: parent.width
            text: "Monitored Mounts"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceVariantText
        }

        StyledText {
            width: parent.width
            text: "Pick a mount to add (above), click X to remove"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        // Pill container
        Flow {
            id: mountPillsContainer
            width: parent.width
            height: 60
            clip: true
            spacing: Theme.spacingXS

            Repeater {
                id: mountPillsRepeater
                model: root.selectedMountPaths

                delegate: Rectangle {
                    width: pillRow.implicitWidth + 32
                    height: 28
                    radius: 14
                    color: Theme.surfaceVariant
                    border.width: 1
                    border.color: Theme.outline

                    Row {
                        id: pillRow
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        spacing: 6

                        StyledText {
                            text: typeof modelData === "string" && modelData.length > 0 && modelData !== "undefined" && modelData !== "null" ? modelData : "unknown"
                            color: Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        // Remove button
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: pillRemoveArea.containsMouse ? Theme.errorContainer : "transparent"

                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 14
                                color: Theme.onErrorContainer
                            }

                            MouseArea {
                                id: pillRemoveArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var copy = root.selectedMountPaths.filter(function(p) { return p !== modelData; });
                                    root.selectedMountPaths = copy;
                                    root.saveValue("selectedDiskMountPaths", JSON.stringify(copy));
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Load saved mount list when settings component is ready
    Component.onCompleted: {
        var storedStr = root.loadValue("selectedDiskMountPaths", "");
        var loaded;
        if (storedStr && typeof storedStr === "string" && storedStr !== "") {
            try {
                loaded = JSON.parse(storedStr);
            } catch (e) {
                loaded = ["/"];
            }
        } else {
            loaded = ["/"];
        }
        var valid = loaded.filter(function(p) {
            if (typeof p !== "string" || p.trim().length === 0) return false;
            if (p.indexOf("//") !== -1) return false;
            return true;
        });
        if (valid.length === 0) {
            root.selectedMountPaths = ["/"];
        } else {
            root.selectedMountPaths = valid;
        }
    }



    // Add mount dropdown
    SelectionSetting {
        id: addMountPicker
        settingKey: "_tempMountPicker"
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
            if (typeof val === "string" && val !== "" && val.indexOf("//") === -1) {
                if (root.selectedMountPaths.indexOf(val) === -1) {
                    var copy = root.selectedMountPaths.slice();
                    copy.push(val);
                    root.selectedMountPaths = copy;
                    root.saveValue("selectedDiskMountPaths", JSON.stringify(copy));
                }
                // Reset picker to empty
                addMountPicker.value = "";
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
