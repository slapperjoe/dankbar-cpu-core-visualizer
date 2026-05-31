import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "networkMonitor"

    property int _probeMs: pluginData.numberSetting("probeInterval", 1000)

    StyledText {
        width: parent.width
        text: "Network Monitor"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure polling, appearance, and chart options."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM

        StyledText {
            text: "Probe Interval: " + root._probeMs + " ms"
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
        }

        Slider {
            width: parent.width
            from: 500
            to: 10000
            stepSize: 500
            value: root._probeMs
            onValueChanged: {
                root._probeMs = value;
                pluginData.setNumber("probeInterval", value);
            }
        }
    }
}
