pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell.Io

/** Rounded album art with a music note fallback. */
Rectangle {
    id: root
    required property string source
    property string fallbackIcon: "music_note"

    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer1

    property string cacheFilePath: root.source.length > 0 ? `${Directories.coverArt}/${Qt.md5(root.source)}` : ""
    property bool downloaded: false

    onCacheFilePathChanged: {
        root.downloaded = false;
        if (root.cacheFilePath.length === 0)
            return;
        artDownloader.targetUrl = root.source;
        artDownloader.filePath = root.cacheFilePath;
        artDownloader.running = true;
    }

    Process {
        id: artDownloader
        property string targetUrl
        property string filePath
        command: ["bash", "-c", `[ -f ${filePath} ] || curl -4 -sSL '${targetUrl}' -o '${filePath}'`]
        onExited: root.downloaded = true
    }

    StyledImage {
        id: image
        anchors.fill: parent
        source: root.downloaded ? Qt.resolvedUrl(root.cacheFilePath) : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.ceil(root.width * Screen.devicePixelRatio)
        sourceSize.height: Math.ceil(root.height * Screen.devicePixelRatio)
        cache: true

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: image.width
                height: image.height
                radius: root.radius
            }
        }
    }

    MaterialSymbol {
        visible: image.status !== Image.Ready
        anchors.centerIn: parent
        iconSize: Math.round(root.height * 0.4)
        color: Appearance.colors.colSubtext
        text: root.fallbackIcon
    }
}
