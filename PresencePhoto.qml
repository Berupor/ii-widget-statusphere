pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.widgets
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell.Io

/** A friend's current shared photo, with a relative-time corner label, or a picture by url. No captions, no reactions. */
Rectangle {
    id: root
    property var photo: null // { account_id, path, created_at, expires_at }
    property bool thumbnail: false
    property bool cropped: false
    property string url: ""

    readonly property bool animating: root.visible && root.Window.visibility !== Window.Hidden
    readonly property bool showsUrl: root.url.length > 0
    readonly property var shownImage: root.showsUrl ? remoteImage.item : image
    readonly property int status: root.shownImage?.status ?? Image.Null

    property bool remoteIsGif: false

    function sniffRemote(): void {
        if (remoteGifSniff.running || root.url.length === 0)
            return;
        remoteGifSniff.sniffedUrl = root.url;
        remoteGifSniff.running = true;
    }

    onUrlChanged: {
        root.remoteIsGif = false;
        root.sniffRemote();
    }

    Process {
        id: remoteGifSniff
        property string sniffedUrl
        command: ["curl", "-4", "-sSL", "-r", "0-3", remoteGifSniff.sniffedUrl]
        stdout: StdioCollector {
            onStreamFinished: if (remoteGifSniff.sniffedUrl === root.url)
                root.remoteIsGif = text === "GIF8"
        }
        onRunningChanged: if (!remoteGifSniff.running && remoteGifSniff.sniffedUrl !== root.url)
            root.sniffRemote()
    }

    readonly property int minHeight: 100
    readonly property int maxHeight: 320
    // Shared regions come in every shape, so the card follows the image instead of cropping it to a fixed strip
    readonly property real naturalHeight: (root.shownImage?.implicitHeight ?? 0) > 0 ? root.width * root.shownImage.implicitHeight / root.shownImage.implicitWidth : 0

    readonly property real settledHeight: root.naturalHeight > 0 ? Math.round(Math.max(root.minHeight, Math.min(root.maxHeight, root.naturalHeight))) : root.minHeight
    // AnimatedImage re-decodes on every sourceSize change, so the image skips the height ease
    readonly property real imageHeight: root.cropped ? root.height : root.settledHeight

    implicitHeight: root.settledHeight
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

        Loader {
            id: remoteImage
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: root.imageHeight
            active: root.showsUrl
            sourceComponent: root.remoteIsGif ? animatedRemote : staticRemote
        }

        Component {
            id: staticRemote
            StyledImage {
                source: width > 0 && height > 0 ? root.url : ""
                fillMode: Image.PreserveAspectCrop
            }
        }

        Component {
            id: animatedRemote
            AnimatedImage {
                source: width > 0 && height > 0 ? root.url : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
                sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
                playing: root.animating
            }
        }

        LocalPicture {
            id: image
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: root.imageHeight
            sourcePath: root.photo?.path ?? ""
            playing: root.animating
            thumbnailSizeName: "x-large" // The default sizes itself off sourceSize, which is 0 before the first load
            // Panoramas get letterboxed rather than gutted; anything taller is cropped to maxHeight
            fillMode: !root.cropped && root.naturalHeight > 0 && root.naturalHeight < root.minHeight ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        }
    }

    MaterialSymbol {
        visible: (root.shownImage?.status ?? Image.Null) !== Image.Ready
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
