import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "cpuCoreVisualizer"

    SliderSetting {
        settingKey: "probeInterval"
        label: "Probe Interval"
        description: "How often CPU stats are refreshed"
        defaultValue: 1000
        minimum: 250
        maximum: 5000
        unit: "ms"
    }

    SliderSetting {
        settingKey: "smoothingPercent"
        label: "Animation Smoothing"
        description: "Higher values snap faster, lower glide more"
        defaultValue: 28
        minimum: 8
        maximum: 85
        unit: "%"
    }

    SliderSetting {
        settingKey: "barOpacity"
        label: "Bar Background Opacity"
        description: "Opacity of the inactive fill behind bars. 0% is invisible."
        defaultValue: 24
        minimum: 5
        maximum: 75
        unit: "%"
    }

    SelectionSetting {
        settingKey: "colorMode"
        label: "Colour Mode"
        description: "Choose between vivid and soft palette"
        defaultValue: "vivid"
        options: [{ "label": "Vivid", "value": "vivid" }, { "label": "Soft", "value": "soft" }]
    }

    SliderSetting {
        settingKey: "barWidth"
        label: "Bar Width"
        description: "Width of each CPU core bar"
        defaultValue: 4
        minimum: 2
        maximum: 20
        unit: "px"
    }

    ToggleSetting {
        settingKey: "showOverallPercentage"
        label: "Show Overall Percentage"
        description: "Show total CPU usage beside the bars"
        defaultValue: true
    }
}
