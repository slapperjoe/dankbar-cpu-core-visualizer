import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "cpuCoreVisualizer"

    StyledText {
        width: parent.width
        text: "CPU Core Visualizer"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Per-core CPU bars with vivid or monochrome rendering, plus adjustable probe time."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SelectionSetting {
        settingKey: "colorMode"
        label: "Colour Mode"
        description: "Choose a vivid palette, a softer dark-theme palette, theme text mono, or the UI base colour"
        options: [{
            "label": "Vivid",
            "value": "vivid"
        }, {
            "label": "Soft Dark",
            "value": "soft"
        }, {
            "label": "Mono",j
            "value": "mono"
        }, {
            "label": "UI Base",
            "value": "base"
        }]
        defaultValue: "vivid"
    }

    ToggleSetting {
        settingKey: "showOverallPercentage"
        label: "Show Overall CPU %"
        description: "Show total CPU percentage beside the core bars"
        defaultValue: true
    }

    SliderSetting {
        settingKey: "probeInterval"
        label: "Probe Time"
        description: "How often the plugin asks DgopService for fresh CPU samples"
        defaultValue: 1000
        minimum: 250
        maximum: 3000
        unit: "ms"
        leftIcon: "timer"
    }

    SliderSetting {
        settingKey: "smoothingPercent"
        label: "Animation Smoothing"
        description: "Lower values glide more; higher values snap faster"
        defaultValue: 28
        minimum: 8
        maximum: 85
        unit: ""
        leftIcon: "timeline"
    }

    SliderSetting {
        settingKey: "barWidth"
        label: "Bar Width"
        description: "Width of each core bar"
        defaultValue: 4
        minimum: 2
        maximum: 24
        unit: "px"
        leftIcon: "width_normal"
    }

    SliderSetting {
        settingKey: "barGap"
        label: "Bar Gap"
        description: "Gap between bars"
        defaultValue: 2
        minimum: 0
        maximum: 10
        unit: "px"
        leftIcon: "space_bar"
    }

    SliderSetting {
        settingKey: "maxVisibleCores"
        label: "Visible Cores"
        description: "Maximum number of cores shown before clipping"
        defaultValue: 32
        minimum: 1
        maximum: 32
        unit: ""
        rightIcon: "memory"
    }

    SliderSetting {
        settingKey: "minBarHeight"
        label: "Minimum Bar Size"
        description: "Set to 0 if you want truly empty idle bars"
        defaultValue: 2
        minimum: 0
        maximum: 8
        unit: "px"
        leftIcon: "height"
    }

    SliderSetting {
        settingKey: "cornerRadius"
        label: "Roundness"
        description: "Corner radius for each bar"
        defaultValue: 2
        minimum: 0
        maximum: 8
        unit: "px"
        leftIcon: "rounded_corner"
    }

    SliderSetting {
        settingKey: "animationDuration"
        label: "Animation Length"
        description: "How long each update glides for"
        defaultValue: 650
        minimum: 120
        maximum: 1600
        unit: "ms"
        leftIcon: "slow_motion_video"
    }

}
