import Qt 6.7
import QtQuick 2.15
import QtQuick.Layouts 6.7
import io.github.dankmachines.dankmaterialshell.theming 1.0 as Theme
import io.github.dankmachines.dankmaterialshell.plugins 1.0 as DankPlugins

PluginSettingsPage {
    id: root

    pluginId: "audioSwitcher"
    title: "Audio Switcher"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

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
