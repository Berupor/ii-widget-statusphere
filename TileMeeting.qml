import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property var device: form.card.meetingDevice
    readonly property real untilMs: (form.device?.meeting_until ?? 0) * 1000
    readonly property bool due: form.device !== null && form.untilMs > Date.now()
    readonly property real iconSize: Math.max(Appearance.font.pixelSize.large, Math.round(Math.min(form.width, form.height) * 0.4))

    RowLayout {
        anchors.fill: parent
        spacing: 8
        visible: form.due

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: "event_busy"
            iconSize: form.iconSize
            color: form.card.contentColor
        }
        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: form.due ? Translation.tr("Busy until %1").arg(Qt.formatTime(new Date(form.untilMs), "HH:mm")) : ""
            color: form.card.contentColor
            font.pixelSize: Appearance.font.pixelSize.normal
        }
    }
}
