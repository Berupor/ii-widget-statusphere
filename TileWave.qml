import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property var device: form.card.musicDevice
    readonly property bool hasPosition: (form.device?.spotify_length ?? 0) > 0
    readonly property real progress: form.hasPosition ? (form.device.spotify_position ?? 0) / form.device.spotify_length : 0
    readonly property bool hasTrack: !!form.device?.spotify_status && !!form.device?.spotify_track
    readonly property string titleText: form.hasTrack ? form.device.spotify_track : Statusphere.trackFor(form.device)
    readonly property string artistText: form.hasTrack ? (form.device.spotify_artist ?? "") : ""
    readonly property real artSide: Math.min(form.height, form.width * 0.4)

    RowLayout {
        anchors.fill: parent
        spacing: 10

        PresenceArt {
            Layout.preferredWidth: form.artSide
            Layout.preferredHeight: form.artSide
            Layout.alignment: Qt.AlignVCenter
            source: form.device?.spotify_art_url ?? ""
            playing: form.card.animating
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: form.titleText
                color: form.card.contentColor
                font.pixelSize: Appearance.font.pixelSize.normal
            }
            StyledText {
                Layout.fillWidth: true
                visible: form.artistText !== ""
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: form.artistText
                color: form.card.mutedContentColor
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            WaveBar {
                Layout.fillWidth: true
                visible: form.hasPosition
                color: form.card.contentColor
                to: 1
                value: form.progress
                wavy: true
                animateWave: form.hasPosition && form.card.animating && form.device?.spotify_status === "playing"
            }
        }
    }
}
