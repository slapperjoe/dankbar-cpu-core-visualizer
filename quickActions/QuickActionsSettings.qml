import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "quickActions"

    property var displayOptions: [{ "label": "Auto-detect", "value": "auto" }]

    Component.onCompleted: {
        fetchDisplays();
    }

    function fetchDisplays() {
        Proc.runCommand("displays", ["sh", "-c", "niri msg --json outputs 2>/dev/null"],
            function(output, exitCode) {
                if (exitCode !== 0 || !output) return;
                try {
                    var data = JSON.parse(output);
                    var opts = [{ "label": "Auto-detect", "value": "auto" }];
                    for (var key in data) {
                        opts.push({ "label": key, "value": key });
                    }
                    root.displayOptions = opts;
                } catch (e) {
                    console.error("Failed to parse niri outputs:", e);
                }
            }, 50, 5000);
    }

    SelectionSetting {
        settingKey: "selectedDisplay"
        label: "Display Output"
        description: "Target display for rotation actions"
        options: root.displayOptions
        defaultValue: "auto"
    }

    StyledText {
        text: "Click the bolt icon in the bar to open quick actions. Rotation uses niri compositor commands."
        color: Theme.surfaceVariantText
        font.pixelSize: Theme.fontSizeSmall - 1
        wrapMode: Text.WordWrap
    }
}
