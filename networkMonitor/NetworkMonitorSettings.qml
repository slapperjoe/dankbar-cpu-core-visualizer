import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "networkMonitor"

    SelectionSetting {
        settingKey: "colorMode"
        label: "Colour Mode"
        description: "Vivid or soft palette for network chart"
        defaultValue: "vivid"
        options: [{ "label": "Vivid", "value": "vivid" }, { "label": "Soft", "value": "soft" }]
    }

    SliderSetting {
        settingKey: "probeInterval"
        label: "Probe Interval"
        description: "How often network stats are refreshed"
        defaultValue: 1000
        minimum: 200
        maximum: 2000
        unit: "ms"
    }

    SliderSetting {
        settingKey: "networkChartWidth"
        label: "Chart Width"
        description: "Width of the mini chart in the bar pill"
        defaultValue: 80
        minimum: 40
        maximum: 200
        unit: "px"
    }

    SliderSetting {
        settingKey: "chartHeight"
        label: "Popout Chart Height"
        description: "Height of the chart in the popout"
        defaultValue: 80
        minimum: 40
        maximum: 200
        unit: "px"
    }

    SliderSetting {
        settingKey: "historySize"
        label: "History Size"
        description: "Number of data points in the rolling chart"
        defaultValue: 60
        minimum: 10
        maximum: 120
        unit: "pts"
    }

    ToggleSetting {
        settingKey: "showNetworkGrid"
        label: "Show Grid Lines"
        description: "Show horizontal guide lines on charts"
        defaultValue: true
    }

    SliderSetting {
        settingKey: "networkLineWidth"
        label: "Line Width"
        description: "Stroke width for chart lines"
        defaultValue: 2
        minimum: 1
        maximum: 4
        unit: "px"
    }
}
