import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "audioSwitcher"

    readonly property var audioOutputOptions: {
        const options = [{
            label: "Auto cycle all outputs",
            value: ""
        }];
        try {
            const sinks = AudioService.getAvailableSinks();
            if (!Array.isArray(sinks))
                return options;

            for (let i = 0; i < sinks.length; i++) {
                const node = sinks[i];
                const label = AudioService.displayName(node);
                const subtitle = AudioService.subtitle(node.name || "");
                options.push({
                    label: subtitle.length > 0 ? label + " (" + subtitle + ")" : label,
                    value: node.name || ""
                });
            }
        } catch (e) {
            // AudioService not available yet
        }
        return options;
    }

    ToggleSetting {
        settingKey: "audioQuickSwitchEnabled"
        label: "Show Audio Output Button"
        description: "Show a clickable output button in the bar that opens the audio panel and reflects the current device type."
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "popoutOpenOnClick"
        label: "Open Popouts On Click"
        description: "Use click instead of hover for section popouts. The audio button always opens its panel on left-click."
        defaultValue: false
    }

    SelectionSetting {
        settingKey: "audioQuickSwitchPrimary"
        label: "Preferred Output 1"
        description: "First preferred output shown in the audio panel. Leave on auto-cycle to show all currently available outputs."
        options: root.audioOutputOptions
        defaultValue: ""
    }

    SelectionSetting {
        settingKey: "audioQuickSwitchSecondary"
        label: "Preferred Output 2"
        description: "Optional second preferred output shown in the audio panel. When both outputs are set, the panel only shows those two."
        options: root.audioOutputOptions
        defaultValue: ""
    }
}