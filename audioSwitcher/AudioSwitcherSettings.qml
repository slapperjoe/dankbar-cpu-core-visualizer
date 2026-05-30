import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: root

    pluginId: "audioSwitcher"

    StringSetting {
        settingKey: "defaultDevice"
        label: "Default Device"
        defaultValue: "auto"
    }
}
