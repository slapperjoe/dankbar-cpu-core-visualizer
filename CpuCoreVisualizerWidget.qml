import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    property int padding: 4
    property bool patchingBarConfig: false
    property var sectionAnchors: ({})
    property string activePopoutSection: ""
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
    property real networkLineWidth: Math.max(1, Math.min(4, numberSetting("networkLineWidth", 2)))
    property real sharedWidgetPadding: (root.barConfig?.removeWidgetPadding ?? false) ? 0 : ((root.barConfig?.widgetPadding ?? 12) * (root.widgetThickness / 30))
    property int sectionShellPadding: Math.max(4, root.barGap + 3)
    property int networkShellPadding: Math.max(2, root.sectionShellPadding - 2)
    property int sectionOuterMargin: Math.max(2, Math.round(root.sharedWidgetPadding / 4))
    property int sectionPillThickness: Math.max(root.minBarHeight + 12, Math.round(root.widgetThickness - root.sectionOuterMargin))
    property int sectionContentThickness: Math.max(root.minBarHeight + 1, root.sectionPillThickness - root.sectionShellPadding * 2)
    property int audioButtonSize: Math.max(root.compactIconSize + 12, root.sectionPillThickness + 2)
    property real sectionPillRadius: Math.min(root.sectionPillThickness / 2, Theme.cornerRadius + root.sectionOuterMargin)
    property bool showNetworkGrid: boolSetting("showNetworkGrid", true)
    property string popoutTriggerMode: boolSetting("popoutOpenOnClick", stringSetting("popoutTriggerMode", "hover") === "click") ? "click" : "hover"
    property var configuredSectionSlots: root.arraySetting("sectionSlots", [])
    property bool showCpuSection: boolSetting("showCpuSection", true)
    property bool showMemorySection: boolSetting("showMemorySection", true)
    property bool showDiskSection: boolSetting("showDiskSection", true)
    property bool showNetworkSection: boolSetting("showNetworkSection", true)
    property bool showGpuSection: boolSetting("showGpuSection", true)
    property int cpuSectionOrder: Math.max(1, Math.min(5, Math.round(numberSetting("cpuSectionOrder", 1))))
    property int memorySectionOrder: Math.max(1, Math.min(5, Math.round(numberSetting("memorySectionOrder", 2))))
    property int diskSectionOrder: Math.max(1, Math.min(5, Math.round(numberSetting("diskSectionOrder", 3))))
    property int networkSectionOrder: Math.max(1, Math.min(5, Math.round(numberSetting("networkSectionOrder", 4))))
    property int gpuSectionOrder: Math.max(1, Math.min(5, Math.round(numberSetting("gpuSectionOrder", 5))))
    property real smoothingFactor: Math.max(0.08, Math.min(0.85, numberSetting("smoothingPercent", 28) / 100))
    property string rawColorMode: stringSetting("colorMode", "vivid")
    property string colorMode: (root.rawColorMode === "soft" || root.rawColorMode === "mono" || root.rawColorMode === "base") ? "soft" : "vivid"
    property real fillOverlayOpacity: root.colorMode === "soft" ? 0.22 : 0.24
    property bool showOverallPercentage: boolSetting("showOverallPercentage", true)
    property bool audioQuickSwitchEnabled: boolSetting("audioQuickSwitchEnabled", false)
    property string audioQuickSwitchPrimary: stringSetting("audioQuickSwitchPrimary", "")
    property string audioQuickSwitchSecondary: stringSetting("audioQuickSwitchSecondary", "")
    property bool barHovered: false
    property bool popoutHovered: false
    property bool detailsPopoutOpen: false
    property string pendingDeferredPopoutSection: ""
    property string hoveredSection: ""
    property var animatedCpuUsage: []
    property real animatedMemoryUsage: 0
    property var animatedDiskUsages: []
    property var animatedGpuUsages: []
    property var networkDownloadHistory: []
    property var networkUploadHistory: []
    property var gpuTelemetry: []
    property var gpuProcesses: []
    property bool nvidiaSmiAvailable: false
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
    readonly property var topGpuProcesses: {
        const procs = Array.isArray(root.gpuProcesses) ? root.gpuProcesses.slice() : [];
        procs.sort((a, b) => (Number(b.usedMemoryMiB) || 0) - (Number(a.usedMemoryMiB) || 0));
        return procs.slice(0, 8);
    }
    readonly property int primaryGpuIndex: {
        if (!Array.isArray(root.gpuTelemetry) || root.gpuTelemetry.length <= 0)
            return -1;

        let selectedIndex = 0;
        let selectedScore = -1;
        for (let i = 0; i < root.gpuTelemetry.length; i++) {
            const gpu = root.gpuTelemetry[i];
            const utilization = root.clampUsage(Number(gpu && gpu.utilization !== undefined ? gpu.utilization : 0));
            const memoryUsage = root.clampUsage(Number(gpu && gpu.memoryUsagePercent !== undefined ? gpu.memoryUsagePercent : 0));
            const score = Math.max(utilization, memoryUsage);
            if (score > selectedScore) {
                selectedScore = score;
                selectedIndex = i;
            }
        }
        return selectedIndex;
    }
    readonly property var primaryGpu: root.primaryGpuIndex >= 0 && root.primaryGpuIndex < root.gpuTelemetry.length ? root.gpuTelemetry[root.primaryGpuIndex] : null
    readonly property real gpuUsageValue: root.primaryGpu ? root.clampUsage(Number(root.primaryGpu.utilization || 0)) : 0
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
    readonly property var validSectionKeys: ["cpu", "memory", "disk", "network", "gpu"]
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
        }, {
            key: "gpu",
            enabled: root.showGpuSection,
            order: root.gpuSectionOrder,
            fallbackIndex: 4
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
    readonly property string currentPopoutSection: {
        if (root.popoutTriggerMode === "hover" && root.hoveredSection.length > 0)
            return root.hoveredSection;
        if (root.activePopoutSection.length > 0)
            return root.activePopoutSection;
        return root.defaultPopoutSection;
    }
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

    function nvidiaNumber(value, fallback = 0) {
        if (value === undefined || value === null)
            return fallback;

        const text = String(value).trim();
        if (text.length <= 0 || text === "N/A" || text === "[N/A]" || text === "[Not Supported]")
            return fallback;

        const parsed = Number(text);
        return Number.isNaN(parsed) ? fallback : parsed;
    }

    function formatGpuMemory(mib) {
        return root.formatStorage(root.nvidiaNumber(mib, 0) * 1024 * 1024);
    }

    function processInfoForPid(pid) {
        const numericPid = Number(pid || 0);
        if (numericPid <= 0 || !Array.isArray(DgopService.allProcesses))
            return null;

        for (let i = 0; i < DgopService.allProcesses.length; i++) {
            const proc = DgopService.allProcesses[i];
            if (Number(proc && proc.pid !== undefined ? proc.pid : 0) === numericPid)
                return proc;
        }

        return null;
    }

    function gpuDisplayNameForProcess(proc) {
        const processInfo = root.processInfoForPid(proc ? proc.pid : 0);
        if (processInfo && processInfo.command)
            return processInfo.command;

        const rawName = String(proc && proc.processName ? proc.processName : "").trim();
        if (rawName.length <= 0)
            return "unknown";

        const slashParts = rawName.split("/");
        return slashParts[slashParts.length - 1] || rawName;
    }

    function refreshGpuTelemetry() {
        if (!nvidiaGpuStatsProcess.running)
            nvidiaGpuStatsProcess.running = true;
        if (!nvidiaGpuAppsProcess.running)
            nvidiaGpuAppsProcess.running = true;
    }

    function parseNvidiaGpuStats(text) {
        const lines = String(text || "").split(/\r?\n/).map(line => line.trim()).filter(line => line.length > 0);
        let nextGpus = [];
        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split(",").map(part => part.trim());
            if (parts.length < 13)
                continue;

            const memoryUsedMiB = root.nvidiaNumber(parts[5], 0);
            const memoryTotalMiB = root.nvidiaNumber(parts[6], 0);
            const memoryUsagePercent = memoryTotalMiB > 0 ? root.clampUsage((memoryUsedMiB / memoryTotalMiB) * 100) : 0;
            nextGpus.push({
                "index": Math.max(0, Math.round(root.nvidiaNumber(parts[0], i))),
                "uuid": parts[1],
                "name": parts[2] || "NVIDIA GPU",
                "temperature": root.nvidiaNumber(parts[3], 0),
                "utilization": root.clampUsage(root.nvidiaNumber(parts[4], 0)),
                "memoryUsedMiB": memoryUsedMiB,
                "memoryTotalMiB": memoryTotalMiB,
                "memoryUsagePercent": memoryUsagePercent,
                "powerDrawWatts": root.nvidiaNumber(parts[7], 0),
                "powerLimitWatts": root.nvidiaNumber(parts[8], 0),
                "graphicsClockMHz": root.nvidiaNumber(parts[9], 0),
                "memoryClockMHz": root.nvidiaNumber(parts[10], 0),
                "encoderUtilization": root.clampUsage(root.nvidiaNumber(parts[11], 0)),
                "decoderUtilization": root.clampUsage(root.nvidiaNumber(parts[12], 0))
            });
        }

        root.gpuTelemetry = nextGpus;
        root.nvidiaSmiAvailable = nextGpus.length > 0;
    }

    function parseNvidiaGpuApps(text) {
        const lines = String(text || "").split(/\r?\n/).map(line => line.trim()).filter(line => line.length > 0 && line.indexOf("No running processes found") === -1);
        let nextProcesses = [];
        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split(",").map(part => part.trim());
            if (parts.length < 4)
                continue;

            const gpuUuid = parts[0];
            const gpu = root.gpuTelemetry.find(entry => entry.uuid === gpuUuid);
            nextProcesses.push({
                "gpuUuid": gpuUuid,
                "gpuName": gpu ? gpu.name : "GPU",
                "pid": Math.max(0, Math.round(root.nvidiaNumber(parts[1], 0))),
                "processName": parts[2] || "",
                "usedMemoryMiB": root.nvidiaNumber(parts[3], 0)
            });
        }

        root.gpuProcesses = nextProcesses;
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
        let nextGpu = root.animatedGpuUsages ? root.animatedGpuUsages.slice() : [];
        const gpuCount = root.gpuTelemetry.length;
        for (let g = 0; g < gpuCount; g++) {
            const gpuTarget = root.gpuUsageFor(g);
            const gpuCurrent = Number(nextGpu[g]);
            nextGpu[g] = root.syncUsageValue(gpuCurrent, gpuTarget, force);
        }
        nextGpu.length = gpuCount;
        root.animatedGpuUsages = nextGpu;
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

    function gpuUsageFor(index) {
        if (index < 0 || index >= root.gpuTelemetry.length)
            return 0;

        const gpu = root.gpuTelemetry[index];
        return root.clampUsage(root.nvidiaNumber(gpu && gpu.utilization !== undefined ? gpu.utilization : 0, 0));
    }

    function cpuRatioFor(index) {
        const animated = Number(root.animatedCpuUsage[index]);
        if (!Number.isNaN(animated))
            return root.clampUsage(animated) / 100;

        return root.usageFor(index) / 100;
    }

    function colorFor(index) {
        if (root.colorMode === "soft")
            return root.softPalette[index % root.softPalette.length];

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
        if (sectionKey === "gpu")
            return "developer_board";

        if (sectionKey === "memory")
            return "sd_card";

        if (sectionKey === "disk")
            return "storage";

        if (sectionKey === "network")
            return "network_check";

        return "memory";
    }

    function sectionTitle(sectionKey) {
        if (sectionKey === "gpu")
            return "GPU";

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

        if (sectionKey === "gpu")
            return Math.max(1, root.gpuTelemetry.length);

        if (sectionKey === "disk")
            return Math.max(1, root.selectedDiskMounts.length);

        return 1;
    }

    function sectionUsageFor(sectionKey, index) {
        if (sectionKey === "gpu")
            return root.gpuUsageFor(index);

        if (sectionKey === "memory")
            return root.memoryUsageValue;

        if (sectionKey === "disk")
            return root.diskMountUsageFor(index);

        if (sectionKey === "network")
            return 0;

        return root.usageFor(index);
    }

    function sectionAnimatedUsageFor(sectionKey, index) {
        if (sectionKey === "gpu")
            return Number(root.animatedGpuUsages[index]);

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
        if (sectionKey === "gpu")
            return root.primaryGpu ? root.gpuUsageValue.toFixed(0) + "%" : "—";

        if (sectionKey === "network")
            return root.formatCompactNetworkSpeed(root.currentDownloadRate) + " / " + root.formatCompactNetworkSpeed(root.currentUploadRate);

        if (sectionKey === "disk")
            return root.diskUsageValue.toFixed(0) + "%";

        return root.sectionUsageFor(sectionKey, 0).toFixed(0) + "%";
    }

    function sectionColorFor(sectionKey, index) {
        if (sectionKey === "cpu")
            return root.colorFor(index);

        if (sectionKey === "gpu")
            return root.colorMode === "soft" ? root.softPalette[(index * 5 + 10) % root.softPalette.length] : root.vividPalette[(index * 5 + 13) % root.vividPalette.length];

        if (sectionKey === "memory")
            return root.colorMode === "soft" ? root.softPalette[11] : root.vividPalette[13];

        if (sectionKey === "disk")
            return root.colorMode === "soft" ? root.softPalette[(index * 7 + 3) % root.softPalette.length] : root.vividPalette[(index * 7 + 3) % root.vividPalette.length];

        if (sectionKey === "network")
            return index === 0 ? Theme.info : Theme.error;

        return root.colorMode === "soft" ? root.softPalette[index % root.softPalette.length] : root.vividPalette[index % root.vividPalette.length];
    }

    function networkDownloadColor() {
        return root.colorMode === "soft" ? root.softPalette[11] : root.vividPalette[13];
    }

    function networkUploadColor() {
        return root.colorMode === "soft" ? root.softPalette[0] : root.vividPalette[0];
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
        if (sectionKey === "gpu") {
            if (!root.nvidiaSmiAvailable)
                return "NVIDIA tools unavailable";

            if (!root.primaryGpu)
                return "Waiting for GPU stats";

            let subtitle = root.primaryGpu.name + "  " + root.gpuUsageValue.toFixed(0) + "%";
            if (root.primaryGpu.memoryTotalMiB > 0)
                subtitle += "  |  " + root.formatGpuMemory(root.primaryGpu.memoryUsedMiB) + " / " + root.formatGpuMemory(root.primaryGpu.memoryTotalMiB);
            if (root.primaryGpu.temperature > 0)
                subtitle += "  |  " + Math.round(root.primaryGpu.temperature) + "°C";
            if (root.gpuTelemetry.length > 1)
                subtitle += "  |  " + root.gpuTelemetry.length + " GPUs";
            return subtitle;
        }

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
        if (root.primaryGpu)
            summary += "  |  GPU " + root.gpuUsageValue.toFixed(0) + "%";
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
        if (root.primaryGpu) {
            let gpuLine = root.primaryGpu.name + "  |  " + root.gpuUsageValue.toFixed(0) + "% util";
            if (root.primaryGpu.memoryTotalMiB > 0)
                gpuLine += "  |  VRAM " + root.formatGpuMemory(root.primaryGpu.memoryUsedMiB) + " / " + root.formatGpuMemory(root.primaryGpu.memoryTotalMiB);
            if (root.primaryGpu.temperature > 0)
                gpuLine += "  |  " + Math.round(root.primaryGpu.temperature) + "°C";
            lines.push("GPU: " + gpuLine);
        }
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
        if (root.primaryGpu)
            summary += "  |  GPU " + root.gpuUsageValue.toFixed(0) + "%";
        if (DgopService.cpuTemperature > 0)
            summary += "  |  " + Math.round(DgopService.cpuTemperature) + "°C";
        return summary;
    }

    function availableAudioToggleSinks() {
        const sinks = AudioService.getAvailableSinks();
        if (!Array.isArray(sinks))
            return [];

        const configuredNames = [root.audioQuickSwitchPrimary, root.audioQuickSwitchSecondary].filter(name => name && name.length > 0);
        let targets = sinks.filter(node => configuredNames.indexOf(node.name) !== -1);

        if (configuredNames.length >= 2 && targets.length >= 2)
            return targets;

        return sinks;
    }

    function audioSinkIconName(sink) {
        if (!sink)
            return "speaker";

        const sinkIcon = String(AudioService.sinkIcon(sink) || "speaker");
        if (sinkIcon === "tv")
            return "monitor";
        if (sinkIcon === "headset")
            return "headset";
        return "speaker";
    }

    function audioSinkLabel(sink) {
        if (!sink)
            return "No audio output";

        return AudioService.displayName(sink) || sink.description || sink.name || "Audio output";
    }

    function isAudioSinkActive(sink) {
        const activeName = AudioService.sink && AudioService.sink.name ? AudioService.sink.name : "";
        return Boolean(sink && sink.name && activeName.length > 0 && sink.name === activeName);
    }

    function selectAudioOutput(sink) {
        if (!sink)
            return false;

        Pipewire.preferredDefaultAudioSink = sink;
        return true;
    }

    function audioButtonIcon() {
        return root.audioSinkIconName(AudioService.sink);
    }

    function barPositionValue() {
        if (root.axis?.edge === "left")
            return SettingsData.Position.Left;
        if (root.axis?.edge === "right")
            return SettingsData.Position.Right;
        if (root.axis?.edge === "bottom")
            return SettingsData.Position.Bottom;
        return SettingsData.Position.Top;
    }

    function registerSectionAnchor(sectionKey, item) {
        if (!sectionKey || !item)
            return;
        const next = Object.assign({}, root.sectionAnchors);
        next[sectionKey] = item;
        root.sectionAnchors = next;
    }

    function unregisterSectionAnchor(sectionKey, item) {
        if (!sectionKey || !item || root.sectionAnchors[sectionKey] !== item)
            return;
        const next = Object.assign({}, root.sectionAnchors);
        delete next[sectionKey];
        root.sectionAnchors = next;
    }

    function sectionAnchor(sectionKey) {
        return root.sectionAnchors[sectionKey] || null;
    }

    function positionSectionPopout(sectionKey) {
        const anchor = root.sectionAnchor(sectionKey);
        if (!anchor || !root.parentScreen)
            return false;

        const globalPos = anchor.mapToItem(null, 0, 0);
        const barPosition = root.barPositionValue();
        let triggerY = globalPos.y;
        if (barPosition === SettingsData.Position.Left || barPosition === SettingsData.Position.Right)
            triggerY = globalPos.y + anchor.height / 2;
        else if (barPosition === SettingsData.Position.Top)
            triggerY = globalPos.y + anchor.height;
        sectionPopout.setTriggerPosition(globalPos.x, triggerY, anchor.width, root.section, root.parentScreen, barPosition, root.barThickness, root.barSpacing, root.barConfig);
        return true;
    }

    function openSectionPopout(sectionKey) {
        closePopoutTimer.stop();
        root.activePopoutSection = sectionKey;
        if (!root.positionSectionPopout(sectionKey))
            return;
        sectionPopout.open();
    }

    function deferSectionPopout(sectionKey) {
        root.pendingDeferredPopoutSection = sectionKey;
        deferredPopoutOpenTimer.restart();
    }

    function toggleSectionPopout(sectionKey) {
        if (sectionPopout.shouldBeVisible && root.activePopoutSection === sectionKey) {
            root.closeDetailsPopout();
            return;
        }
        root.openSectionPopout(sectionKey);
    }

    function handleSectionHover(sectionKey) {
        root.hoveredSection = sectionKey;
        if (root.popoutTriggerMode === "hover")
            root.openSectionPopout(sectionKey);
    }

    function clearHoveredSection(sectionKey) {
        if (root.hoveredSection === sectionKey && !root.barHovered && !root.popoutHovered)
            root.hoveredSection = "";
    }

    function ensureTransparentHostPill() {
        if (!root.barConfig || root.patchingBarConfig || root.barConfig._cpuCoreVisualizerPatched)
            return;

        root.patchingBarConfig = true;
        const nextConfig = Object.assign({}, root.barConfig);
        nextConfig.noBackground = true;
        nextConfig.removeWidgetPadding = true;
        nextConfig._cpuCoreVisualizerPatched = true;
        root.barConfig = nextConfig;
        root.patchingBarConfig = false;
    }

    component HorizontalAudioToggleButton: Rectangle {
        id: horizontalAudioButton

        width: root.audioButtonSize
        height: root.sectionPillThickness
        radius: root.sectionPillRadius
        color: audioButtonMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

        Component.onCompleted: root.registerSectionAnchor("audio", horizontalAudioButton)
        Component.onDestruction: root.unregisterSectionAnchor("audio", horizontalAudioButton)

        DankRipple {
            id: horizontalAudioRipple
            cornerRadius: horizontalAudioButton.radius
        }

        DankIcon {
            anchors.centerIn: parent
            name: root.audioButtonIcon()
            size: Math.min(root.sectionPillThickness - 6, root.compactIconSize + 2)
            color: Theme.widgetTextColor
            filled: true
        }

        MouseArea {
            id: audioButtonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (containsMouse)
                    root.handleSectionHover("audio");
                else
                    root.clearHoveredSection("audio");
            }
            onPressed: mouse => horizontalAudioRipple.trigger(mouse.x, mouse.y)
            acceptedButtons: Qt.LeftButton
            onClicked: root.deferSectionPopout("audio")
        }
    }

    component VerticalAudioToggleButton: Rectangle {
        id: verticalAudioButton

        width: root.sectionPillThickness
        height: width
        radius: root.sectionPillRadius
        color: audioButtonMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

        Component.onCompleted: root.registerSectionAnchor("audio", verticalAudioButton)
        Component.onDestruction: root.unregisterSectionAnchor("audio", verticalAudioButton)

        DankRipple {
            id: verticalAudioRipple
            cornerRadius: verticalAudioButton.radius
        }

        DankIcon {
            anchors.centerIn: parent
            name: root.audioButtonIcon()
            size: Math.min(parent.width - 6, root.compactIconSize + 2)
            color: Theme.widgetTextColor
            filled: true
        }

        MouseArea {
            id: audioButtonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (containsMouse)
                    root.handleSectionHover("audio");
                else
                    root.clearHoveredSection("audio");
            }
            onPressed: mouse => verticalAudioRipple.trigger(mouse.x, mouse.y)
            acceptedButtons: Qt.LeftButton
            onClicked: root.deferSectionPopout("audio")
        }
    }

    function openDetailsPopout() {
        closePopoutTimer.stop();
        if (root.popoutTriggerMode !== "hover")
            return;
        const sectionKey = root.currentPopoutSection;
        if (!sectionKey)
            return;
        root.openSectionPopout(sectionKey);
    }

    function scheduleClosePopout() {
        if (root.popoutTriggerMode === "click")
            return;
        if (root.barHovered || root.popoutHovered)
            return ;

        closePopoutTimer.restart();
    }

    function closeDetailsPopout() {
        closePopoutTimer.stop();
        if (!sectionPopout.shouldBeVisible)
            return ;

        sectionPopout.close();
        root.detailsPopoutOpen = false;
        root.hoveredSection = "";
        if (root.popoutTriggerMode === "click")
            root.activePopoutSection = "";
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

    TextMetrics {
        id: compactArrowMetrics

        font.pixelSize: root.overallTextSize()
        font.weight: Font.Medium
        text: "↓"
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

            const inset = Math.min(Math.max(strokeWidth / 2, 0.5), Math.min(width, height) / 2);
            const drawableWidth = Math.max(0, width - inset * 2);
            const drawableHeight = Math.max(0, height - inset * 2);

            ctx.beginPath();
            ctx.lineWidth = strokeWidth;
            ctx.strokeStyle = strokeColor;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";

            for (let i = 0; i < series.length; i++) {
                const x = series.length <= 1 ? width / 2 : inset + (i / (series.length - 1)) * drawableWidth;
                const ratio = Math.max(0, Math.min(1, Number(series[i] || 0) / Math.max(1, peak)));
                const y = height - inset - ratio * drawableHeight;
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

    component HorizontalNetworkSection: Rectangle {
        id: horizontalNetwork

        implicitWidth: networkContent.implicitWidth + root.networkShellPadding * 2
        implicitHeight: root.sectionPillThickness
        radius: root.sectionPillRadius
        color: horizontalNetworkHover.hovered ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

        Component.onCompleted: root.registerSectionAnchor("network", horizontalNetwork)
        Component.onDestruction: root.unregisterSectionAnchor("network", horizontalNetwork)

        HoverHandler {
            id: horizontalNetworkHover
            onHoveredChanged: {
                if (hovered)
                    root.handleSectionHover("network");
                else
                    root.clearHoveredSection("network");
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                if (root.popoutTriggerMode === "click")
                    root.toggleSectionPopout("network");
            }
        }

        Row {
            id: networkContent

            anchors.centerIn: parent
            spacing: root.barGap

            Item {
                width: Math.ceil(networkLabelMetrics.advanceWidth)
                height: downloadSpeedText.implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    id: downloadSpeedText

                    anchors.left: parent.left
                    anchors.right: downloadArrowText.left
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: root.formatCompactNetworkSpeed(root.currentDownloadRate)
                    color: Theme.widgetTextColor
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Medium
                }

                StyledText {
                    id: downloadArrowText

                    width: Math.ceil(compactArrowMetrics.advanceWidth)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↓"
                    color: Theme.info
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                width: root.networkChartWidth
                height: Math.max(root.minBarHeight + 1, horizontalNetwork.height - 6)
                anchors.verticalCenter: parent.verticalCenter
                radius: Math.min(root.cornerRadius + 1, height / 2)
                color: Theme.surfaceContainer
                clip: true

                NetworkHistoryChart {
                    anchors.fill: parent
                    downloadSeries: root.networkDownloadHistory
                    uploadSeries: root.networkUploadHistory
                    downloadPeak: root.peakDownloadRate
                    uploadPeak: root.peakUploadRate
                    downloadColor: root.networkDownloadColor()
                    uploadColor: root.networkUploadColor()
                    strokeWidth: root.networkLineWidth
                    gridVisible: root.showNetworkGrid
                }
            }

            Item {
                width: Math.ceil(networkLabelMetrics.advanceWidth)
                height: uploadSpeedText.implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    id: uploadArrowText

                    width: Math.ceil(compactArrowMetrics.advanceWidth)
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↑"
                    color: Theme.error
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Medium
                }

                StyledText {
                    id: uploadSpeedText

                    anchors.left: uploadArrowText.right
                    anchors.leftMargin: 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.formatCompactNetworkSpeed(root.currentUploadRate)
                    color: Theme.widgetTextColor
                    font.pixelSize: root.overallTextSize()
                    font.weight: Font.Medium
                }
            }
        }
    }

    component VerticalNetworkSection: Rectangle {
        id: verticalNetwork

        property int availableWidth: root.sectionPillThickness

        implicitWidth: availableWidth + root.networkShellPadding * 2
        implicitHeight: verticalNetworkContent.implicitHeight + root.networkShellPadding * 2
        radius: root.sectionPillRadius
        color: verticalNetworkHover.hovered ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

        Component.onCompleted: root.registerSectionAnchor("network", verticalNetwork)
        Component.onDestruction: root.unregisterSectionAnchor("network", verticalNetwork)

        HoverHandler {
            id: verticalNetworkHover
            onHoveredChanged: {
                if (hovered)
                    root.handleSectionHover("network");
                else
                    root.clearHoveredSection("network");
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                if (root.popoutTriggerMode === "click")
                    root.toggleSectionPopout("network");
            }
        }

        Column {
            id: verticalNetworkContent

            anchors.centerIn: parent
            spacing: root.barGap

            Item {
                width: verticalNetwork.availableWidth
                height: verticalDownloadSpeedText.implicitHeight

                StyledText {
                    id: verticalDownloadSpeedText

                    anchors.left: parent.left
                    anchors.right: verticalDownloadArrowText.left
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: root.formatCompactNetworkSpeed(root.currentDownloadRate)
                    color: Theme.widgetTextColor
                    font.pixelSize: Math.max(8, root.overallTextSize() - 1)
                    font.weight: Font.Medium
                }

                StyledText {
                    id: verticalDownloadArrowText

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↓"
                    color: Theme.info
                    font.pixelSize: Math.max(8, root.overallTextSize() - 1)
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                width: verticalNetwork.availableWidth
                height: Math.max(root.sectionPillThickness * 2 - 2, verticalNetwork.availableWidth * 2)
                radius: Math.min(root.cornerRadius + 1, height / 3)
                color: Theme.surfaceContainer
                clip: true

                NetworkHistoryChart {
                    anchors.fill: parent
                    downloadSeries: root.networkDownloadHistory
                    uploadSeries: root.networkUploadHistory
                    downloadPeak: root.peakDownloadRate
                    uploadPeak: root.peakUploadRate
                    downloadColor: root.networkDownloadColor()
                    uploadColor: root.networkUploadColor()
                    strokeWidth: root.networkLineWidth
                    gridVisible: root.showNetworkGrid
                }
            }

            Item {
                width: verticalNetwork.availableWidth
                height: verticalUploadSpeedText.implicitHeight

                StyledText {
                    id: verticalUploadArrowText

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↑"
                    color: Theme.error
                    font.pixelSize: Math.max(8, root.overallTextSize() - 1)
                    font.weight: Font.Medium
                }

                StyledText {
                    id: verticalUploadSpeedText

                    anchors.left: verticalUploadArrowText.right
                    anchors.leftMargin: 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.formatCompactNetworkSpeed(root.currentUploadRate)
                    color: Theme.widgetTextColor
                    font.pixelSize: Math.max(8, root.overallTextSize() - 1)
                    font.weight: Font.Medium
                }
            }
        }
    }

    component HorizontalMetricSection: Rectangle {
        id: horizontalSection

        property string sectionKey: ""
        property string registeredSectionKey: ""

        implicitWidth: metricContent.implicitWidth + root.sectionShellPadding * 2
        implicitHeight: root.sectionPillThickness
        radius: root.sectionPillRadius
        color: horizontalMetricHover.hovered ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

        function refreshAnchorRegistration() {
            if (registeredSectionKey.length > 0 && registeredSectionKey !== sectionKey)
                root.unregisterSectionAnchor(registeredSectionKey, horizontalSection);
            if (sectionKey.length > 0) {
                root.registerSectionAnchor(sectionKey, horizontalSection);
                registeredSectionKey = sectionKey;
            }
        }

        Component.onCompleted: refreshAnchorRegistration()
        Component.onDestruction: root.unregisterSectionAnchor(registeredSectionKey, horizontalSection)
        onSectionKeyChanged: refreshAnchorRegistration()

        HoverHandler {
            id: horizontalMetricHover
            onHoveredChanged: {
                if (hovered)
                    root.handleSectionHover(horizontalSection.sectionKey);
                else
                    root.clearHoveredSection(horizontalSection.sectionKey);
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                if (root.popoutTriggerMode === "click")
                    root.toggleSectionPopout(horizontalSection.sectionKey);
            }
        }

        Row {
            id: metricContent

            anchors.centerIn: parent
            spacing: root.sectionPadding

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.barGap

                Repeater {
                    model: root.sectionBarCount(horizontalSection.sectionKey)

                    delegate: Item {
                        width: root.barWidth
                        height: (horizontalSection.sectionKey === "cpu" || horizontalSection.sectionKey === "gpu") ? Math.max(root.minBarHeight + 1, horizontalSection.height - 8) : root.sectionContentThickness

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
                    color: Theme.widgetTextColor
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
    }

    component VerticalMetricSection: Rectangle {
        id: verticalSection

        property string sectionKey: ""
        property int availableWidth: root.sectionPillThickness
        property bool fillFromLeft: root.axis?.edge === "left"
        property string registeredSectionKey: ""

        implicitWidth: availableWidth + root.sectionShellPadding * 2
        implicitHeight: verticalMetricContent.implicitHeight + root.sectionShellPadding * 2
        radius: root.sectionPillRadius
        color: verticalMetricHover.hovered ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

        function refreshAnchorRegistration() {
            if (registeredSectionKey.length > 0 && registeredSectionKey !== sectionKey)
                root.unregisterSectionAnchor(registeredSectionKey, verticalSection);
            if (sectionKey.length > 0) {
                root.registerSectionAnchor(sectionKey, verticalSection);
                registeredSectionKey = sectionKey;
            }
        }

        Component.onCompleted: refreshAnchorRegistration()
        Component.onDestruction: root.unregisterSectionAnchor(registeredSectionKey, verticalSection)
        onSectionKeyChanged: refreshAnchorRegistration()

        HoverHandler {
            id: verticalMetricHover
            onHoveredChanged: {
                if (hovered)
                    root.handleSectionHover(verticalSection.sectionKey);
                else
                    root.clearHoveredSection(verticalSection.sectionKey);
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                if (root.popoutTriggerMode === "click")
                    root.toggleSectionPopout(verticalSection.sectionKey);
            }
        }

        Column {
            id: verticalMetricContent

            anchors.centerIn: parent
            spacing: root.sectionPadding

            Column {
                width: (verticalSection.sectionKey === "cpu" || verticalSection.sectionKey === "gpu") ? Math.max(root.minBarHeight + 1, verticalSection.width - 2) : verticalSection.availableWidth
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
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: Math.min(verticalSection.availableWidth, Math.ceil(overallPercentageMetrics.advanceWidth))
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
        root.ensureTransparentHostPill();
        DgopService.addRef(["cpu", "memory", "diskmounts", "processes", "network"]);
        root.syncAnimatedUsage(true);
        root.appendNetworkHistorySample(root.currentDownloadRate, root.currentUploadRate);
        DgopService.updateAllStats();
        root.refreshGpuTelemetry();
        root.queueNetworkHistoryCapture();
    }
    onBarConfigChanged: root.ensureTransparentHostPill()
    Component.onDestruction: {
        closePopoutTimer.stop();
        networkHistoryCaptureTimer.stop();
        DgopService.removeRef(["cpu", "memory", "diskmounts", "processes", "network"]);
        nvidiaGpuStatsProcess.running = false;
        nvidiaGpuAppsProcess.running = false;
    }
    onRawCoreUsageChanged: root.syncAnimatedUsage(root.animatedCpuUsage.length !== root.rawCoreUsage.length)
    onMemoryUsageValueChanged: root.syncAnimatedUsage(false)
    onSelectedDiskMountsChanged: root.syncAnimatedUsage(root.animatedDiskUsages.length !== root.selectedDiskMounts.length)
    onGpuTelemetryChanged: root.syncAnimatedUsage(root.animatedGpuUsages.length !== root.gpuTelemetry.length)
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
        id: deferredPopoutOpenTimer

        interval: 1
        repeat: false
        onTriggered: {
            const sectionKey = root.pendingDeferredPopoutSection;
            root.pendingDeferredPopoutSection = "";
            if (sectionKey.length > 0)
                root.openSectionPopout(sectionKey);
        }
    }

    Timer {
        id: probeTimer

        interval: root.probeInterval
        repeat: true
        running: true
        onTriggered: {
            DgopService.updateAllStats();
            root.refreshGpuTelemetry();
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

    Process {
        id: nvidiaGpuStatsProcess

        command: ["nvidia-smi", "--query-gpu=index,uuid,name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw,power.limit,clocks.gr,clocks.mem,utilization.encoder,utilization.decoder", "--format=csv,noheader,nounits"]
        running: false
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.nvidiaSmiAvailable = false;
                root.gpuTelemetry = [];
            }
        }

        stdout: StdioCollector {
            onStreamFinished: root.parseNvidiaGpuStats(text)
        }
    }

    Process {
        id: nvidiaGpuAppsProcess

        command: ["nvidia-smi", "--query-compute-apps=gpu_uuid,pid,process_name,used_memory", "--format=csv,noheader,nounits"]
        running: false
        onExited: exitCode => {
            if (exitCode !== 0)
                root.gpuProcesses = [];
        }

        stdout: StdioCollector {
            onStreamFinished: root.parseNvidiaGpuApps(text)
        }
    }

    horizontalBarPill: Component {
        Item {
            id: horizontalRoot

            implicitWidth: root.padding * 2 + horizontalContent.implicitWidth
            implicitHeight: root.widgetThickness

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                }
            }

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

                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    active: root.audioQuickSwitchEnabled
                    sourceComponent: HorizontalAudioToggleButton {
                    }
                }

            }

            HoverHandler {
                id: horizontalHoverArea

                onHoveredChanged: {
                    root.barHovered = hovered;
                    if (hovered && root.popoutTriggerMode === "hover")
                        root.openDetailsPopout();
                    else {
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
            implicitHeight: root.padding * 2 + verticalContent.implicitHeight + root.sectionOuterMargin * 2

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                }
            }

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

                Loader {
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: root.audioQuickSwitchEnabled
                    sourceComponent: VerticalAudioToggleButton {
                    }
                }

            }

            HoverHandler {
                id: verticalHoverArea

                onHoveredChanged: {
                    root.barHovered = hovered;
                    if (hovered && root.popoutTriggerMode === "hover")
                        root.openDetailsPopout();
                    else {
                        root.scheduleClosePopout();
                    }
                }
            }

        }

    }

    Component {
        id: detailsPanelComponent

        PopoutComponent {
            id: detailsPopout

            headerText: {
                if (root.defaultPopoutSection === "")
                    return "Details";
                if (root.currentPopoutSection === "audio")
                    return "Audio";
                if (root.currentPopoutSection === "memory")
                    return "Memory";
                if (root.currentPopoutSection === "disk")
                    return "Storage";
                if (root.currentPopoutSection === "network")
                    return "Network";
                if (root.currentPopoutSection === "gpu")
                    return "GPU";
                return "CPU";
            }
            detailsText: {
                if (root.currentPopoutSection === "audio") {
                    if (!AudioService.sink)
                        return "No audio output available";
                    let label = AudioService.displayName(AudioService.sink);
                    const volume = AudioService.sink?.audio ? Math.round(AudioService.sink.audio.volume * 100) : 0;
                    const muted = AudioService.sink?.audio?.muted ? "  |  muted" : "";
                    return label + "  |  " + volume + "%" + muted;
                }
                if (root.currentPopoutSection === "memory") {
                    const total = Number(DgopService.totalMemoryKB || 0);
                    if (total <= 0)
                        return "Waiting for memory stats";
                    return DgopService.formatSystemMemory(DgopService.usedMemoryKB) + " / " + DgopService.formatSystemMemory(total) + "  |  " + root.memoryUsageValue.toFixed(0) + "%";
                }
                if (root.currentPopoutSection === "disk")
                    return root.diskSelectionLabel;
                if (root.currentPopoutSection === "network")
                    return "";
                if (root.currentPopoutSection === "gpu") {
                    if (!root.nvidiaSmiAvailable)
                        return "nvidia-smi unavailable";
                    if (!root.primaryGpu)
                        return "Waiting for GPU stats";
                    return root.sectionSummarySubtitle("gpu");
                }
                if (root.defaultPopoutSection === "")
                    return "Enable at least one section to show data here";
                return root.shortSummaryText();
            }
            showCloseButton: false

            Connections {
                function onShouldBeVisibleChanged() {
                    root.detailsPopoutOpen = sectionPopout.shouldBeVisible;
                    if (!root.detailsPopoutOpen)
                        root.popoutHovered = false;

                }

                target: sectionPopout
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

                    Column {
                        visible: root.currentPopoutSection === "audio"
                        width: parent.width
                        spacing: Theme.spacingM

                        Flow {
                            id: audioSourceFlow

                            visible: root.availableAudioToggleSinks().length > 1
                            width: parent.width
                            spacing: Theme.spacingS

                            Repeater {
                                model: root.availableAudioToggleSinks()

                                delegate: Rectangle {
                                    required property var modelData

                                    width: Math.max(110, Math.min(180, (audioSourceFlow.width - audioSourceFlow.spacing) / 2))
                                    height: 52
                                    radius: Theme.cornerRadius
                                    color: root.isAudioSinkActive(modelData) ? Theme.primaryHoverLight : Theme.surfaceContainerHigh
                                    border.width: 1
                                    border.color: root.isAudioSinkActive(modelData) ? Theme.primary : Theme.outline

                                    DankRipple {
                                        id: audioSourceRipple
                                        cornerRadius: parent.radius
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: mouse => audioSourceRipple.trigger(mouse.x, mouse.y)
                                        onClicked: root.selectAudioOutput(parent.modelData)
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.spacingM
                                        anchors.rightMargin: Theme.spacingM
                                        spacing: Theme.spacingS

                                        DankIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: root.audioSinkIconName(modelData)
                                            size: Theme.iconSize
                                            color: root.isAudioSinkActive(modelData) ? Theme.primary : Theme.surfaceText
                                            filled: true
                                        }

                                        StyledText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - Theme.iconSize - Theme.spacingS
                                            text: root.audioSinkLabel(modelData)
                                            color: Theme.surfaceText
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: root.isAudioSinkActive(modelData) ? Font.Medium : Font.Normal
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 72
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                spacing: Theme.spacingM

                                DankIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: root.audioButtonIcon()
                                    size: Theme.iconSizeLarge
                                    color: Theme.primary
                                    filled: true
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - Theme.iconSizeLarge - Theme.spacingM * 2
                                    spacing: Theme.spacingXS

                                    StyledText {
                                        width: parent.width
                                        text: root.audioSinkLabel(AudioService.sink)
                                        color: Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        width: parent.width
                                        text: {
                                            const sinkCount = root.availableAudioToggleSinks().length;
                                            if (!AudioService.sink)
                                                return "";
                                            if (sinkCount > 1)
                                                return "Click an output above to switch devices.";
                                            return "Only one output is currently available.";
                                        }
                                        color: Theme.surfaceVariantText
                                        font.pixelSize: Theme.fontSizeSmall
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: audioMuteMouse.containsMouse ? Theme.primaryHoverLight : Theme.surfaceContainerHigh

                                DankRipple {
                                    id: audioMuteRipple
                                    cornerRadius: parent.radius
                                }

                                MouseArea {
                                    id: audioMuteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: mouse => audioMuteRipple.trigger(mouse.x, mouse.y)
                                    onClicked: {
                                        if (AudioService.sink?.audio)
                                            AudioService.sink.audio.muted = !AudioService.sink.audio.muted;
                                    }
                                }

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: {
                                        if (!AudioService.sink?.audio)
                                            return "volume_off";
                                        if (AudioService.sink.audio.muted)
                                            return "volume_off";
                                        if (AudioService.sink.audio.volume === 0)
                                            return "volume_mute";
                                        if (AudioService.sink.audio.volume <= 0.33)
                                            return "volume_down";
                                        return "volume_up";
                                    }
                                    size: Theme.iconSize
                                    color: AudioService.sink?.audio && !AudioService.sink.audio.muted && AudioService.sink.audio.volume > 0 ? Theme.primary : Theme.surfaceText
                                }
                            }

                            DankSlider {
                                readonly property real actualVolumePercent: AudioService.sink?.audio ? Math.round(AudioService.sink.audio.volume * 100) : 0

                                width: parent.width - 40 - Theme.spacingS
                                enabled: AudioService.sink?.audio != null
                                minimum: 0
                                maximum: AudioService.sinkMaxVolume
                                value: AudioService.sink?.audio ? Math.min(AudioService.sinkMaxVolume, Math.round(AudioService.sink.audio.volume * 100)) : 0
                                showValue: true
                                unit: "%"
                                valueOverride: actualVolumePercent
                                thumbOutlineColor: Theme.surfaceContainer
                                trackColor: Theme.ccSliderTrackColor
                                trackOpacity: Theme.ccSliderTrackOpacity
                                anchors.verticalCenter: parent.verticalCenter

                                onSliderValueChanged: function (newValue) {
                                    if (AudioService.sink?.audio) {
                                        AudioService.sink.audio.volume = newValue / 100.0;
                                        if (newValue > 0 && AudioService.sink.audio.muted)
                                            AudioService.sink.audio.muted = false;
                                    }
                                }
                            }
                        }
                    }

                    // ── CPU / overview view ──────────────────────────────────
                    Column {
                        visible: root.currentPopoutSection === "cpu"
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
                                        opacity: root.fillOverlayOpacity

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
                                        color: Theme.widgetTextColor
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
                        visible: root.currentPopoutSection === "memory"
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
                                opacity: root.fillOverlayOpacity

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
                                color: Theme.widgetTextColor
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
                                    opacity: root.fillOverlayOpacity

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
                                    color: Theme.widgetTextColor
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

                    // ── GPU view ─────────────────────────────────────────────
                    Column {
                        visible: root.currentPopoutSection === "gpu"
                        width: parent.width
                        spacing: Theme.spacingS

                        Rectangle {
                            width: parent.width
                            height: root.nvidiaSmiAvailable ? 88 : 72
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Theme.outline
                            clip: true

                            Rectangle {
                                visible: root.primaryGpu != null
                                anchors.top: parent.top
                                anchors.left: parent.left
                                width: parent.width * (root.gpuUsageValue / 100)
                                height: parent.height
                                radius: Theme.cornerRadius
                                color: root.sectionColorFor("gpu", 0)
                                opacity: root.fillOverlayOpacity

                                Behavior on width {
                                    NumberAnimation {
                                        duration: root.animationDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingXS

                                StyledText {
                                    width: parent.width
                                    text: {
                                        if (!root.nvidiaSmiAvailable)
                                            return "nvidia-smi unavailable";
                                        if (!root.primaryGpu)
                                            return "Waiting for GPU stats";
                                        return root.primaryGpu.name;
                                    }
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    width: parent.width
                                    text: {
                                        if (!root.nvidiaSmiAvailable)
                                            return "Install NVIDIA drivers/tools to show GPU utilization, VRAM, power, and process data.";
                                        if (!root.primaryGpu)
                                            return "No NVIDIA GPU telemetry available yet.";

                                        let line = root.gpuUsageValue.toFixed(0) + "% util";
                                        if (root.primaryGpu.memoryTotalMiB > 0)
                                            line += "  |  " + root.formatGpuMemory(root.primaryGpu.memoryUsedMiB) + " / " + root.formatGpuMemory(root.primaryGpu.memoryTotalMiB);
                                        if (root.primaryGpu.temperature > 0)
                                            line += "  |  " + Math.round(root.primaryGpu.temperature) + "°C";
                                        if (root.primaryGpu.powerDrawWatts > 0)
                                            line += "  |  " + root.primaryGpu.powerDrawWatts.toFixed(root.primaryGpu.powerDrawWatts >= 100 ? 0 : 1) + " W";
                                        return line;
                                    }
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    wrapMode: Text.WordWrap
                                }

                                StyledText {
                                    visible: root.primaryGpu != null
                                    width: parent.width
                                    text: {
                                        if (!root.primaryGpu)
                                            return "";

                                        let parts = [];
                                        if (root.primaryGpu.graphicsClockMHz > 0)
                                            parts.push(Math.round(root.primaryGpu.graphicsClockMHz) + " MHz gfx");
                                        if (root.primaryGpu.memoryClockMHz > 0)
                                            parts.push(Math.round(root.primaryGpu.memoryClockMHz) + " MHz mem");
                                        parts.push(root.primaryGpu.encoderUtilization.toFixed(0) + "% enc");
                                        parts.push(root.primaryGpu.decoderUtilization.toFixed(0) + "% dec");
                                        if (root.gpuTelemetry.length > 1)
                                            parts.push(root.gpuTelemetry.length + " GPUs");
                                        return parts.join("  |  ");
                                    }
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Repeater {
                            model: root.gpuTelemetry

                            delegate: Rectangle {
                                visible: root.gpuTelemetry.length > 1
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
                                    width: parent.width * (root.clampUsage(Number(modelData.utilization || 0)) / 100)
                                    height: parent.height
                                    radius: Theme.cornerRadius
                                    color: root.sectionColorFor("gpu", index)
                                    opacity: root.fillOverlayOpacity

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: root.animationDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    anchors.right: gpuCardUsageText.left
                                    anchors.rightMargin: Theme.spacingS
                                    text: modelData.name || ("GPU " + index)
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    id: gpuCardUsageText

                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: root.clampUsage(Number(modelData.utilization || 0)).toFixed(0) + "%"
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Theme.spacingS
                                    anchors.right: parent.right
                                    text: root.formatGpuMemory(modelData.memoryUsedMiB) + " / " + root.formatGpuMemory(modelData.memoryTotalMiB) + "  |  " + Math.round(Number(modelData.temperature || 0)) + "°C  |  " + Number(modelData.powerDrawWatts || 0).toFixed(Number(modelData.powerDrawWatts || 0) >= 100 ? 0 : 1) + " W"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        StyledText {
                            width: parent.width
                            text: "Top GPU processes"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            visible: root.nvidiaSmiAvailable
                        }

                        StyledText {
                            width: parent.width
                            visible: root.nvidiaSmiAvailable && root.topGpuProcesses.length <= 0
                            text: "No active GPU processes reported right now."
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Repeater {
                            model: root.topGpuProcesses

                            delegate: Rectangle {
                                width: parent.width
                                height: 60
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: Theme.outline
                                clip: true

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    width: parent.width * Math.min(1, (Number(modelData.usedMemoryMiB) || 0) / Math.max(1, root.primaryGpu ? Number(root.primaryGpu.memoryTotalMiB || 0) : Number(modelData.usedMemoryMiB || 1)))
                                    height: parent.height
                                    radius: Theme.cornerRadius
                                    color: root.sectionColorFor("gpu", index)
                                    opacity: root.fillOverlayOpacity

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: root.animationDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    anchors.right: gpuProcMemoryText.left
                                    anchors.rightMargin: Theme.spacingS
                                    text: root.gpuDisplayNameForProcess(modelData)
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    id: gpuProcMemoryText

                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.spacingS
                                    text: root.formatGpuMemory(modelData.usedMemoryMiB)
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Theme.spacingS
                                    anchors.right: parent.right
                                    text: modelData.gpuName + "  |  pid " + (modelData.pid || "—") + (root.processInfoForPid(modelData.pid) ? "  |  " + (Number(root.processInfoForPid(modelData.pid).cpu) || 0).toFixed(1) + "% cpu" : "")
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // ── Disk view ────────────────────────────────────────────
                    Column {
                        visible: root.currentPopoutSection === "disk"
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
                                    opacity: root.fillOverlayOpacity

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
                                    color: Theme.widgetTextColor
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
                        visible: root.currentPopoutSection === "network"
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

                                    Item {
                                        width: parent.width
                                        height: Math.max(networkSpeedRow.implicitHeight, networkIpText.implicitHeight)

                                        Row {
                                            id: networkSpeedRow

                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
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
                                            id: networkIpText

                                            anchors.left: networkSpeedRow.right
                                            anchors.leftMargin: Theme.spacingM
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            horizontalAlignment: Text.AlignRight
                                            text: root.activeNetworkIp.length > 0 ? "IP " + root.activeNetworkIp : "IP unavailable"
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            elide: Text.ElideRight
                                        }
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
                                            color: root.networkDownloadColor()
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
                                            color: root.networkUploadColor()
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
                                            downloadColor: root.networkDownloadColor()
                                            uploadColor: root.networkUploadColor()
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

    PluginPopout {
        id: sectionPopout
        contentWidth: root.popoutWidth
        contentHeight: root.popoutHeight
        pluginContent: detailsPanelComponent
    }
}
