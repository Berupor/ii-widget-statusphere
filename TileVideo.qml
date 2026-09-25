import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property var device: form.card.videoDevice
    readonly property bool hasPosition: (form.device?.video_length ?? 0) > 0
    readonly property real progress: form.hasPosition ? (form.device.video_position ?? 0) / form.device.video_length : 0
    readonly property real iconSize: Math.max(Appearance.font.pixelSize.large, Math.round(Math.min(form.height, 64) * 0.45))

    RowLayout {
        anchors.fill: parent
        spacing: 10

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: form.device?.video_status === "paused" ? "pause_circle" : "smart_display"
            iconSize: form.iconSize
            color: form.card.contentColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: form.device?.video_title ?? "-"
                color: form.card.contentColor
                font.pixelSize: Appearance.font.pixelSize.normal
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: form.device?.video_channel ?? ""
                color: form.card.mutedContentColor
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            WaveBar {
                Layout.fillWidth: true
                visible: form.hasPosition
                color: form.card.contentColor
                to: 1
                value: form.progress
                wavy: false
            }
        }
    }
}
