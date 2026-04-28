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
    property int networkChartWidth: Math.max(64, Math.round(numberSetting("networkChartWidth", 120)))
    property int networkChartHeight: Math.max(12, Math.round(numberSetting("networkChartHeight", 24)))
    property real networkLineWidth: Math.max(1, Math.min(4, numberSetting("networkLineWidth", 2)))
    property bool showNetworkGrid: boolSetting("showNetworkGrid", true)
    property var configuredSectionSlots: root.arraySetting("sectionSlots", [])
    property bool showCpuSection: boolSetting("showCpuSection", true)
    property bool showMemorySection: boolSetting("showMemorySection", true)
    property bool showDiskSection: boolSetting("showDiskSection", true)
    property bool showNetworkSection: boolSetting("showNetworkSection", true)
    property int cpuSectionOrder: Math.max(1, Math.min(4, Math.round(numberSetting("cpuSectionOrder", 1))))
    property int memorySectionOrder: Math.max(1, Math.min(4, Math.round(numberSetting("memorySectionOrder", 2))))
    property int diskSectionOrder: Math.max(1, Math.min(4, Math.round(numberSetting("diskSectionOrder", 3))))
    property int networkSectionOrder: Math.max(1, Math.min(4, Math.round(numberSetting("networkSectionOrder", 4))))
    property real smoothingFactor: Math.max(0.08, Math.min(0.85, numberSetting("smoothingPercent", 28) / 100))
    property string colorMode: stringSetting("colorMode", "vivid")
    property bool showOverallPercentage: boolSetting("showOverallPercentage", true)
    property bool barHovered: false
    property bool popoutHovered: false
    property bool detailsPopoutOpen: false
    property string hoveredSection: ""
    property var animatedCpuUsage: []
    property real animatedMemoryUsage: 0
    property var animatedDiskUsages: []
    property var networkDownloadHistory: []
    property var networkUploadHistory: []
    property bool pendingNetworkHistoryCapture: false
    readonly property real totalCpuUsage: root.clampUsage(Number(DgopService.cpuUsage || 0))
    readonly property real memoryUsageValue: root.clampUsage(Number(DgopService.memoryUsage || 0))
    readonly property int networkHistoryWindowMs: 60000
    readonly property int networkHistorySampleLimit: Math.max(12, Math.round(root.networkHistoryWindowMs / root.probeInterval) + 1)
    readonly property real currentDownloadRate: Math.max(0, Number(DgopService.networkRxRate || 0))
    readonly property real currentUploadRate: Math.max(0, Number(DgopService.networkTxRate || 0))
    readonly property real peakDownloadRate: root.networkPeak(root.networkDownloadHistory, root.currentDownloadRate)
    readonly property real peakUploadRate: root.networkPeak(root.networkUploadHistory, root.currentUploadRate)
    readonly property string activeNetworkIp: {
        if (DgopService.wifiConnected && DgopService.wifiIP)
            return DgopService.wifiIP;

        if (DgopService.ethernetConnected && DgopService.ethernetIP)
            return DgopService.ethernetIP;

        if (NetworkService.wifiConnected && NetworkService.wifiIP)
            return NetworkService.wifiIP;

        if (NetworkService.ethernetConnected && NetworkService.ethernetIP)
            return NetworkService.ethernetIP;

        return DgopService.wifiIP || DgopService.ethernetIP || NetworkService.wifiIP || NetworkService.ethernetIP || "";
    }
    readonly property var selectedDiskMountPaths: root.arraySetting("selectedDiskMountPaths", ["/"])
    readonly property var diskMountList: Array.isArray(DgopService.diskMounts) ? DgopService.diskMounts : []
    readonly property var topMemoryProcesses: {
        const procs = Array.isArray(DgopService.allProcesses) ? DgopService.allProcesses.slice() : [];
        procs.sort((a, b) => (Number(b.memoryKB) || 0) - (Number(a.memoryKB) || 0));
        return procs.slice(0, 8);
    }
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
    readonly property var validSectionKeys: ["cpu", "memory", "disk", "network"]
    readonly property var enabledOrderedSectionKeys: {
        const configured = root.normalizedVisibleSectionKeys(root.configuredSectionSlots);
        if (configured.length > 0 || root.configuredSectionSlots.length > 0)
            return configured;

        const sections = [{
            key: "cpu",
            enabled: root.showCpuSection,
            order: root.cpuSectionOrder,
            fallbackIndex: 0
        }, {
            key: "memory",
            enabled: root.showMemorySection,
            order: root.memorySectionOrder,
            fallbackIndex: 1
        }, {
            key: "disk",
            enabled: root.showDiskSection,
            order: root.diskSectionOrder,
            fallbackIndex: 2
        }, {
            key: "network",
            enabled: root.showNetworkSection,
            order: root.networkSectionOrder,
            fallbackIndex: 3
        }];

        let enabled = sections.filter(section => section.enabled);
        enabled.sort((left, right) => {
            if (left.order !== right.order)
                return left.order - right.order;

            return left.fallbackIndex - right.fallbackIndex;
        });

        return enabled.map(section => section.key);
    }
    readonly property string defaultPopoutSection: root.enabledOrderedSectionKeys.length > 0 ? root.enabledOrderedSectionKeys[0] : ""
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
        let nextDisk = root.animatedDiskUsages ? root.animatedDiskUsages.slice() : [];
        const diskCount = root.selectedDiskMounts.length;
        for (let d = 0; d < diskCount; d++) {
            const diskTarget = root.diskMountUsageFor(d);
            const diskCurrent = Number(nextDisk[d]);
            nextDisk[d] = root.syncUsageValue(diskCurrent, diskTarget, force);
        }
        nextDisk.length = diskCount;
        root.animatedDiskUsages = nextDisk;
    }

    function diskMountUsageFor(index) {
        if (index < 0 || index >= root.selectedDiskMounts.length)
            return 0;

        return root.clampUsage(root.diskMountPercent(root.selectedDiskMounts[index]));
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

        if (sectionKey === "network")
            return "network_check";

        return "memory";
    }

    function sectionTitle(sectionKey) {
        if (sectionKey === "memory")
            return "Memory";

        if (sectionKey === "disk")
            return "Disk";

        if (sectionKey === "network")
            return "Network";

        return "CPU";
    }

    function normalizedVisibleSectionKeys(candidate) {
        let normalized = [];
        let seen = {};
        const source = Array.isArray(candidate) ? candidate : [];
        for (let i = 0; i < source.length; i++) {
            const key = String(source[i] || "");
            if (key === "off" || key.length <= 0)
                continue;
            if (root.validSectionKeys.indexOf(key) === -1 || seen[key])
                continue;
            normalized.push(key);
            seen[key] = true;
        }
        return normalized;
    }

    function isSectionVisible(sectionKey) {
        return root.enabledOrderedSectionKeys.indexOf(sectionKey) !== -1;
    }

    function sectionBarCount(sectionKey) {
        if (sectionKey === "cpu")
            return root.displayedCoreCount;

        if (sectionKey === "disk")
            return Math.max(1, root.selectedDiskMounts.length);

        return 1;
    }

    function sectionUsageFor(sectionKey, index) {
        if (sectionKey === "memory")
            return root.memoryUsageValue;

        if (sectionKey === "disk")
            return root.diskMountUsageFor(index);

        if (sectionKey === "network")
            return 0;

        return root.usageFor(index);
    }

    function sectionAnimatedUsageFor(sectionKey, index) {
        if (sectionKey === "memory")
            return root.animatedMemoryUsage;

        if (sectionKey === "disk")
            return Number(root.animatedDiskUsages[index]);

        if (sectionKey === "network")
            return 0;

        return Number(root.animatedCpuUsage[index]);
    }

    function sectionRatioFor(sectionKey, index) {
        const animated = Number(root.sectionAnimatedUsageFor(sectionKey, index));
        if (!Number.isNaN(animated))
            return root.clampUsage(animated) / 100;

        return root.sectionUsageFor(sectionKey, index) / 100;
    }

    function sectionPercentageText(sectionKey) {
        if (sectionKey === "network")
            return root.formatCompactNetworkSpeed(root.currentDownloadRate) + " / " + root.formatCompactNetworkSpeed(root.currentUploadRate);

        if (sectionKey === "disk")
            return root.diskUsageValue.toFixed(0) + "%";

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

        if (sectionKey === "disk")
            return root.colorMode === "soft" ? root.softPalette[(index * 7 + 3) % root.softPalette.length] : root.vividPalette[(index * 7 + 3) % root.vividPalette.length];

        if (sectionKey === "network")
            return index === 0 ? Theme.info : Theme.error;

        return root.colorMode === "soft" ? root.softPalette[index % root.softPalette.length] : root.vividPalette[index % root.vividPalette.length];
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

    function formatNetworkSpeed(bytesPerSecond) {
        const value = Math.max(0, Number(bytesPerSecond || 0));
        if (value < 1024)
            return value.toFixed(0) + " B/s";

        if (value < 1024 * 1024)
            return (value / 1024).toFixed(value >= 10 * 1024 ? 0 : 1) + " KB/s";

        if (value < 1024 * 1024 * 1024)
            return (value / (1024 * 1024)).toFixed(value >= 10 * 1024 * 1024 ? 0 : 1) + " MB/s";

        return (value / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
    }

    function formatCompactNetworkSpeed(bytesPerSecond) {
        const value = Math.max(0, Number(bytesPerSecond || 0));
        if (value < 1024)
            return value.toFixed(0) + "B/s";

        if (value < 1024 * 1024)
            return (value / 1024).toFixed(value >= 10 * 1024 ? 0 : 1) + "K/s";

        if (value < 1024 * 1024 * 1024)
            return (value / (1024 * 1024)).toFixed(value >= 10 * 1024 * 1024 ? 0 : 1) + "M/s";

        return (value / (1024 * 1024 * 1024)).toFixed(1) + "G/s";
    }

    function trimNetworkHistory(values) {
        let trimmed = Array.isArray(values) ? values.slice() : [];
        if (trimmed.length > root.networkHistorySampleLimit)
            trimmed = trimmed.slice(trimmed.length - root.networkHistorySampleLimit);
        return trimmed;
    }

    function networkPeak(values, currentValue) {
        let peak = Math.max(1, Number(currentValue || 0));
        const series = Array.isArray(values) ? values : [];
        for (let i = 0; i < series.length; i++)
            peak = Math.max(peak, Number(series[i] || 0));
        return peak;
    }

    function appendNetworkHistorySample(downloadRate, uploadRate) {
        let nextDownload = root.networkDownloadHistory ? root.networkDownloadHistory.slice() : [];
        let nextUpload = root.networkUploadHistory ? root.networkUploadHistory.slice() : [];
        nextDownload.push(Math.max(0, Number(downloadRate || 0)));
        nextUpload.push(Math.max(0, Number(uploadRate || 0)));
        root.networkDownloadHistory = root.trimNetworkHistory(nextDownload);
        root.networkUploadHistory = root.trimNetworkHistory(nextUpload);
    }

    function queueNetworkHistoryCapture() {
        if (root.pendingNetworkHistoryCapture)
            return;

        root.pendingNetworkHistoryCapture = true;
        networkHistoryCaptureTimer.restart();
    }

    function networkRateSubtitle() {
        return "↓ " + root.formatNetworkSpeed(root.currentDownloadRate) + "  |  ↑ " + root.formatNetworkSpeed(root.currentUploadRate);
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

        if (sectionKey === "network")
            return root.networkRateSubtitle();

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
        summary += "  |  Net " + root.formatCompactNetworkSpeed(root.currentDownloadRate) + " down / " + root.formatCompactNetworkSpeed(root.currentUploadRate) + " up";
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
        lines.push("Network peaks (1m): down " + root.formatNetworkSpeed(root.peakDownloadRate) + "  |  up " + root.formatNetworkSpeed(root.peakUploadRate));

        return header + "\n" + summary + (lines.length > 0 ? "\n" + lines.join("\n") : "");
    }

    function shortSummaryText() {
        const totalUsage = root.totalCpuUsage.toFixed(1);
        const hottestIndex = root.hottestCoreIndex();
        const hottestUsage = root.usageFor(hottestIndex).toFixed(0);
        let summary = "Total " + totalUsage + "%";
        summary += "  |  Hot core C" + hottestIndex + " " + hottestUsage + "%";
        summary += "  |  Net " + root.formatCompactNetworkSpeed(root.currentDownloadRate) + "/" + root.formatCompactNetworkSpeed(root.currentUploadRate);
        if (DgopService.cpuTemperature > 0)
            summary += "  |  " + Math.round(DgopService.cpuTemperature) + "°C";
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

    TextMetrics {
        id: networkLabelMetrics

        font.pixelSize: root.overallTextSize()
        font.weight: Font.Medium
        text: "↓ 888.8M"
    }

    component NetworkHistoryChart: Canvas {
        property var downloadSeries: []
        property var uploadSeries: []
        property real downloadPeak: 1
        property real uploadPeak: 1
        property color downloadColor: Theme.info
        property color uploadColor: Theme.error
        property real strokeWidth: 2
        property bool gridVisible: true

        onDownloadSeriesChanged: requestPaint()
        onUploadSeriesChanged: requestPaint()
        onDownloadPeakChanged: requestPaint()
        onUploadPeakChanged: requestPaint()
        onDownloadColorChanged: requestPaint()
        onUploadColorChanged: requestPaint()
        onStrokeWidthChanged: requestPaint()
        onGridVisibleChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function drawSeries(ctx, series, peak, strokeColor) {
            if (!Array.isArray(series) || series.length <= 0)
                return;

            ctx.beginPath();
            ctx.lineWidth = strokeWidth;
            ctx.strokeStyle = strokeColor;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";

            for (let i = 0; i < series.length; i++) {
                const x = series.length <= 1 ? width / 2 : (i / (series.length - 1)) * width;
                const ratio = Math.max(0, Math.min(1, Number(series[i] || 0) / Math.max(1, peak)));
                const y = height - ratio * height;
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }

            ctx.stroke();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (gridVisible) {
                ctx.strokeStyle = Theme.outline;
                ctx.globalAlpha = 0.3;
                ctx.lineWidth = 1;
                for (let row = 1; row <= 3; row++) {
                    const y = (height / 4) * row;
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                    ctx.stroke();
                }

                ctx.globalAlpha = 1;
            }

            drawSeries(ctx, downloadSeries, downloadPeak, downloadColor);
            drawSeries(ctx, uploadSeries, uploadPeak, uploadColor);
        }
    }

    component HorizontalNetworkSection: Row {
        id: horizontalNetwork

        spacing: root.barGap

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.hoveredSection = "network";
                else if (root.hoveredSection === "network")
                    root.hoveredSection = "";
            }
        }

        StyledText {
            width: Math.ceil(networkLabelMetrics.advanceWidth)
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: "↓ " + root.formatCompactNetworkSpeed(root.currentDownloadRate)
            color: Theme.info
            font.pixelSize: root.overallTextSize()
            font.weight: Font.Medium
        }

        Rectangle {
            width: root.networkChartWidth
            height: Math.max(root.networkChartHeight, root.minBarHeight + 1)
            anchors.verticalCenter: parent.verticalCenter
            radius: Math.min(root.cornerRadius + 1, height / 2)
            color: Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outline
            clip: true

            NetworkHistoryChart {
                anchors.fill: parent
                anchors.margins: 1
                downloadSeries: root.networkDownloadHistory
                uploadSeries: root.networkUploadHistory
                downloadPeak: root.peakDownloadRate
                uploadPeak: root.peakUploadRate
                strokeWidth: root.networkLineWidth
                gridVisible: root.showNetworkGrid
            }
        }

        StyledText {
            width: Math.ceil(networkLabelMetrics.advanceWidth)
            anchors.verticalCenter: parent.verticalCenter
            text: "↑ " + root.formatCompactNetworkSpeed(root.currentUploadRate)
            color: Theme.error
            font.pixelSize: root.overallTextSize()
            font.weight: Font.Medium
        }
    }

    component VerticalNetworkSection: Column {
        id: verticalNetwork

        property int availableWidth: Math.max(root.widgetThickness - root.padding * 2, root.minBarHeight + 1)

        width: availableWidth
        spacing: root.barGap

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.hoveredSection = "network";
                else if (root.hoveredSection === "network")
                    root.hoveredSection = "";
            }
        }

        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "↓ " + root.formatCompactNetworkSpeed(root.currentDownloadRate)
            color: Theme.info
            font.pixelSize: Math.max(8, root.overallTextSize() - 1)
            font.weight: Font.Medium
        }

        Rectangle {
            width: parent.width
            height: Math.max(root.networkChartHeight * 2, root.barWidth * 3)
            radius: Math.min(root.cornerRadius + 1, height / 3)
            color: Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outline
            clip: true

            NetworkHistoryChart {
                anchors.fill: parent
                anchors.margins: 1
                downloadSeries: root.networkDownloadHistory
                uploadSeries: root.networkUploadHistory
                downloadPeak: root.peakDownloadRate
                uploadPeak: root.peakUploadRate
                strokeWidth: root.networkLineWidth
                gridVisible: root.showNetworkGrid
            }
        }

        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "↑ " + root.formatCompactNetworkSpeed(root.currentUploadRate)
            color: Theme.error
            font.pixelSize: Math.max(8, root.overallTextSize() - 1)
            font.weight: Font.Medium
        }
    }

    component HorizontalMetricSection: Row {
        id: horizontalSection

        property string sectionKey: "cpu"

        spacing: root.sectionPadding

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.hoveredSection = horizontalSection.sectionKey;
                else if (root.hoveredSection === horizontalSection.sectionKey)
                    root.hoveredSection = "";
            }
        }

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
            spacing: 2

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
        spacing: root.sectionPadding

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.hoveredSection = verticalSection.sectionKey;
                else if (root.hoveredSection === verticalSection.sectionKey)
                    root.hoveredSection = "";
            }
        }

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
            spacing: 2

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

    Component {
        id: horizontalMetricSectionComponent

        HorizontalMetricSection {
        }
    }

    Component {
        id: horizontalNetworkSectionComponent

        HorizontalNetworkSection {
        }
    }

    Component {
        id: verticalMetricSectionComponent

        VerticalMetricSection {
        }
    }

    Component {
        id: verticalNetworkSectionComponent

        VerticalNetworkSection {
        }
    }

    layerNamespacePlugin: "cpu-core-visualizer"
    Component.onCompleted: {
        DgopService.addRef(["cpu", "memory", "diskmounts", "processes", "network"]);
        root.syncAnimatedUsage(true);
        root.appendNetworkHistorySample(root.currentDownloadRate, root.currentUploadRate);
        DgopService.updateAllStats();
        root.queueNetworkHistoryCapture();
    }
    Component.onDestruction: {
        closePopoutTimer.stop();
        networkHistoryCaptureTimer.stop();
        DgopService.removeRef(["cpu", "memory", "diskmounts", "processes", "network"]);
    }
    onRawCoreUsageChanged: root.syncAnimatedUsage(root.animatedCpuUsage.length !== root.rawCoreUsage.length)
    onMemoryUsageValueChanged: root.syncAnimatedUsage(false)
    onSelectedDiskMountsChanged: root.syncAnimatedUsage(root.animatedDiskUsages.length !== root.selectedDiskMounts.length)
    onEnabledOrderedSectionKeysChanged: {
        if (root.hoveredSection.length > 0 && !root.isSectionVisible(root.hoveredSection))
            root.hoveredSection = "";
    }
    onNetworkHistorySampleLimitChanged: {
        root.networkDownloadHistory = root.trimNetworkHistory(root.networkDownloadHistory);
        root.networkUploadHistory = root.trimNetworkHistory(root.networkUploadHistory);
    }
    onIsVerticalChanged: root.refreshBarsForLayoutChange()
    popoutWidth: 420
    popoutHeight: 400

    Connections {
        target: DgopService

        function onNetworkRxRateChanged() {
            root.queueNetworkHistoryCapture();
        }

        function onNetworkTxRateChanged() {
            root.queueNetworkHistoryCapture();
        }
    }

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
        onTriggered: {
            DgopService.updateAllStats();
            root.queueNetworkHistoryCapture();
        }
    }

    Timer {
        id: networkHistoryCaptureTimer

        interval: 40
        repeat: false
        onTriggered: {
            root.pendingNetworkHistoryCapture = false;
            root.appendNetworkHistorySample(root.currentDownloadRate, root.currentUploadRate);
        }
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
                    model: root.enabledOrderedSectionKeys

                    delegate: Loader {
                        anchors.verticalCenter: parent.verticalCenter
                        sourceComponent: modelData === "network" ? horizontalNetworkSectionComponent : horizontalMetricSectionComponent

                        property string resolvedSectionKey: modelData
                        onLoaded: {
                            if (item && item.sectionKey !== undefined)
                                item.sectionKey = resolvedSectionKey;
                        }
                    }

                }

            }

            HoverHandler {
                id: horizontalHoverArea

                onHoveredChanged: {
                    root.barHovered = hovered;
                    if (hovered)
                        root.openDetailsPopout();
                    else {
                        root.hoveredSection = "";
                        root.scheduleClosePopout();
                    }
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
                    model: root.enabledOrderedSectionKeys

                    delegate: Loader {
                        anchors.horizontalCenter: parent.horizontalCenter
                        sourceComponent: modelData === "network" ? verticalNetworkSectionComponent : verticalMetricSectionComponent

                        property string resolvedSectionKey: modelData
                        onLoaded: {
                            if (item && item.sectionKey !== undefined)
                                item.sectionKey = resolvedSectionKey;
                        }
                    }

                }

            }

            HoverHandler {
                id: verticalHoverArea

                onHoveredChanged: {
                    root.barHovered = hovered;
                    if (hovered)
                        root.openDetailsPopout();
                    else {
                        root.hoveredSection = "";
                        root.scheduleClosePopout();
                    }
                }
            }

        }

    }

    popoutContent: Component {
        PopoutComponent {
            id: detailsPopout

            headerText: {
                if (root.defaultPopoutSection === "")
                    return "Details";
                if ((root.hoveredSection || root.defaultPopoutSection) === "memory")
                    return "Memory";
                if ((root.hoveredSection || root.defaultPopoutSection) === "disk")
                    return "Storage";
                if ((root.hoveredSection || root.defaultPopoutSection) === "network")
                    return "Network";
                return "CPU";
            }
            detailsText: {
                if ((root.hoveredSection || root.defaultPopoutSection) === "memory") {
                    const total = Number(DgopService.totalMemoryKB || 0);
                    if (total <= 0)
                        return "Waiting for memory stats";
                    return DgopService.formatSystemMemory(DgopService.usedMemoryKB) + " / " + DgopService.formatSystemMemory(total) + "  |  " + root.memoryUsageValue.toFixed(0) + "%";
                }
                if ((root.hoveredSection || root.defaultPopoutSection) === "disk")
                    return root.diskSelectionLabel;
                if ((root.hoveredSection || root.defaultPopoutSection) === "network")
                    return "";
                if (root.defaultPopoutSection === "")
                    return "Enable at least one section to show data here";
                return root.shortSummaryText();
            }
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

                    // ── CPU / overview view ──────────────────────────────────
                    Column {
                        visible: (root.hoveredSection || root.defaultPopoutSection) === "cpu"
                        width: parent.width
                        spacing: Theme.spacingS

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
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        width: root.cardFillWidth(index, parent.width)
                                        height: parent.height
                                        radius: Theme.cornerRadius
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

                    // ── Memory view ──────────────────────────────────────────
                    Column {
                        visible: (root.hoveredSection || root.defaultPopoutSection) === "memory"
                        width: parent.width
                        spacing: Theme.spacingS

                        Rectangle {
                            width: parent.width
                            height: 88
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Theme.outline
                            clip: true

                            Rectangle {
                                width: parent.width * (root.animatedMemoryUsage / 100)
                                height: parent.height
                                radius: parent.radius
                                color: root.sectionColorFor("memory", 0)
                                opacity: (root.colorMode === "mono" || root.colorMode === "base") ? 0.18 : 0.24

                                Behavior on width {
                                    NumberAnimation {
                                        duration: root.animationDuration
                                        easing.type: Easing.OutCubic
                                    }

                                }
                            }

                            DankIcon {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.top: parent.top
                                anchors.topMargin: Theme.spacingM
                                name: "sd_card"
                                size: Theme.iconSize
                                color: root.sectionColorFor("memory", 0)
                            }

                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM + Theme.iconSize + Theme.spacingS
                                anchors.top: parent.top
                                anchors.topMargin: Theme.spacingS
                                text: "Memory"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                            }

                            StyledText {
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingM
                                anchors.top: parent.top
                                anchors.topMargin: Theme.spacingS
                                text: root.memoryUsageValue.toFixed(0) + "%"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                            }

                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Theme.spacingS
                                text: {
                                    const total = Number(DgopService.totalMemoryKB || 0);
                                    if (total <= 0)
                                        return "Waiting for memory stats";
                                    return DgopService.formatSystemMemory(DgopService.usedMemoryKB) + " used  /  " + DgopService.formatSystemMemory(total) + " total";
                                }
                                color: Theme.surfaceVariantText
                                font.pixelSize: Theme.fontSizeSmall - 1
                            }

                        }

                        StyledText {
                            width: parent.width
                            text: "Top processes by memory"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            visible: root.topMemoryProcesses.length > 0
                        }

                        Repeater {
                            model: root.topMemoryProcesses

                            delegate: Rectangle {
                                width: parent.width
                                height: 52
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: Theme.outline
                                clip: true

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    width: parent.width * Math.min(1, (Number(modelData.memoryPercent) || 0) / 100)
                                    height: parent.height
                                    radius: Theme.cornerRadius
                                    color: root.sectionColorFor("memory", 0)
                                    opacity: (root.colorMode === "mono" || root.colorMode === "base") ? 0.18 : 0.24

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: root.animationDuration
                                            easing.type: Easing.OutCubic
                                        }

                                    }
                                }

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.sectionColorFor("memory", 0)
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingM
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM + 14
                                    anchors.right: memProcMemText.left
                                    anchors.rightMargin: Theme.spacingS
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: modelData.command || "unknown"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    id: memProcMemText

                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: root.formatStorage(Number(modelData.memoryKB) * 1024)
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Theme.spacingS
                                    text: (Number(modelData.memoryPercent) || 0).toFixed(1) + "% mem  |  " + (Number(modelData.cpu) || 0).toFixed(1) + "% cpu  |  pid " + (modelData.pid || "—")
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                }

                            }

                        }

                    }

                    // ── Disk view ────────────────────────────────────────────
                    Column {
                        visible: (root.hoveredSection || root.defaultPopoutSection) === "disk"
                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: root.selectedDiskMounts

                            delegate: Rectangle {
                                width: parent.width
                                height: 72
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: Theme.outline
                                clip: true

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    width: parent.width * (root.diskMountUsageFor(index) / 100)
                                    height: parent.height
                                    radius: Theme.cornerRadius
                                    color: root.sectionColorFor("disk", index)
                                    opacity: (root.colorMode === "mono" || root.colorMode === "base") ? 0.18 : 0.24

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: root.animationDuration
                                            easing.type: Easing.OutCubic
                                        }

                                    }
                                }

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.sectionColorFor("disk", index)
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingM + 2
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM + 14
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: root.diskMountPath(modelData) || "Unknown"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: root.diskMountUsageFor(index).toFixed(0) + "%"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Theme.spacingS
                                    text: {
                                        const total = Number(modelData && modelData.total !== undefined ? modelData.total : 0);
                                        if (total <= 0)
                                            return "Usage data unavailable";
                                        return root.formatStorage(modelData.used) + " used  /  " + root.formatStorage(total) + " total";
                                    }
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                }

                            }

                        }

                    }

                    // ── Network view ──────────────────────────────────────────
                    Column {
                        visible: (root.hoveredSection || root.defaultPopoutSection) === "network"
                        width: parent.width
                        spacing: Theme.spacingS
                        Rectangle {
                            width: parent.width
                            height: 196
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Theme.outline

                            Item {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM

                                Column {
                                    id: networkSummaryRow

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    spacing: Math.max(2, Math.floor(Theme.spacingS / 2))

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingL

                                        StyledText {
                                            text: "↓ " + root.formatNetworkSpeed(root.currentDownloadRate)
                                            color: Theme.info
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                        }

                                        StyledText {
                                            text: "↑ " + root.formatNetworkSpeed(root.currentUploadRate)
                                            color: Theme.error
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                        }
                                    }

                                    StyledText {
                                        width: parent.width
                                        text: root.activeNetworkIp.length > 0 ? "IP " + root.activeNetworkIp : "IP unavailable"
                                        color: Theme.surfaceVariantText
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        elide: Text.ElideRight
                                    }
                                }

                                Item {
                                    id: chartArea

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: networkSummaryRow.bottom
                                    anchors.topMargin: Theme.spacingM
                                    anchors.bottom: parent.bottom

                                    Item {
                                        id: leftAxis

                                        width: 56
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom

                                        StyledText {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            width: parent.width
                                            text: root.formatCompactNetworkSpeed(root.peakDownloadRate)
                                            color: Theme.info
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                        }

                                        StyledText {
                                            anchors.left: parent.left
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            text: "0B/s"
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                        }
                                    }

                                    Item {
                                        id: rightAxis

                                        width: 56
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom

                                        StyledText {
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            width: parent.width
                                            horizontalAlignment: Text.AlignRight
                                            text: root.formatCompactNetworkSpeed(root.peakUploadRate)
                                            color: Theme.error
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                        }

                                        StyledText {
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            horizontalAlignment: Text.AlignRight
                                            text: "0B/s"
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                        }
                                    }

                                    Rectangle {
                                        anchors.left: leftAxis.right
                                        anchors.right: rightAxis.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        radius: Theme.cornerRadius
                                        color: Theme.surface
                                        border.width: 1
                                        border.color: Theme.outline
                                        clip: true

                                        NetworkHistoryChart {
                                            anchors.fill: parent
                                            anchors.margins: Math.max(2, Math.floor(Theme.spacingS / 2))
                                            downloadSeries: root.networkDownloadHistory
                                            uploadSeries: root.networkUploadHistory
                                            downloadPeak: root.peakDownloadRate
                                            uploadPeak: root.peakUploadRate
                                            strokeWidth: Math.max(2, root.networkLineWidth)
                                            gridVisible: root.showNetworkGrid
                                        }
                                    }
                                }
                            }
                        }

                    }

                }

            }

        }

    }

}
