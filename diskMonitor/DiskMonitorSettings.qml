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
    SelectionSetting {
        settingKey: "selectedDiskMountPath"
        label: "Disk Mount"
        description: "Choose which disk mount to monitor"
        options: root.diskMountOptions
        defaultValue: "/"
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

    // Dynamically build disk mount options from DgopService
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
}
