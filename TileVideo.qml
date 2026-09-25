import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property var device: form.card.videoDevice
    readonly property real length: form.device?.video_length ?? 0
    readonly property bool hasPosition: form.length > 0
    readonly property real progress: form.hasPosition ? (form.device.video_position ?? 0) / form.length : 0
    readonly property real artHeight: Math.min(form.height, 64)
    readonly property real artWidth: Math.min(form.artHeight * 16 / 9, form.width * 0.3)
    readonly property real artTintShare: 0.6
    readonly property real minArtHeightForLength: 40
    readonly property color textColor: Appearance.colors.colOnLayer2

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: form.artWidth
            implicitHeight: form.artHeight
            radius: Appearance.rounding.small
            color: ColorUtils.mix(form.card.tint, Appearance.colors.colLayer2, form.artTintShare)

            MaterialSymbol {
                anchors.centerIn: parent
                text: form.device?.video_status === "paused" ? "pause" : "play_arrow"
                fill: 1
                iconSize: Math.round(form.artHeight * 0.38)
                color: form.card.contentColor
            }
            Rectangle {
                visible: form.hasPosition && form.artHeight >= form.minArtHeightForLength
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                implicitWidth: lengthText.implicitWidth + 8
                implicitHeight: lengthText.implicitHeight + 2
                radius: 4
                color: ColorUtils.transparentize("black", 0.6)

                StyledText {
                    id: lengthText
                    anchors.centerIn: parent
                    text: StringUtils.friendlyTimeForSeconds(form.length)
                    color: form.card.contentColor
                    font.pixelSize: Appearance.font.pixelSize.smallest
                }
            }
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
                color: form.textColor
                font.pixelSize: Appearance.font.pixelSize.normal
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: form.device?.video_channel ?? ""
                color: ColorUtils.transparentize(form.textColor, 0.35)
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            WaveBar {
                Layout.fillWidth: true
                visible: form.hasPosition
                color: Appearance.colors.colPrimary
                to: 1
                value: form.progress
                wavy: false
            }
        }
    }
}
