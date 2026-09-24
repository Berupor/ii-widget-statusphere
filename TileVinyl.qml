import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: form
    required property var card
    readonly property var device: form.card.musicDevice
    readonly property bool hasPosition: (form.device?.spotify_length ?? 0) > 0
    readonly property real progress: form.hasPosition ? (form.device.spotify_position ?? 0) / form.device.spotify_length : 0
    readonly property int turnDurationMs: 9000

    CircularProgress {
        visible: form.hasPosition
        anchors.centerIn: parent
        implicitSize: Math.round(Math.min(form.width, form.height))
        lineWidth: Math.max(3, implicitSize * 0.06)
        value: form.progress
        colPrimary: form.card.contentColor
        colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.75)
    }

    Item {
        id: cover
        anchors.centerIn: parent
        width: Math.round(Math.min(form.width, form.height) * 0.68)
        height: cover.width

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: cover.width
                height: cover.height
                radius: cover.width / 2
            }
        }

        PresenceArt {
            anchors.fill: parent
            source: form.device?.spotify_art_url ?? ""
        }

        RotationAnimation on rotation {
            running: form.device?.spotify_status === "playing"
            paused: running && !form.card.animating
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: form.turnDurationMs
        }
    }
}
