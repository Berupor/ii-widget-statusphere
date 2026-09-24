pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Window
import Quickshell.Io

/** A local file, thumbnailed like any picture; a GIF bypasses the static thumbnail and plays. */
Item {
    id: root
    required property string sourcePath
    property int fillMode: Image.PreserveAspectCrop
    property string thumbnailSizeName: ""

    property bool playing: true
    readonly property int status: image.item?.status ?? Image.Null
    implicitWidth: image.item?.implicitWidth ?? 0
    implicitHeight: image.item?.implicitHeight ?? 0

    property bool isGif: false

    onSourcePathChanged: {
        root.isGif = false;
        if (root.sourcePath.length === 0)
            return;
        gifSniffer.running = true;
    }

    Process {
        id: gifSniffer
        command: ["head", "-c4", FileUtils.trimFileProtocol(root.sourcePath)]
        stdout: StdioCollector {
            onStreamFinished: root.isGif = text === "GIF8"
        }
    }

    Loader {
        id: image
        anchors.fill: parent
        sourceComponent: root.isGif ? animatedPicture : thumbnail
    }

    Component {
        id: thumbnail
        ThumbnailImage {
            sourcePath: root.sourcePath
            fillMode: root.fillMode
            thumbnailSizeName: root.thumbnailSizeName.length > 0 ? root.thumbnailSizeName : Images.thumbnailSizeNameForDimensions(Math.ceil(width * Screen.devicePixelRatio), Math.ceil(height * Screen.devicePixelRatio))
        }
    }

    Component {
        id: animatedPicture
        AnimatedImage {
            asynchronous: true
            source: root.sourcePath.length > 0 ? Qt.resolvedUrl(root.sourcePath) : ""
            fillMode: root.fillMode
            sourceSize.width: Math.ceil(root.width * Screen.devicePixelRatio)
            sourceSize.height: Math.ceil(root.height * Screen.devicePixelRatio)
            playing: root.playing
        }
    }
}
