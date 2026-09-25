pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell.Io

/** Rounded album art with a music note fallback; an animated cover plays as a GIF. */
Rectangle {
    id: root
    required property string source
    property list<string> fallbacks: []
    property string fallbackIcon: "music_note"
    property int fillMode: Image.PreserveAspectCrop
    property string fit: "cover"
    property int horizontalAlignment: Image.AlignHCenter
    property int verticalAlignment: Image.AlignVCenter

    readonly property int effectiveFillMode: root.fit === "stretch" ? Image.Stretch : root.fit === "blur" ? Image.PreserveAspectFit : root.fillMode

    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer1

    property bool playing: true
    property bool settleGif: false
    property int settleSeconds: 4
    readonly property int status: image.item?.status ?? Image.Null
    readonly property real heightPerWidth: (image.item?.implicitWidth ?? 0) > 0 ? image.item.implicitHeight / image.item.implicitWidth : -1

    property string cacheFilePath: root.source.length > 0 ? `${Directories.coverArt}/${Qt.md5(root.source)}` : ""
    property bool downloaded: false
    property bool isGif: false

    readonly property string resolvedSource: root.downloaded ? Qt.resolvedUrl(root.cacheFilePath) : ""
    readonly property int pixelWidth: Math.ceil(root.width * Screen.devicePixelRatio)
    readonly property int pixelHeight: Math.ceil(root.height * Screen.devicePixelRatio)

    function fetch(): void {
        if (artDownloader.running || root.cacheFilePath.length === 0)
            return;
        artDownloader.filePath = root.cacheFilePath;
        artDownloader.urls = [root.source, ...root.fallbacks];
        artDownloader.running = true;
    }

    onCacheFilePathChanged: {
        root.downloaded = false;
        root.isGif = false;
        root.fetch();
    }

    onFallbacksChanged: root.fetch()

    Process {
        id: artDownloader
        property string filePath
        property list<string> urls
        readonly property string script: `
target="$1"; shift
if [ ! -f "$target" ]; then
    for url in "$@"; do
        tmp="$target.$$"
        if curl -4 -fsSL "$url" -o "$tmp"; then
            mv "$tmp" "$target"
            break
        fi
        rm -f "$tmp"
    done
fi
head -c4 "$target" 2>/dev/null
`
        command: ["bash", "-c", artDownloader.script, "_", artDownloader.filePath, ...artDownloader.urls]
        stdout: StdioCollector {
            onStreamFinished: if (artDownloader.filePath === root.cacheFilePath)
                root.isGif = text === "GIF8"
        }
        onRunningChanged: {
            if (artDownloader.running)
                return;
            if (artDownloader.filePath === root.cacheFilePath)
                root.downloaded = true;
            else
                root.fetch();
        }
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
            source: root.fit === "blur" ? root.resolvedSource : ""
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
        sourceComponent: root.isGif ? animatedArt : staticArt

        layer.enabled: root.radius > 0 || root.fit === "blur"
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: image.width
                height: image.height
                radius: root.radius

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
        }
    }

    Component {
        id: staticArt
        StyledImage {
            source: root.resolvedSource
            fillMode: root.effectiveFillMode
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            sourceSize.width: root.pixelWidth
            sourceSize.height: root.pixelHeight
            cache: true
        }
    }

    Component {
        id: animatedArt
        AnimatedImage {
            id: gif
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
            source: root.resolvedSource
            fillMode: root.effectiveFillMode
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            // QMovie scales to sourceSize exactly, ignoring aspect, and takes 0x0 as a real size; -1 decodes at native size.
            sourceSize.width: root.fit === "stretch" ? root.pixelWidth : -1
            sourceSize.height: root.fit === "stretch" ? root.pixelHeight : -1
            cache: true
            playing: root.playing

            property bool stopAtFirstFrame: false

            function restartSettle(): void {
                gif.stopAtFirstFrame = false;
                gif.paused = false;
                settleTimer.restart();
            }

            Component.onCompleted: if (root.settleGif && gif.playing)
                gif.restartSettle()

            onPlayingChanged: {
                if (!root.settleGif)
                    return;
                if (gif.playing)
                    gif.restartSettle();
                else
                    settleTimer.stop();
            }

            onCurrentFrameChanged: if (gif.stopAtFirstFrame && gif.currentFrame === 0)
                gif.paused = true

            Timer {
                id: settleTimer
                interval: root.settleSeconds * 1000
                onTriggered: gif.stopAtFirstFrame = gif.frameCount > 1
            }
        }
    }

    MaterialSymbol {
        visible: root.status !== Image.Ready && root.fallbackIcon.length > 0
        anchors.centerIn: parent
        iconSize: Math.round(root.height * 0.4)
        color: Appearance.colors.colSubtext
        text: root.fallbackIcon
    }
}
