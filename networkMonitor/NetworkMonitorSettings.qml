import Qt 6.7
import QtQuick 2.15
import QtQuick.Layouts 6.7
import io.github.dankmachines.dankmaterialshell.theming 1.0 as Theme
import io.github.dankmachines.dankmaterialshell.plugins 1.0 as DankPlugins

PluginSettingsPage {
    id: root

    pluginId: "networkMonitor"
    title: "Network Monitor"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // ── Polling ───────────────────────────────────────
        PluginSettingsGroup {
            Layout.fillWidth: true
            title: "Polling"

            PluginSettingsRow {
                title: "Probe Interval"
                subtitle: "How often to request fresh network stats (ms)"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("probeInterval", 2000)
                    min: 500
                    max: 30000
                    step: 500
                    unit: "ms"
                    onValueChanged: root.pluginData.setNumber("probeInterval", value)
                }
            }
        }

        // ── Appearance ────────────────────────────────────
        PluginSettingsGroup {
            Layout.fillWidth: true
            title: "Appearance"

            PluginSettingsRow {
                title: "Color Mode"
                subtitle: "Vivid or soft palette for network chart"
                control: PluginSettingsSelector {
                    options: ["vivid", "soft"]
                    selected: root.pluginData.stringSetting("colorMode", "vivid")
                    onSelected: root.pluginData.setString("colorMode", selected)
                }
            }

            PluginSettingsRow {
                title: "Chart Height"
                subtitle: "Height of the network chart in pixels"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("chartHeight", 80)
                    min: 40
                    max: 200
                    step: 1
                    unit: "px"
                    onValueChanged: root.pluginData.setNumber("chartHeight", value)
                }
            }

            PluginSettingsRow {
                title: "History Size"
                subtitle: "Number of data points to keep in the rolling chart"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("historySize", 60)
                    min: 10
                    max: 120
                    step: 1
                    unit: "points"
                    onValueChanged: root.pluginData.setNumber("historySize", value)
                }
            }
        }
    }
}
