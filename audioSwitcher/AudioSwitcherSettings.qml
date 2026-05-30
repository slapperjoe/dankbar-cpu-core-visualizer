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
        settingKey: "popoutOpenOnClick"
        label: "Open Popouts On Click"
        description: "Use click instead of hover for section popouts."
        defaultValue: false
    }
}
