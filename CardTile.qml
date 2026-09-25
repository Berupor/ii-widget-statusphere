pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts

Item {
    id: root
    required property var account
    required property var tile
    // A pack preview squeezes a surface into ~20px cells with no room for text -
    // it shows only the tile's silhouette, colour and any cover/banner/photo art.
    property bool thumbnail: false

    readonly property var type: CardLayouts.typeOf(root.tile)
    readonly property var form: CardLayouts.formOf(root.tile)
    readonly property bool fullBleed: root.form.fullBleed === true
    readonly property bool animating: root.visible && root.Window.visibility !== Window.Hidden

    readonly property var device: Statusphere.deviceForTile(root.account, root.tile)
    readonly property string liveBackground: root.tile.background?.kind === "live" ? (root.tile.background?.value ?? "") : ""
    readonly property var musicDevice: root.type?.reads === "music" || root.liveBackground === "music" ? Statusphere.musicDevices(root.account)[0] ?? null : null
    readonly property var gameDevice: root.type?.reads === "game" || root.liveBackground === "game" ? Statusphere.gameDevices(root.account)[0] ?? null : null
    readonly property bool pictureFailed: root.type?.art === "picture" && photoArt.item?.status === Image.Error
    readonly property bool hasData: Statusphere.tileHasData(root.account, root.tile) && !root.pictureFailed
    readonly property bool dimmed: !root.hasData && root.tile.onMissing === "dim"
    readonly property real dimmedOpacity: 0.45
    opacity: root.dimmed ? root.dimmedOpacity : 1

    readonly property var field: root.type?.needsField ? Statusphere.fieldFor(root.device, root.tile.field) : null
    readonly property real percent: root.field?.percent ?? 0
    readonly property string valueText: root.field?.value ?? "-"
    readonly property string labelText: root.field?.label ?? Statusphere.labelForKey(root.tile.field)
    readonly property string notedLabelText: root.field?.note ? `${root.labelText} · ${root.field.note}` : root.labelText
    readonly property string shownValueText: root.hasData ? root.withSymbolsAttached(root.valueText) : (root.hasArt ? "" : "-")

    readonly property var symbolCodeRanges: [[0x21, 0x2F], [0x3A, 0x40], [0x5B, 0x60], [0x7B, 0x7E], [0x2000, 0x2BFF], [0xFE00, 0xFE0F], [0x1F000, 0x1FAFF]]

    function isSymbol(token: string): bool {
        return [...token].every(ch => root.symbolCodeRanges.some(([from, to]) => ch.codePointAt(0) >= from && ch.codePointAt(0) <= to));
    }

    function withSymbolsAttached(text: string): string {
        const nbsp = "\u00A0";
        return text.replace(/^(\S+) +(?=\S)/, (whole, first) => root.isSymbol(first) ? first + nbsp : whole).replace(/(\S) +(\S+)$/, (whole, before, last) => root.isSymbol(last) ? before + nbsp + last : whole);
    }

    readonly property var colorKeys: CardLayouts.colorKeysOf(root.tile.color)
    readonly property color tint: Appearance.colors[root.colorKeys[0]]
    readonly property color contentColor: root.backgroundSource.length > 0 ? "white" : Appearance.colors[root.colorKeys[1]]
    readonly property color mutedContentColor: ColorUtils.transparentize(root.contentColor, 0.35)

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    readonly property string resolvedShape: CardLayouts.resolvedShape(root.tile, root.valueText)
    readonly property int shapeEnum: MaterialShape.Shape[root.resolvedShape] ?? MaterialShape.Shape.Circle
    readonly property bool sineCookieShape: root.resolvedShape === "SineCookie"

    readonly property bool backgroundIsLocal: root.liveBackground === "photo"
    readonly property string backgroundSource: {
        const bg = root.tile.background;
        if (root.fullBleed || !bg)
            return "";
        if (bg.kind === "url")
            return bg.value ?? "";
        if (root.liveBackground === "music")
            return root.musicDevice?.spotify_art_url ?? "";
        if (root.liveBackground === "game")
            return root.gameDevice?.game_hero_url || root.gameDevice?.game_header_url || "";
        if (root.liveBackground === "photo")
            return Statusphere.currentPhotoFor(root.account)?.path ?? "";
        return "";
    }

    readonly property bool shaped: !root.fullBleed && root.resolvedShape !== "default"
    readonly property string fit: CardLayouts.fitOf(root.tile)

    Rectangle {
        id: silhouette
        visible: !root.fullBleed && !root.shaped
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: root.backgroundSource ? Appearance.colors.colLayer2 : root.tint
    }

    Loader {
        active: root.shaped
        anchors.centerIn: parent
        sourceComponent: root.sineCookieShape ? sineCookieSilhouette : materialShapeSilhouette
    }

    Component {
        id: materialShapeSilhouette
        MaterialShape {
            implicitSize: Math.min(root.width, root.height)
            shape: root.shapeEnum
            color: root.tint
        }
    }

    Component {
        id: sineCookieSilhouette
        SineCookie {
            implicitSize: Math.min(root.width, root.height)
            color: root.tint
        }
    }

    readonly property bool showsPhotoArt: (root.type?.art ?? "") !== ""
    readonly property real artScrimOpacity: 0.6
    readonly property bool hasArt: root.showsPhotoArt || root.backgroundSource.length > 0
    readonly property bool showsSky: root.form.sky === true

    Loader {
        id: artMask
        objectName: "tileArtMask"
        anchors.fill: parent
        visible: false
        active: root.hasArt || root.showsSky
        sourceComponent: root.resolvedShape === "default" ? roundedArtMask : (root.sineCookieShape ? sineCookieArtMask : shapedArtMask)
    }

    Component {
        id: roundedArtMask
        Rectangle {
            radius: silhouette.radius
        }
    }

    Component {
        id: shapedArtMask
        // Stretched over the whole tile, which is fine because resolvedShape is non-default only on a square one
        MaterialShape {
            shape: root.shapeEnum
            color: "white"
        }
    }

    Component {
        id: sineCookieArtMask
        SineCookie {
            implicitSize: Math.min(root.width, root.height)
            color: "white"
        }
    }

    Item {
        id: art
        objectName: "tileArt"
        visible: root.hasArt
        anchors.fill: parent

        layer.enabled: root.hasArt
        layer.effect: OpacityMask {
            maskSource: artMask
        }

        Loader {
            active: root.backgroundIsLocal
            anchors.fill: parent
            sourceComponent: LocalPicture {
                sourcePath: root.backgroundSource
                fillMode: Image.PreserveAspectCrop
                fit: root.fit
                playing: root.animating
            }
        }

        Loader {
            active: root.backgroundSource.length > 0 && !root.backgroundIsLocal
            anchors.fill: parent
            sourceComponent: PresenceArt {
                radius: 0
                source: root.backgroundSource
                fallbackIcon: root.liveBackground === "music" ? "music_note" : root.liveBackground === "game" ? "sports_esports" : "image"
                playing: root.animating
                fit: root.fit
                settleGif: Statusphere.opt("pauseGifs") && root.tile.background?.kind === "url"
                settleSeconds: Statusphere.opt("gifPauseSeconds")
            }
        }

        Loader {
            id: photoArt
            active: root.showsPhotoArt
            anchors.fill: parent
            sourceComponent: PresencePhoto {
                radius: 0
                photo: root.type?.art === "photo" ? Statusphere.currentPhotoFor(root.account) : null
                url: root.type?.art === "picture" ? CardLayouts.pictureUrlOf(root.tile) : ""
                thumbnail: root.thumbnail
                cropped: true
                fit: root.fit
                settleGif: Statusphere.opt("pauseGifs")
                settleSeconds: Statusphere.opt("gifPauseSeconds")
            }
        }

        Rectangle {
            id: textScrim
            visible: root.backgroundSource.length > 0
            anchors.fill: parent
            color: Appearance.colors.colScrim
            opacity: root.artScrimOpacity
        }
    }

    Loader {
        id: weatherSky
        objectName: "tileWeatherSky"
        anchors.fill: parent
        active: root.showsSky
        visible: active

        layer.enabled: root.showsSky
        layer.effect: OpacityMask {
            maskSource: artMask
        }

        sourceComponent: WeatherSky {
            value: root.valueText
            tint: root.tint
            contentColor: root.contentColor
            running: root.animating
        }
    }

    // A fixed 12px eats most of a thumbnail-scale tile (a pack preview squeezes a
    // surface into ~20px cells) and leaves nothing for text to fit in - scale it
    // with the tile instead.
    readonly property real contentInset: root.fullBleed ? 0 : Math.max(4, Math.round(Math.min(root.width, root.height) * 0.1))

    Item {
        id: content
        x: root.contentInset
        y: root.contentInset
        width: Math.max(0, root.width - 2 * root.contentInset)
        height: Math.max(0, root.height - 2 * root.contentInset)
        clip: true

        Loader {
            id: formLoader
            objectName: "tileForm"
            anchors.fill: parent
            readonly property string file: root.thumbnail && !root.fullBleed ? "" : root.form.file

            function load(): void {
                formLoader.setSource(formLoader.file ? Qt.resolvedUrl(formLoader.file) : "", {
                    "card": root
                });
            }

            onFileChanged: formLoader.load()
            Component.onCompleted: formLoader.load()
        }
    }
}
