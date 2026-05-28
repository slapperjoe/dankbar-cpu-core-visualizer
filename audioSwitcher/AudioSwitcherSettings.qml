import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "audioSwitcher"
    title: "Audio Switcher"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // ── Behavior ────────────────────────────────────────
        PluginSettingsGroup {
            Layout.fillWidth: true
            title: "Behavior"

            PluginSettingsRow {
                title: "Default Device"
                subtitle: "Default audio output device"
                control: PluginSettingsSelector {
                    options: ["auto", "headphones", "speakers", "hdmi"]
                    selected: root.pluginData.stringSetting("defaultDevice", "auto")
                    onSelected: root.pluginData.setString("defaultDevice", selected)
                }
            }

            PluginSettingsRow {
                title: "Show Panel on Click"
                subtitle: "Open audio panel when widget is clicked"
                control: PluginSettingsToggle {
                    checked: root.pluginData.boolSetting("showPanelOnClick", true)
                    onCheckedChanged: root.pluginData.setBool("showPanelOnClick", checked)
                }
            }
        }
    }
}
