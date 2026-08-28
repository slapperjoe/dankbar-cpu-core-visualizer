import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "digitalClock"

    ToggleSetting {
        settingKey: "showSeconds"
        label: "Show Seconds"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showAmPm"
        label: "Show AM/PM"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "showDate"
        label: "Show Date"
        defaultValue: true
    }

    SliderSetting {
        settingKey: "backgroundOpacity"
        label: "Background Opacity"
        defaultValue: 55
        minimum: 0
        maximum: 100
        unit: "%"
    }
}
