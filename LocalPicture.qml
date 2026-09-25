pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell.Io

/** A local file, thumbnailed like any picture; a GIF bypasses the static thumbnail and plays. */
Item {
    id: root
    required property string sourcePath
    property int fillMode: Image.PreserveAspectCrop
    property string fit: "cover"
    property string thumbnailSizeName: ""

    readonly property int effectiveFillMode: root.fit === "stretch" ? Image.Stretch : root.fit === "blur" ? Image.PreserveAspectFit : root.fillMode

    property bool playing: true
    readonly property int status: image.item?.status ?? Image.Null
    implicitWidth: image.item?.implicitWidth ?? 0
    implicitHeight: image.item?.implicitHeight ?? 0

    property bool isGif: false

    function sniff(): void {
        if (gifSniffer.running || root.sourcePath.length === 0)
            return;
        gifSniffer.sniffedPath = root.sourcePath;
        gifSniffer.running = true;
    }

    onSourcePathChanged: {
        root.isGif = false;
        root.sniff();
    }

    Process {
        id: gifSniffer
        property string sniffedPath
        command: ["head", "-c4", FileUtils.trimFileProtocol(gifSniffer.sniffedPath)]
        stdout: StdioCollector {
            onStreamFinished: if (gifSniffer.sniffedPath === root.sourcePath)
                root.isGif = text === "GIF8"
        }
        onRunningChanged: if (!gifSniffer.running && gifSniffer.sniffedPath !== root.sourcePath)
            root.sniff()
    }

    Item {
        id: blurBackdrop
        objectName: "pictureFitBackdrop"
        // layer.enabled hides its own source item to show the blurred copy in its place -
        // binding that item's own visible would fight that, so the fit switch lives here.
        visible: root.fit === "blur"
        anchors.fill: parent

        Image {
            objectName: "pictureFitBackdrop"
            anchors.fill: parent
            asynchronous: true
            cache: false
            source: root.fit === "blur" && root.sourcePath.length > 0 ? Qt.resolvedUrl(root.sourcePath) : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 64
            sourceSize.height: 64

            layer.enabled: true
            layer.effect: FastBlur {
                radius: 48
            }
        }
    }

    Loader {
        id: image
        anchors.fill: parent
        sourceComponent: root.isGif ? animatedPicture : thumbnail

        layer.enabled: root.fit === "blur"
        layer.effect: OpacityMask {
            maskSource: PictureFitFeatherMask {
                objectName: "pictureFitFeather"
                width: image.width
                height: image.height
                paintedWidth: image.item?.paintedWidth ?? image.width
                paintedHeight: image.item?.paintedHeight ?? image.height
            }
        }
    }

    Component {
        id: thumbnail
        ThumbnailImage {
            sourcePath: root.sourcePath
            fillMode: root.effectiveFillMode
            thumbnailSizeName: root.thumbnailSizeName.length > 0 ? root.thumbnailSizeName : Images.thumbnailSizeNameForDimensions(Math.ceil(width * Screen.devicePixelRatio), Math.ceil(height * Screen.devicePixelRatio))
        }
    }

    Component {
        id: animatedPicture
        AnimatedImage {
            asynchronous: true
            source: root.sourcePath.length > 0 ? Qt.resolvedUrl(root.sourcePath) : ""
            fillMode: root.effectiveFillMode
            // QMovie's scaledSize has no partial-axis aspect-preserving mode the way
            // Image.sourceSize does - leaving both unset decodes at native size so cover/blur
            // keep proportions, and stretch is the only mode that forces them.
            sourceSize.width: root.fit === "stretch" ? Math.ceil(root.width * Screen.devicePixelRatio) : -1
            sourceSize.height: root.fit === "stretch" ? Math.ceil(root.height * Screen.devicePixelRatio) : -1
            playing: root.playing
        }
    }
}
