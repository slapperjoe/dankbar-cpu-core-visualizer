import Qt 6.7
import QtQuick 2.15
import QtQuick.Layouts 6.7
import io.github.dankmachines.dankmaterialshell.theming 1.0 as Theme
import io.github.dankmachines.dankmaterialshell.plugins 1.0 as DankPlugins

PluginSettingsPage {
    id: root

    pluginId: "diskMonitor"
    title: "Disk Monitor"

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
                subtitle: "How often to request fresh disk stats (ms)"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("probeInterval", 3000)
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
                subtitle: "Vivid or soft palette for disk bars"
                control: PluginSettingsSelector {
                    options: ["vivid", "soft"]
                    selected: root.pluginData.stringSetting("colorMode", "vivid")
                    onSelected: root.pluginData.setString("colorMode", selected)
                }
            }

            PluginSettingsRow {
                title: "Bar Width"
                subtitle: "Width of each disk bar in pixels"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("barWidth", 24)
                    min: 8
                    max: 80
                    step: 1
                    unit: "px"
                    onValueChanged: root.pluginData.setNumber("barWidth", value)
                }
            }

            PluginSettingsRow {
                title: "Bar Gap"
                subtitle: "Spacing between disk bars"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("barGap", 4)
                    min: 1
                    max: 20
                    step: 1
                    unit: "px"
                    onValueChanged: root.pluginData.setNumber("barGap", value)
                }
            }

            PluginSettingsRow {
                title: "Corner Radius"
                subtitle: "Rounding of the disk bar corners"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("cornerRadius", 6)
                    min: 2
                    max: 20
                    step: 1
                    unit: "px"
                    onValueChanged: root.pluginData.setNumber("cornerRadius", value)
                }
            }
        }

        // ── Animation ─────────────────────────────────────
        PluginSettingsGroup {
            Layout.fillWidth: true
            title: "Animation"

            PluginSettingsRow {
                title: "Smoothing"
                subtitle: "Animation smoothing factor (higher = more smoothing)"
                control: PluginSettingsSlider {
                    value: root.pluginData.numberSetting("smoothingPercent", 15)
                    min: 1
                    max: 99
                    step: 1
                    unit: "%"
                    onValueChanged: root.pluginData.setNumber("smoothingPercent", value)
                }
            }
        }
    }
}
