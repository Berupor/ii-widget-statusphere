import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property var device: form.card.alarmDevice
    readonly property real triggerMs: (form.device?.alarm_at ?? 0) * 1000
    readonly property bool due: form.device !== null && form.triggerMs > Date.now()
    readonly property real captionSize: Math.max(Appearance.font.pixelSize.smallest, Math.round(form.height * 0.15))

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: 2

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            spacing: 4

            MaterialSymbol {
                text: "alarm"
                iconSize: form.captionSize
                color: form.card.mutedContentColor
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: Translation.tr("Alarm")
                color: form.card.mutedContentColor
                font.pixelSize: form.captionSize
            }
        }
        ShrinkThenWrapText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.4))
            maxLines: 1
            text: form.due ? Qt.formatTime(new Date(form.triggerMs), "HH:mm") : "-"
            color: form.card.contentColor
        }
    }
}
