import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins

// Wide digital clock + date desktop widget.
// Time sits large on the left, the date stacks on the right.
DesktopPluginComponent {
    id: root

    minWidth: 280
    minHeight: 30

    property bool showSeconds: pluginData.showSeconds ?? true
    property bool showDate: pluginData.showDate ?? true
    property bool showAmPm: pluginData.showAmPm ?? false
    property real backgroundOpacity: (pluginData.backgroundOpacity ?? 55) / 100

    SystemClock {
        id: systemClock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        opacity: root.backgroundOpacity
    }

    // Time and date share one centered row. Text is sized by a FIXED formula
    // (not scaled down with widget height), so shortening the widget only
    // trims the empty padding — the digits stay the same size.
    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingL

        Text {
            id: timeText
            text: {
                const h = systemClock.date?.getHours() ?? 0;
                const m = systemClock.date?.getMinutes() ?? 0;
                const s = systemClock.date?.getSeconds() ?? 0;

                let hours = h;
                let suffix = "";
                const wantAmPm = root.showAmPm;
                const is12h = !SettingsData.use24HourClock || root.showAmPm;
                if (is12h) {
                    hours = h % 12 === 0 ? 12 : h % 12;
                    if (wantAmPm)
                        suffix = h >= 12 ? " PM" : " AM";
                }
                const hh = String(hours).padStart(2, "0");
                const mm = String(m).padStart(2, "0");
                const ss = String(s).padStart(2, "0");
                return (root.showSeconds ? hh + ":" + mm + ":" + ss : hh + ":" + mm) + suffix;
            }
            // Fixed time font size — independent of widget height so the digits
            // stay identical no matter how the box is resized.
            font.pixelSize: 34
            font.weight: Font.Bold
            font.family: "monospace"
            color: Theme.primary
            elide: Text.ElideNone
            verticalAlignment: Text.AlignVCenter
            lineHeight: 1.0
        }

        // Date — day name over full date, right aligned.
        Column {
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showDate
            width: Math.max(dayText.implicitWidth, dateText.implicitWidth)

            Text {
                id: dayText
                anchors.right: parent.right
                text: systemClock.date?.toLocaleDateString(I18n.locale(), "dddd") ?? ""
                font.pixelSize: 15
                font.weight: Font.Medium
                color: Theme.surfaceText
                lineHeight: 1.0
            }

            Text {
                id: dateText
                anchors.right: parent.right
                text: systemClock.date?.toLocaleDateString(I18n.locale(), "d MMMM yyyy") ?? ""
                font.pixelSize: 12
                color: Theme.surfaceVariantText
                lineHeight: 1.0
            }
        }
    }
}
