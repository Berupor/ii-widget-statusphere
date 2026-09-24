pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.widgets
import QtQuick
import Qt5Compat.GraphicalEffects

/** A friend's current shared photo, with a relative-time corner label, or a picture by url. No captions, no reactions. */
Rectangle {
    id: root
    property var photo: null // { account_id, path, created_at, expires_at }
    property bool thumbnail: false
    property bool cropped: false
    property string url: ""

    readonly property bool showsUrl: root.url.length > 0
    readonly property Image shownImage: root.showsUrl ? remoteImage : image
    readonly property int status: root.shownImage.status

    readonly property int minHeight: 100
    readonly property int maxHeight: 320
    // Shared regions come in every shape, so the card follows the image instead of cropping it to a fixed strip
    readonly property real naturalHeight: root.shownImage.implicitHeight > 0 ? root.width * root.shownImage.implicitHeight / root.shownImage.implicitWidth : 0

    implicitHeight: root.naturalHeight > 0 ? Math.round(Math.max(root.minHeight, Math.min(root.maxHeight, root.naturalHeight))) : root.minHeight
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Item {
        id: art
        anchors.fill: parent

        layer.enabled: root.radius > 0
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: art.width
                height: art.height
                radius: root.radius
            }
        }

        ThumbnailImage {
            id: image
            anchors.fill: parent
            sourcePath: root.photo?.path ?? ""
            thumbnailSizeName: "x-large" // The default sizes itself off sourceSize, which is 0 before the first load
            // Panoramas get letterboxed rather than gutted; anything taller is cropped to maxHeight
            fillMode: !root.cropped && root.naturalHeight > 0 && root.naturalHeight < root.minHeight ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        }

        StyledImage {
            id: remoteImage
            anchors.fill: parent
            source: root.showsUrl && width > 0 && height > 0 ? root.url : ""
            fillMode: Image.PreserveAspectCrop
        }
    }

    MaterialSymbol {
        visible: root.shownImage.status !== Image.Ready
        anchors.centerIn: parent
        iconSize: Math.round(root.height * 0.3)
        color: Appearance.colors.colSubtext
        text: root.showsUrl ? "image" : "photo_camera"
    }

    Rectangle {
        visible: root.photo !== null && !root.thumbnail
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 8
        }
        radius: Appearance.rounding.full
        // colScrim is half black, which leaves white at 3.9:1 over a bright photo
        color: Qt.rgba(0, 0, 0, 0.6)
        implicitWidth: timeLabel.implicitWidth + 12
        implicitHeight: timeLabel.implicitHeight + 6

        StyledText {
            id: timeLabel
            anchors.centerIn: parent
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: "white"
            text: root.photo ? NotificationUtils.getFriendlyNotifTimeString(Date.parse(root.photo.created_at)) : ""
        }
    }
}
