import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "networkMonitor"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

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
            PluginSettingsRow {
                title: "Grid Lines"
                subtitle: "Show horizontal grid lines on the chart"
                control: PluginSettingsToggle {
                    checked: root.pluginData.boolSetting("showNetworkGrid", true)
                    onToggled: root.pluginData.setBool("showNetworkGrid", checked)
                }
            }

            PluginSettingsRow {
                title: "Line Width"
                subtitle: "Stroke width for the chart lines"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("networkLineWidth", 2)
                    min: 1
                    max: 4
                    step: 1
                    unit: "px"
                    onValueChanged: root.pluginData.setNumber("networkLineWidth", value)
                }
            }
        }
    }
}
