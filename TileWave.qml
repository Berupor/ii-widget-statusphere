import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property var device: form.card.musicDevice
    readonly property bool hasPosition: (form.device?.spotify_length ?? 0) > 0
    readonly property real progress: form.hasPosition ? (form.device.spotify_position ?? 0) / form.device.spotify_length : 0

    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PresenceArt {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                source: form.device?.spotify_art_url ?? ""
            }
            ShrinkThenWrapText {
                Layout.fillWidth: true
                largestSize: Appearance.font.pixelSize.smaller
                maxLines: 1
                text: Statusphere.trackFor(form.device)
                color: form.card.contentColor
            }
        }

        WaveBar {
            Layout.fillWidth: true
            visible: form.hasPosition
            color: form.card.contentColor
            to: 1
            value: form.progress
            animateWave: form.card.animating && form.device?.spotify_status === "playing"
        }
    }
}
