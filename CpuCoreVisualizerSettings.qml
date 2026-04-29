import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "cpuCoreVisualizer"

    function normalizedColorMode(candidate) {
        const value = String(candidate || "vivid");
        if (value === "soft" || value === "mono" || value === "base")
            return "soft";
        return "vivid";
    }

    Component.onCompleted: {
        const stored = root.loadValue("colorMode", "vivid");
        const normalized = root.normalizedColorMode(stored);
        if (stored !== normalized)
            root.saveValue("colorMode", normalized);
    }

    readonly property var audioOutputOptions: {
        const options = [{
            label: "Auto cycle all outputs",
            value: ""
        }];
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

        return options;
    }

    function sectionLabelForKey(key) {
        if (key === "cpu")
            return "CPU";
        if (key === "memory")
            return "Memory";
        if (key === "disk")
            return "Disk";
        if (key === "network")
            return "Network";
        return "Off";
    }

    function sectionKeyForLabel(label) {
        if (label === "CPU")
            return "cpu";
        if (label === "Memory")
            return "memory";
        if (label === "Disk")
            return "disk";
        if (label === "Network")
            return "network";
        return "off";
    }

    function slotLabel(index) {
        if (index === 0)
            return "1st Slot";
        if (index === 1)
            return "2nd Slot";
        if (index === 2)
            return "3rd Slot";
        return "4th Slot";
    }

    function normalizedSectionSlots(candidate) {
        let normalized = [];
        let used = {};
        const validKeys = ["cpu", "memory", "disk", "network"];
        const source = Array.isArray(candidate) ? candidate : [];

        for (let i = 0; i < Math.min(4, source.length); i++) {
            const key = String(source[i] || "off");
            if (key === "off") {
                normalized.push("off");
            } else if (validKeys.indexOf(key) !== -1 && !used[key]) {
                normalized.push(key);
                used[key] = true;
            } else {
                normalized.push("off");
            }
        }

        while (normalized.length < 4)
            normalized.push("off");

        return normalized;
    }

    function legacySectionSlots() {
        const sections = [{
            key: "cpu",
            enabled: Boolean(root.loadValue("showCpuSection", true)),
            order: Number(root.loadValue("cpuSectionOrder", 1)) || 1,
            fallbackIndex: 0
        }, {
            key: "memory",
            enabled: Boolean(root.loadValue("showMemorySection", true)),
            order: Number(root.loadValue("memorySectionOrder", 2)) || 2,
            fallbackIndex: 1
        }, {
            key: "disk",
            enabled: Boolean(root.loadValue("showDiskSection", true)),
            order: Number(root.loadValue("diskSectionOrder", 3)) || 3,
            fallbackIndex: 2
        }, {
            key: "network",
            enabled: Boolean(root.loadValue("showNetworkSection", true)),
            order: Number(root.loadValue("networkSectionOrder", 4)) || 4,
            fallbackIndex: 3
        }];

        sections.sort((left, right) => {
            if (left.order !== right.order)
                return left.order - right.order;

            return left.fallbackIndex - right.fallbackIndex;
        });

        let slots = [];
        for (let i = 0; i < sections.length; i++) {
            if (sections[i].enabled)
                slots.push(sections[i].key);
        }

        return root.normalizedSectionSlots(slots);
    }

    component SectionOrderSetting: Column {
        id: sectionOrderSetting

        property var slots: ["cpu", "memory", "disk", "network"]
        property bool syncing: false

        width: parent.width
        spacing: Theme.spacingS

        function loadValue() {
            syncing = true;
            const storedSlots = root.loadValue("sectionSlots", []);
            if (Array.isArray(storedSlots) && storedSlots.length > 0)
                slots = root.normalizedSectionSlots(storedSlots);
            else
                slots = root.legacySectionSlots();
            syncing = false;
            root.saveValue("sectionSlots", slots);
        }

        function setSlot(index, key) {
            let nextSlots = slots.slice();
            if (key !== "off") {
                for (let i = 0; i < nextSlots.length; i++) {
                    if (i !== index && nextSlots[i] === key)
                        nextSlots[i] = "off";
                }
            }
            nextSlots[index] = key;
            slots = root.normalizedSectionSlots(nextSlots);
        }

        onSlotsChanged: {
            if (!syncing)
                root.saveValue("sectionSlots", slots);
        }

        StyledText {
            width: parent.width
            text: "Sections"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            width: parent.width
            text: "Choose which section appears in each slot. Set a slot to Off to hide it. Picking a section in a new slot clears it from any previous slot."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: 4

            delegate: DankDropdown {
                width: sectionOrderSetting.width
                text: root.slotLabel(index)
                description: "Pick the section shown in this position"
                currentValue: root.sectionLabelForKey(sectionOrderSetting.slots[index])
                options: ["CPU", "Memory", "Disk", "Network", "Off"]
                onValueChanged: newValue => {
                    sectionOrderSetting.setSlot(index, root.sectionKeyForLabel(newValue));
                }
            }
        }
    }

    StyledText {
        width: parent.width
        text: "CPU Core Visualizer"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Per-core CPU, memory, and disk bars plus a rolling network download/upload chart."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SelectionSetting {
        settingKey: "colorMode"
        label: "Colour Mode"
        description: "Choose the palette for data fills. Text, icons, and widget chrome follow the DankBar theme."
        options: [{
            "label": "Vivid",
            "value": "vivid"
        }, {
            "label": "Soft",
            "value": "soft"
        }]
        defaultValue: "vivid"
    }

    ToggleSetting {
        settingKey: "showOverallPercentage"
        label: "Show Overall CPU %"
        description: "Show total CPU percentage beside the core bars"
        defaultValue: true
    }

    SectionOrderSetting {
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

    SliderSetting {
        settingKey: "probeInterval"
        label: "Probe Time"
        description: "How often the plugin asks DgopService for fresh CPU samples"
        defaultValue: 1000
        minimum: 250
        maximum: 3000
        unit: "ms"
        leftIcon: "timer"
    }

    SliderSetting {
        settingKey: "smoothingPercent"
        label: "Animation Smoothing"
        description: "Lower values glide more; higher values snap faster"
        defaultValue: 28
        minimum: 8
        maximum: 85
        unit: ""
        leftIcon: "timeline"
    }

    SliderSetting {
        settingKey: "barWidth"
        label: "Bar Width"
        description: "Width of each core bar"
        defaultValue: 4
        minimum: 2
        maximum: 24
        unit: "px"
        leftIcon: "width_normal"
    }

    SliderSetting {
        settingKey: "barGap"
        label: "Bar Gap"
        description: "Gap between bars"
        defaultValue: 2
        minimum: 0
        maximum: 10
        unit: "px"
        leftIcon: "space_bar"
    }

    SliderSetting {
        settingKey: "maxVisibleCores"
        label: "Visible Cores"
        description: "Maximum number of cores shown before clipping"
        defaultValue: 32
        minimum: 1
        maximum: 32
        unit: ""
        rightIcon: "memory"
    }

    SliderSetting {
        settingKey: "minBarHeight"
        label: "Minimum Bar Size"
        description: "Set to 0 if you want truly empty idle bars"
        defaultValue: 2
        minimum: 0
        maximum: 8
        unit: "px"
        leftIcon: "height"
    }

    SliderSetting {
        settingKey: "cornerRadius"
        label: "Roundness"
        description: "Corner radius for each bar"
        defaultValue: 2
        minimum: 0
        maximum: 8
        unit: "px"
        leftIcon: "rounded_corner"
    }

    SliderSetting {
        settingKey: "animationDuration"
        label: "Animation Length"
        description: "How long each update glides for"
        defaultValue: 650
        minimum: 120
        maximum: 1600
        unit: "ms"
        leftIcon: "slow_motion_video"
    }

    SliderSetting {
        settingKey: "networkChartWidth"
        label: "Network Chart Width"
        description: "Width of the compact network history chart"
        defaultValue: 120
        minimum: 64
        maximum: 220
        unit: "px"
        leftIcon: "show_chart"
    }

    SliderSetting {
        settingKey: "networkChartHeight"
        label: "Network Chart Height"
        description: "Height of the compact network history chart"
        defaultValue: 24
        minimum: 12
        maximum: 56
        unit: "px"
        leftIcon: "height"
    }

    SliderSetting {
        settingKey: "networkLineWidth"
        label: "Network Line Width"
        description: "Thickness of the upload and download traces"
        defaultValue: 2
        minimum: 1
        maximum: 4
        unit: "px"
        leftIcon: "edit"
    }

    ToggleSetting {
        settingKey: "showNetworkGrid"
        label: "Show Network Grid"
        description: "Draw faint guide lines behind the network history chart"
        defaultValue: true
    }

}
