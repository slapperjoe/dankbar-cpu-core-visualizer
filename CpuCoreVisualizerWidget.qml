import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    property int padding: 4
    property var vividPalette: ["#ff003c", "#ff4f00", "#ff7a00", "#ffb000", "#ffd400", "#f5ff00", "#c8ff00", "#8dff00", "#53ff00", "#00ff1e", "#00ff6a", "#00ffae", "#00ffd5", "#00e5ff", "#00b3ff", "#0080ff", "#0057ff", "#3040ff", "#5c2dff", "#7d1fff", "#9d00ff", "#c200ff", "#e100ff", "#ff00e1", "#ff00b8", "#ff008f", "#ff0066", "#ff335f", "#ff5c5c", "#ff7f50", "#ff9f1c", "#ffcf33"]
    property var softPalette: ["#ff8aa5", "#ffac7a", "#ffc27a", "#ffd86e", "#fff07a", "#dcff8a", "#b8ff94", "#8eff9d", "#7fffb8", "#7fffd8", "#80f3ff", "#82dcff", "#86c3ff", "#90acff", "#a595ff", "#bc8cff", "#d38bff", "#ea8cff", "#ff8fe8", "#ff93cf", "#ff95b5", "#ff9c9c", "#ffb091", "#ffc188", "#ffd487", "#f1e88f", "#d7f39a", "#bbeea8", "#a6e8bf", "#9be1d4", "#a2d8e6", "#b4cfee"]
    property int barWidth: Math.max(2, Math.round(numberSetting("barWidth", 4)))
    property int barGap: Math.max(0, Math.round(numberSetting("barGap", 2)))
    property int sectionPadding: Math.max(0, Math.round(numberSetting("sectionPadding", Math.max(Theme.spacingS, root.barGap + 4))))
    property int maxVisibleCores: Math.max(1, Math.round(numberSetting("maxVisibleCores", 32)))
    property int minBarHeight: Math.max(0, Math.round(numberSetting("minBarHeight", 2)))
    property int animationDuration: Math.max(120, Math.round(numberSetting("animationDuration", 650)))
    property int cornerRadius: Math.max(0, Math.round(numberSetting("cornerRadius", 2)))
    property int probeInterval: Math.max(250, Math.round(numberSetting("probeInterval", 1000)))
    property real smoothingFactor: Math.max(0.08, Math.min(0.85, numberSetting("smoothingPercent", 28) / 100))
    property string colorMode: stringSetting("colorMode", "vivid")
    property bool showOverallPercentage: boolSetting("showOverallPercentage", true)
    property bool barHovered: false
    property bool popoutHovered: false
    property bool detailsPopoutOpen: false
    property var animatedCpuUsage: []
    property real animatedMemoryUsage: 0
    property real animatedDiskUsage: 0
    readonly property real totalCpuUsage: root.clampUsage(Number(DgopService.cpuUsage || 0))
    readonly property real memoryUsageValue: root.clampUsage(Number(DgopService.memoryUsage || 0))
    readonly property var selectedDiskMountPaths: root.arraySetting("selectedDiskMountPaths", ["/"])
    readonly property var diskMountList: Array.isArray(DgopService.diskMounts) ? DgopService.diskMounts : []
    readonly property var selectedDiskMounts: {
        let exactMatches = [];
        let fallback = [];
        for (let i = 0; i < root.diskMountList.length; i++) {
            const mount = root.diskMountList[i];
            const mountPath = root.diskMountPath(mount);
            if (!mountPath || !root.diskMountHasUsage(mount))
                continue;

            fallback.push(mount);
            if (root.selectedDiskMountPaths.indexOf(mountPath) !== -1)
                exactMatches.push(mount);
        }

        if (exactMatches.length > 0)
            return exactMatches;

        return fallback;
    }
    readonly property string diskSelectionLabel: {
        if (root.selectedDiskMounts.length <= 0)
            return "Waiting for disk stats";

        let labels = [];
        for (let i = 0; i < root.selectedDiskMounts.length; i++)
            labels.push(root.diskMountPath(root.selectedDiskMounts[i]));

        return labels.join(", ");
    }
    readonly property real diskUsageValue: {
        if (root.selectedDiskMounts.length <= 0)
            return 0;

        let weightedUsed = 0;
        let weightedTotal = 0;
        for (let i = 0; i < root.selectedDiskMounts.length; i++) {
            const mount = root.selectedDiskMounts[i];
            const total = Number(mount && mount.total !== undefined ? mount.total : 0);
            const used = Number(mount && mount.used !== undefined ? mount.used : 0);
            if (total > 0) {
                weightedUsed += Math.max(0, used);
                weightedTotal += total;
            }
        }

        if (weightedTotal > 0)
            return root.clampUsage((weightedUsed / weightedTotal) * 100);

        let percentTotal = 0;
        let percentCount = 0;
        for (let j = 0; j < root.selectedDiskMounts.length; j++) {
            const percent = root.diskMountPercent(root.selectedDiskMounts[j]);
            if (percent >= 0) {
                percentTotal += percent;
                percentCount++;
            }
        }

        if (percentCount <= 0)
            return 0;

        return root.clampUsage(percentTotal / percentCount);
    }
    readonly property string diskUsageSubtitle: {
        if (root.selectedDiskMounts.length <= 0)
            return "Waiting for disk stats";

        if (root.selectedDiskMounts.length === 1) {
            const mount = root.selectedDiskMounts[0];
            const total = Number(mount && mount.total !== undefined ? mount.total : 0);
            if (total > 0)
                return root.diskMountPath(mount) + "  " + root.formatStorage(mount.used) + " / " + root.formatStorage(total);
        }

        return root.diskSelectionLabel;
    }
    readonly property string diskUsageTooltipText: {
        if (root.selectedDiskMounts.length <= 0)
            return "Waiting for disk stats";

        let parts = [];
        for (let i = 0; i < root.selectedDiskMounts.length; i++) {
            const mount = root.selectedDiskMounts[i];
            let part = root.diskMountPath(mount) + " " + root.diskMountPercent(mount).toFixed(0) + "%";
            const total = Number(mount && mount.total !== undefined ? mount.total : 0);
            if (total > 0)
                part += " (" + root.formatStorage(mount.used) + " / " + root.formatStorage(total) + ")";
            parts.push(part);
        }

        return parts.join("  |  ");
    }
    readonly property var sectionKeys: ["cpu", "memory", "disk"]
    readonly property int sectionGap: root.sectionPadding
    readonly property int compactIconSize: Math.max(10, Math.min(root.widgetThickness - root.padding * 2, Theme.barIconSize(root.barThickness, -8, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)))
    readonly property var rawCoreUsage: {
        const perCore = DgopService.perCoreCpuUsage;
        if (Array.isArray(perCore) && perCore.length > 0)
            return perCore;

        return [DgopService.cpuUsage || 0];
    }
    readonly property int displayedCoreCount: {
        const total = root.rawCoreUsage.length;
        if (total <= 0)
            return 1;

        return Math.min(root.maxVisibleCores, total);
    }

    function clampUsage(value) {
        if (Number.isNaN(value))
            return 0;

        return Math.max(0, Math.min(100, value));
    }

    function arraySetting(key, fallback) {
        if (pluginData && Array.isArray(pluginData[key]))
            return pluginData[key];

        return fallback;
    }

    function diskMountPath(mount) {
        if (!mount)
            return "";

        if (mount.mount !== undefined && mount.mount !== null && String(mount.mount).length > 0)
            return String(mount.mount);

        if (mount.mountpoint !== undefined && mount.mountpoint !== null && String(mount.mountpoint).length > 0)
            return String(mount.mountpoint);

        return "";
    }

    function diskMountPercent(mount) {
        if (!mount)
            return 0;

        const total = Number(mount.total || 0);
        const used = Number(mount.used || 0);
        if (total > 0)
            return root.clampUsage((used / total) * 100);

        if (mount.percent !== undefined && mount.percent !== null) {
            const parsedPercent = Number(String(mount.percent).replace("%", ""));
            if (!Number.isNaN(parsedPercent))
                return root.clampUsage(parsedPercent);
        }

        return 0;
    }

    function diskMountHasUsage(mount) {
        if (!mount)
            return false;

        if (Number(mount.total || 0) > 0)
            return true;

        return mount.percent !== undefined && mount.percent !== null && String(mount.percent).length > 0;
    }

    function numberSetting(key, fallback) {
        if (pluginData && pluginData[key] !== undefined && pluginData[key] !== null) {
            const value = Number(pluginData[key]);
            if (!Number.isNaN(value))
                return value;

        }
        return fallback;
    }

    function stringSetting(key, fallback) {
        if (pluginData && pluginData[key] !== undefined && pluginData[key] !== null)
            return String(pluginData[key]);

        return fallback;
    }

    function boolSetting(key, fallback) {
        if (pluginData && pluginData[key] !== undefined && pluginData[key] !== null)
            return Boolean(pluginData[key]);

        return fallback;
    }

    function overallTextSize() {
        const fontScale = root.barConfig ? root.barConfig.fontScale : undefined;
        const maximizeText = root.barConfig ? root.barConfig.maximizeWidgetText : undefined;
        return Theme.barTextSize(root.barThickness, fontScale, maximizeText);
    }

    function syncUsageValue(current, target, force) {
        if (force || Number.isNaN(current))
            return target;

        const delta = target - current;
        if (Math.abs(delta) < 0.35)
            return target;

        return current + delta * root.smoothingFactor;
    }

    function syncAnimatedUsage(force) {
        let next = root.animatedCpuUsage ? root.animatedCpuUsage.slice() : [];
        const targetLength = root.rawCoreUsage.length;
        for (let i = 0; i < targetLength; i++) {
            const target = root.usageFor(i);
            const current = Number(next[i]);
            next[i] = root.syncUsageValue(current, target, force);
        }
        next.length = targetLength;
        root.animatedCpuUsage = next;
        root.animatedMemoryUsage = root.syncUsageValue(Number(root.animatedMemoryUsage), root.memoryUsageValue, force);
        root.animatedDiskUsage = root.syncUsageValue(Number(root.animatedDiskUsage), root.diskUsageValue, force);
    }

    function usageFor(index) {
        if (index < 0 || index >= root.rawCoreUsage.length)
            return 0;

        const value = Number(root.rawCoreUsage[index]);
        if (Number.isNaN(value))
            return 0;

        return Math.max(0, Math.min(100, value));
    }

    function cpuRatioFor(index) {
        const animated = Number(root.animatedCpuUsage[index]);
        if (!Number.isNaN(animated))
            return root.clampUsage(animated) / 100;

        return root.usageFor(index) / 100;
    }

    function colorFor(index) {
        if (root.colorMode === "mono")
            return Theme.widgetTextColor;

        if (root.colorMode === "soft")
            return root.softPalette[index % root.softPalette.length];

        if (root.colorMode === "base")
            return Theme.primary;

        return root.vividPalette[index % root.vividPalette.length];
    }

    function usageLabel(index) {
        const usage = root.usageFor(index);
        if (usage >= 85)
            return "Pinned";

        if (usage >= 60)
            return "Hot";

        if (usage >= 35)
            return "Busy";

        if (usage >= 12)
            return "Warm";

        return "Idle";
    }

    function sectionIcon(sectionKey) {
        if (sectionKey === "memory")
            return "sd_card";

        if (sectionKey === "disk")
            return "storage";

        return "memory";
    }

    function sectionTitle(sectionKey) {
        if (sectionKey === "memory")
            return "Memory";

        if (sectionKey === "disk")
            return "Disk";

        return "CPU";
    }

    function sectionBarCount(sectionKey) {
        if (sectionKey === "cpu")
            return root.displayedCoreCount;

        return 1;
    }

    function sectionUsageFor(sectionKey, index) {
        if (sectionKey === "memory")
            return root.memoryUsageValue;

        if (sectionKey === "disk")
            return root.diskUsageValue;

        return root.usageFor(index);
    }

    function sectionAnimatedUsageFor(sectionKey, index) {
        if (sectionKey === "memory")
            return root.animatedMemoryUsage;

        if (sectionKey === "disk")
            return root.animatedDiskUsage;

        return Number(root.animatedCpuUsage[index]);
    }

    function sectionRatioFor(sectionKey, index) {
        const animated = Number(root.sectionAnimatedUsageFor(sectionKey, index));
        if (!Number.isNaN(animated))
            return root.clampUsage(animated) / 100;

        return root.sectionUsageFor(sectionKey, index) / 100;
    }

    function sectionPercentageText(sectionKey) {
        return root.sectionUsageFor(sectionKey, 0).toFixed(0) + "%";
    }

    function sectionColorFor(sectionKey, index) {
        if (sectionKey === "cpu")
            return root.colorFor(index);

        if (root.colorMode === "mono")
            return Theme.widgetTextColor;

        if (root.colorMode === "base")
            return Theme.primary;

        if (sectionKey === "memory")
            return root.colorMode === "soft" ? root.softPalette[11] : root.vividPalette[13];

        return root.colorMode === "soft" ? root.softPalette[3] : root.vividPalette[3];
    }

    function formatStorage(bytes) {
        const value = Number(bytes || 0);
        if (value <= 0)
            return "0 B";

        const units = ["B", "KB", "MB", "GB", "TB"];
        let scaled = value;
        let unitIndex = 0;
        while (scaled >= 1024 && unitIndex < units.length - 1) {
            scaled /= 1024;
            unitIndex++;
        }

        const decimals = scaled >= 10 || unitIndex === 0 ? 0 : 1;
        return scaled.toFixed(decimals) + " " + units[unitIndex];
    }

    function sectionSummarySubtitle(sectionKey) {
        if (sectionKey === "memory") {
            const total = Number(DgopService.totalMemoryKB || 0);
            if (total <= 0)
                return "Waiting for memory stats";

            return DgopService.formatSystemMemory(DgopService.usedMemoryKB) + " / " + DgopService.formatSystemMemory(total);
        }

        if (sectionKey === "disk") {
            return root.diskUsageSubtitle;
        }

        const shownCores = root.displayedCoreCount;
        const totalCores = root.rawCoreUsage.length;
        const hottestIndex = root.hottestCoreIndex();
        const hottestUsage = root.usageFor(hottestIndex).toFixed(0);
        let subtitle = "Hot core C" + hottestIndex + " " + hottestUsage + "%";
        subtitle += shownCores < totalCores ? "  |  " + shownCores + "/" + totalCores + " cores" : "  |  " + totalCores + " cores";
        return subtitle;
    }

    function cardFillWidth(index, width) {
        return Math.max(10, Math.round(width * root.cpuRatioFor(index)));
    }

    function verticalHeightFor(sectionKey, index, availableHeight) {
        const ratio = root.sectionRatioFor(sectionKey, index);
        if (ratio <= 0)
            return root.minBarHeight;

        return Math.max(root.minBarHeight, Math.round(availableHeight * ratio));
    }

    function horizontalLengthFor(sectionKey, index, availableWidth) {
        const ratio = root.sectionRatioFor(sectionKey, index);
        if (ratio <= 0)
            return root.minBarHeight;

        return Math.max(root.minBarHeight, Math.round(availableWidth * ratio));
    }

    function hottestCoreIndex() {
        let hottestIndex = 0;
        let hottestValue = -1;
        for (let i = 0; i < root.rawCoreUsage.length; i++) {
            const usage = root.usageFor(i);
            if (usage > hottestValue) {
                hottestValue = usage;
                hottestIndex = i;
            }
        }
        return hottestIndex;
    }

    function tooltipText() {
        const totalUsage = root.totalCpuUsage.toFixed(1);
        const totalCores = root.rawCoreUsage.length;
        const shownCores = root.displayedCoreCount;
        const hottestIndex = root.hottestCoreIndex();
        const hottestUsage = root.usageFor(hottestIndex).toFixed(0);
        let header = "CPU " + totalUsage + "%";
        if (DgopService.cpuTemperature > 0)
            header += "  |  " + Math.round(DgopService.cpuTemperature) + "C";

        if (DgopService.cpuFrequency > 0)
            header += "  |  " + Math.round(DgopService.cpuFrequency) + " MHz";

        let summary = "Memory " + root.memoryUsageValue.toFixed(0) + "%";
        summary += "  |  Disk " + root.diskUsageValue.toFixed(0) + "%";
        summary += "  |  Hottest core C" + hottestIndex + " " + hottestUsage + "%";
        if (shownCores < totalCores)
            summary += "  |  Showing " + shownCores + "/" + totalCores + " cores";
        else
            summary += "  |  " + totalCores + " cores";
        let lines = [];
        for (let i = 0; i < shownCores; i++) {
            const entry = "C" + i + " " + root.usageFor(i).toFixed(0) + "%";
            const lineIndex = Math.floor(i / 4);
            if (!lines[lineIndex])
                lines[lineIndex] = entry;
            else
                lines[lineIndex] += "   " + entry;
        }
        if (root.diskUsageTooltipText.length > 0)
            lines.push("Disk mounts: " + root.diskUsageTooltipText);

        return header + "\n" + summary + (lines.length > 0 ? "\n" + lines.join("\n") : "");
    }

    function shortSummaryText() {
        const totalUsage = root.totalCpuUsage.toFixed(1);
        const hottestIndex = root.hottestCoreIndex();
        const hottestUsage = root.usageFor(hottestIndex).toFixed(0);
        let summary = "CPU " + totalUsage + "%";
        summary += "  |  Memory " + root.memoryUsageValue.toFixed(0) + "%";
        summary += "  |  Disk " + root.diskUsageValue.toFixed(0) + "%";
        summary += "  |  Hot core C" + hottestIndex + " " + hottestUsage + "%";
        if (DgopService.cpuTemperature > 0)
            summary += "  |  " + Math.round(DgopService.cpuTemperature) + "C";

        summary += "  |  Probe " + root.probeInterval + "ms";
        return summary;
    }

    function openDetailsPopout() {
        closePopoutTimer.stop();
        if (root.detailsPopoutOpen)
            return ;

        root.triggerPopout();
        root.detailsPopoutOpen = true;
    }

    function scheduleClosePopout() {
        if (root.barHovered || root.popoutHovered)
            return ;

        closePopoutTimer.restart();
    }

    function closeDetailsPopout() {
        closePopoutTimer.stop();
        if (!root.detailsPopoutOpen)
            return ;

        root.closePopout();
        root.detailsPopoutOpen = false;
    }

    function refreshBarsForLayoutChange() {
        root.syncAnimatedUsage(true);
        Qt.callLater(function() {
            root.syncAnimatedUsage(true);
            DgopService.updateAllStats();
        });
    }

    TextMetrics {
        id: overallPercentageMetrics

        font.pixelSize: root.overallTextSize()
        font.weight: Font.Medium
        text: "100%"
    }

    component HorizontalMetricSection: Row {
        id: horizontalSection

        property string sectionKey: "cpu"

        spacing: root.barGap

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.barGap

            Repeater {
                model: root.sectionBarCount(horizontalSection.sectionKey)

                delegate: Item {
                    width: root.barWidth
                    height: Math.max(root.widgetThickness - root.padding * 2, root.minBarHeight + 1)

                    Rectangle {
                        width: parent.width
                        height: root.verticalHeightFor(horizontalSection.sectionKey, index, parent.height)
                        anchors.bottom: parent.bottom
                        radius: Math.min(root.cornerRadius, width / 2)
                        color: root.sectionColorFor(horizontalSection.sectionKey, index)
                        opacity: 0.96

                        Behavior on height {
                            NumberAnimation {
                                duration: root.animationDuration
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

        }

        Row {
            visible: root.showOverallPercentage
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(2, root.barGap)

            DankIcon {
                name: root.sectionIcon(horizontalSection.sectionKey)
                size: root.compactIconSize
                color: root.sectionColorFor(horizontalSection.sectionKey, 0)
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Math.ceil(overallPercentageMetrics.advanceWidth)
                height: horizontalMetricLabel.implicitHeight

                StyledText {
                    id: horizontalMetricLabel

                    anchors.fill: parent
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: root.sectionPercentageText(horizontalSection.sectionKey)
                    color: Theme.widgetTextColor
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Medium
                }
            }
        }
    }

    component VerticalMetricSection: Column {
        id: verticalSection

        property string sectionKey: "cpu"
        property int availableWidth: Math.max(root.widgetThickness - root.padding * 2, root.minBarHeight + 1)
        property bool fillFromLeft: root.axis?.edge === "left"

        width: availableWidth
        spacing: Math.max(2, root.barGap)

        Column {
            width: parent.width
            spacing: root.barGap

            Repeater {
                model: root.sectionBarCount(verticalSection.sectionKey)

                delegate: Item {
                    width: parent.width
                    height: root.barWidth

                    Rectangle {
                        height: parent.height
                        width: root.horizontalLengthFor(verticalSection.sectionKey, index, parent.width)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: verticalSection.fillFromLeft ? parent.left : undefined
                        anchors.right: verticalSection.fillFromLeft ? undefined : parent.right
                        radius: Math.min(root.cornerRadius, height / 2)
                        color: root.sectionColorFor(verticalSection.sectionKey, index)
                        opacity: 0.96

                        Behavior on width {
                            NumberAnimation {
                                duration: root.animationDuration
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

        }

        Row {
            visible: root.showOverallPercentage
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.max(2, root.barGap)

            DankIcon {
                name: root.sectionIcon(verticalSection.sectionKey)
                size: Math.min(root.compactIconSize, verticalSection.availableWidth)
                color: root.sectionColorFor(verticalSection.sectionKey, 0)
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Math.min(verticalSection.width, Math.ceil(overallPercentageMetrics.advanceWidth))
                height: verticalMetricLabel.implicitHeight

                StyledText {
                    id: verticalMetricLabel

                    anchors.fill: parent
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: root.sectionPercentageText(verticalSection.sectionKey)
                    color: Theme.widgetTextColor
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Medium
                }
            }
        }
    }

    layerNamespacePlugin: "cpu-core-visualizer"
    Component.onCompleted: {
        DgopService.addRef(["cpu", "memory", "diskmounts"]);
        root.syncAnimatedUsage(true);
        DgopService.updateAllStats();
    }
    Component.onDestruction: {
        closePopoutTimer.stop();
        DgopService.removeRef(["cpu", "memory", "diskmounts"]);
    }
    onRawCoreUsageChanged: root.syncAnimatedUsage(root.animatedCpuUsage.length !== root.rawCoreUsage.length)
    onMemoryUsageValueChanged: root.syncAnimatedUsage(false)
    onDiskUsageValueChanged: root.syncAnimatedUsage(false)
    onIsVerticalChanged: root.refreshBarsForLayoutChange()
    popoutWidth: 420
    popoutHeight: 320

    Timer {
        id: closePopoutTimer

        interval: 220
        repeat: false
        onTriggered: root.closeDetailsPopout()
    }

    Timer {
        id: probeTimer

        interval: root.probeInterval
        repeat: true
        running: true
        onTriggered: DgopService.updateAllStats()
    }

    Timer {
        id: animationTimer

        interval: 33
        repeat: true
        running: true
        onTriggered: root.syncAnimatedUsage(false)
    }

    horizontalBarPill: Component {
        Item {
            id: horizontalRoot

            implicitWidth: root.padding * 2 + horizontalContent.implicitWidth
            implicitHeight: root.widgetThickness

            Row {
                id: horizontalContent

                anchors.centerIn: parent
                spacing: root.sectionGap

                Repeater {
                    model: root.sectionKeys

                    delegate: HorizontalMetricSection {
                        sectionKey: modelData
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

            }

            MouseArea {
                id: horizontalHoverArea

                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                onContainsMouseChanged: {
                    root.barHovered = containsMouse;
                    if (containsMouse)
                        root.openDetailsPopout();
                    else
                        root.scheduleClosePopout();
                }
            }

        }

    }

    verticalBarPill: Component {
        Item {
            id: verticalRoot

            implicitWidth: root.widgetThickness
            implicitHeight: root.padding * 2 + verticalContent.implicitHeight

            Column {
                id: verticalContent

                anchors.centerIn: parent
                spacing: root.sectionGap

                Repeater {
                    model: root.sectionKeys

                    delegate: VerticalMetricSection {
                        sectionKey: modelData
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

            }

            MouseArea {
                id: verticalHoverArea

                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                onContainsMouseChanged: {
                    root.barHovered = containsMouse;
                    if (containsMouse)
                        root.openDetailsPopout();
                    else
                        root.scheduleClosePopout();
                }
            }

        }

    }

    popoutContent: Component {
        PopoutComponent {
            id: detailsPopout

            headerText: "CPU Core Visualizer"
            detailsText: root.shortSummaryText()
            showCloseButton: false

            Connections {
                function onShouldBeVisibleChanged() {
                    root.detailsPopoutOpen = detailsPopout.parentPopout ? detailsPopout.parentPopout.shouldBeVisible : false;
                    if (!root.detailsPopoutOpen)
                        root.popoutHovered = false;

                }

                target: detailsPopout.parentPopout
            }

            Item {
                width: parent.width
                implicitHeight: contentColumn.implicitHeight

                MouseArea {
                    id: popoutHoverArea

                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    onContainsMouseChanged: {
                        root.popoutHovered = containsMouse;
                        if (containsMouse)
                            closePopoutTimer.stop();
                        else
                            root.scheduleClosePopout();
                    }
                }

                Column {
                    id: contentColumn

                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        width: parent.width
                        text: "Samples refresh every " + root.probeInterval + "ms from the plugin timer via DgopService. CPU cores, memory, and disk usage animate independently."
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Flow {
                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: root.sectionKeys

                            delegate: Rectangle {
                                width: Math.max(120, (contentColumn.width - Theme.spacingS * 2) / 3)
                                height: 64
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: Theme.outline

                                DankIcon {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingM
                                    name: root.sectionIcon(modelData)
                                    size: Theme.iconSize
                                    color: root.sectionColorFor(modelData, 0)
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM + Theme.iconSize + Theme.spacingS
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: root.sectionTitle(modelData)
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: root.sectionPercentageText(modelData)
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Theme.spacingS
                                    text: root.sectionSummarySubtitle(modelData)
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: "CPU cores"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                    }

                    Flow {
                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: root.displayedCoreCount

                            delegate: Rectangle {
                                width: Math.max(110, (contentColumn.width - Theme.spacingS * 2) / 3)
                                height: 52
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: Theme.outline
                                clip: true

                                Rectangle {
                                    width: root.cardFillWidth(index, parent.width)
                                    height: parent.height
                                    color: root.colorFor(index)
                                    opacity: (root.colorMode === "mono" || root.colorMode === "base") ? 0.18 : 0.24

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 120
                                            easing.type: Easing.OutCubic
                                        }

                                    }
                                }

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.colorFor(index)
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingM
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM + 14
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: "Core " + index
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: root.usageFor(index).toFixed(0) + "%"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Theme.spacingS
                                    text: root.usageLabel(index) + (index === root.hottestCoreIndex() ? "  |  hottest" : "")
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
