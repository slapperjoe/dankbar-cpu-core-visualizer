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
    property var animatedCoreUsage: []
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

    function syncAnimatedUsage(force) {
        let next = root.animatedCoreUsage ? root.animatedCoreUsage.slice() : [];
        const targetLength = root.rawCoreUsage.length;
        for (let i = 0; i < targetLength; i++) {
            const target = root.usageFor(i);
            const current = Number(next[i]);
            if (force || Number.isNaN(current)) {
                next[i] = target;
            } else {
                const delta = target - current;
                if (Math.abs(delta) < 0.35)
                    next[i] = target;
                else
                    next[i] = current + delta * root.smoothingFactor;
            }
        }
        next.length = targetLength;
        root.animatedCoreUsage = next;
    }

    function usageFor(index) {
        if (index < 0 || index >= root.rawCoreUsage.length)
            return 0;

        const value = Number(root.rawCoreUsage[index]);
        if (Number.isNaN(value))
            return 0;

        return Math.max(0, Math.min(100, value));
    }

    function ratioFor(index) {
        const animated = Number(root.animatedCoreUsage[index]);
        if (!Number.isNaN(animated))
            return Math.max(0, Math.min(100, animated)) / 100;

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

    function cardFillWidth(index, width) {
        return Math.max(10, Math.round(width * root.ratioFor(index)));
    }

    function verticalHeightFor(index, availableHeight) {
        const ratio = root.ratioFor(index);
        if (ratio <= 0)
            return root.minBarHeight;

        return Math.max(root.minBarHeight, Math.round(availableHeight * ratio));
    }

    function horizontalLengthFor(index, availableWidth) {
        const ratio = root.ratioFor(index);
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
        const totalUsage = Number(DgopService.cpuUsage || 0).toFixed(1);
        const totalCores = root.rawCoreUsage.length;
        const shownCores = root.displayedCoreCount;
        const hottestIndex = root.hottestCoreIndex();
        const hottestUsage = root.usageFor(hottestIndex).toFixed(0);
        let header = "CPU " + totalUsage + "%";
        if (DgopService.cpuTemperature > 0)
            header += "  |  " + Math.round(DgopService.cpuTemperature) + "C";

        if (DgopService.cpuFrequency > 0)
            header += "  |  " + Math.round(DgopService.cpuFrequency) + " MHz";

        let summary = "Hottest core: C" + hottestIndex + " " + hottestUsage + "%";
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
        return header + "\n" + summary + (lines.length > 0 ? "\n" + lines.join("\n") : "");
    }

    function shortSummaryText() {
        const totalUsage = Number(DgopService.cpuUsage || 0).toFixed(1);
        const hottestIndex = root.hottestCoreIndex();
        const hottestUsage = root.usageFor(hottestIndex).toFixed(0);
        let summary = "CPU " + totalUsage + "%";
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

    TextMetrics {
        id: overallPercentageMetrics

        font.pixelSize: root.overallTextSize()
        font.weight: Font.Medium
        text: "100%"
    }

    layerNamespacePlugin: "cpu-core-visualizer"
    Component.onCompleted: {
        DgopService.addRef(["cpu"]);
        root.syncAnimatedUsage(true);
        DgopService.updateAllStats();
    }
    Component.onDestruction: {
        closePopoutTimer.stop();
        DgopService.removeRef(["cpu"]);
    }
    onRawCoreUsageChanged: root.syncAnimatedUsage(root.animatedCoreUsage.length !== root.rawCoreUsage.length)
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

            readonly property int availableHeight: Math.max(root.widgetThickness - root.padding * 2, root.minBarHeight + 1)

            implicitWidth: root.padding * 2 + horizontalContent.implicitWidth
            implicitHeight: root.widgetThickness

            Row {
                id: horizontalContent

                anchors.centerIn: parent
                spacing: root.barGap

                Row {
                    id: horizontalBars

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.barGap

                    Repeater {
                        model: root.displayedCoreCount

                        delegate: Item {
                            width: root.barWidth
                            height: horizontalRoot.availableHeight

                            Rectangle {
                                width: parent.width
                                height: root.verticalHeightFor(index, parent.height)
                                anchors.bottom: parent.bottom
                                radius: Math.min(root.cornerRadius, width / 2)
                                color: root.colorFor(index)
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

                Item {
                    visible: root.showOverallPercentage
                    width: Math.ceil(overallPercentageMetrics.advanceWidth)
                    height: horizontalPercentageLabel.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: horizontalPercentageLabel

                        anchors.fill: parent
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        text: Number(DgopService.cpuUsage || 0).toFixed(0) + "%"
                        color: Theme.widgetTextColor
                        font.pixelSize: root.overallTextSize()
                        font.weight: Font.Medium
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

            readonly property int availableWidth: Math.max(root.widgetThickness - root.padding * 2, root.minBarHeight + 1)
            readonly property bool fillFromLeft: root.axis?.edge === "left"

            implicitWidth: root.widgetThickness
            implicitHeight: root.padding * 2 + verticalContent.implicitHeight

            Column {
                id: verticalContent

                anchors.centerIn: parent
                spacing: root.barGap

                Column {
                    id: verticalBars

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.barGap

                    Repeater {
                        model: root.displayedCoreCount

                        delegate: Item {
                            width: verticalRoot.availableWidth
                            height: root.barWidth

                            Rectangle {
                                height: parent.height
                                width: root.horizontalLengthFor(index, parent.width)
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: verticalRoot.fillFromLeft ? parent.left : undefined
                                anchors.right: verticalRoot.fillFromLeft ? undefined : parent.right
                                radius: Math.min(root.cornerRadius, height / 2)
                                color: root.colorFor(index)
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

                Item {
                    visible: root.showOverallPercentage
                    width: Math.ceil(overallPercentageMetrics.advanceWidth)
                    height: verticalPercentageLabel.implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        id: verticalPercentageLabel

                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Number(DgopService.cpuUsage || 0).toFixed(0) + "%"
                        color: Theme.widgetTextColor
                        font.pixelSize: root.overallTextSize()
                        font.weight: Font.Medium
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
                        text: "Samples refresh every " + root.probeInterval + "ms from the plugin timer via DgopService. Animation smoothing runs continuously."
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
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
