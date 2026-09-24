pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/** One grid cell: a silhouette plus a scalar form, or a composite source reused as-is. */
Item {
    id: root
    required property var account
    required property var tile
    // A preset preview packs a whole card into ~35px cells with no room for text -
    // it shows only the tile's silhouette, colour and any cover/banner/photo art.
    property bool thumbnail: false

    readonly property var device: Statusphere.deviceForTile(root.account, root.tile)
    readonly property bool hasData: Statusphere.tileHasData(root.account, root.tile)
    readonly property bool dimmed: !root.hasData && root.tile.onMissing === "dim"
    opacity: root.dimmed ? 0.45 : 1

    readonly property var field: root.tile.type === "scalar" ? Statusphere.fieldFor(root.device, root.tile.field) : null
    readonly property real percent: root.field?.percent ?? 0
    readonly property string valueText: root.field?.value ?? "-"
    readonly property string labelText: root.field?.label ?? Statusphere.labelForKey(root.tile.field)

    function roleColor(role: string): color {
        switch (role) {
        case "primary":
            return Appearance.colors.colPrimary;
        case "secondary":
            return Appearance.colors.colSecondary;
        case "tertiary":
            return Appearance.colors.colTertiary;
        case "error":
            return Appearance.colors.colError;
        case "primaryContainer":
            return Appearance.colors.colPrimaryContainer;
        case "secondaryContainer":
            return Appearance.colors.colSecondaryContainer;
        case "tertiaryContainer":
            return Appearance.colors.colTertiaryContainer;
        case "errorContainer":
            return Appearance.colors.colErrorContainer;
        default:
            return Appearance.colors.colLayer2;
        }
    }

    function contentRoleColor(role: string): color {
        switch (role) {
        case "primary":
            return Appearance.colors.colOnPrimary;
        case "secondary":
            return Appearance.colors.colOnSecondary;
        case "tertiary":
            return Appearance.colors.colOnTertiary;
        case "error":
            return Appearance.colors.colOnError;
        case "primaryContainer":
            return Appearance.colors.colOnPrimaryContainer;
        case "secondaryContainer":
            return Appearance.colors.colOnSecondaryContainer;
        case "tertiaryContainer":
            return Appearance.colors.colOnTertiaryContainer;
        case "errorContainer":
            return Appearance.colors.colOnErrorContainer;
        default:
            return Appearance.colors.colOnLayer2;
        }
    }

    readonly property color tint: root.roleColor(root.tile.color)
    readonly property color contentColor: root.contentRoleColor(root.tile.color)
    readonly property color mutedContentColor: ColorUtils.transparentize(root.contentColor, 0.35)

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    // "cover"/"banner" paint their own full-bleed background (PresenceMusic/PresenceGame
    // already do), everything else - including the vinyl/wave/timer sub-forms - takes the
    // tile's own silhouette and colour like a scalar tile.
    readonly property string musicForm: root.tile.form || "cover"
    readonly property string gameForm: root.tile.form || "banner"
    readonly property bool fullBleed: (root.tile.type === "music" && root.musicForm === "cover") || (root.tile.type === "game" && root.gameForm === "banner") || root.tile.type === "photo"

    readonly property int clockHour: {
        const m = root.valueText.match(/^(\d{1,2}):/);
        return m ? parseInt(m[1], 10) : -1;
    }

    function weatherShapeName(): string {
        const v = root.valueText.toLowerCase();
        if (/storm|thunder/.test(v))
            return "SoftBurst";
        if (/snow/.test(v))
            return "Cookie9Sided";
        if (/rain|cloud/.test(v))
            return "Cookie6Sided";
        if (/clear|sun/.test(v))
            return "Sunny";
        return "Circle";
    }

    // "auto" lets a form pick its own silhouette instead of the layout naming one up front:
    // a clock's day/night, a weather tile's condition.
    readonly property string resolvedShape: {
        if (root.tile.shape !== "auto")
            return root.tile.shape;
        if (root.tile.form === "clock")
            return (root.clockHour >= 6 && root.clockHour < 19) ? "Sunny" : "Circle";
        if (root.tile.form === "weather")
            return root.weatherShapeName();
        return "Circle";
    }

    readonly property var weatherTempMatch: root.valueText.match(/-?\d+°/)
    readonly property string numberDisplayValue: root.tile.form === "weather" && root.weatherTempMatch ? root.weatherTempMatch[0] : root.valueText
    // weatherShapeName() already reads the condition into the silhouette, so the
    // caption only needs the city - the full "condition · city" string elides at
    // 1x1 otherwise.
    readonly property string numberDisplayLabel: {
        if (root.tile.form !== "weather")
            return root.labelText;
        const stripped = root.valueText.replace(root.weatherTempMatch ? root.weatherTempMatch[0] : "", "").replace(/^[\s·,-]+|[\s·,-]+$/g, "");
        return stripped.includes("·") ? stripped.split("·").pop().trim() : stripped;
    }

    // A deterministic squiggle per track, not a real spectrum - there is no audio data on
    // the wire, so the wave strip is a decoration that at least changes with the song.
    function waveSeed(device): var {
        const key = Statusphere.trackKey(device) || "silence";
        let seed = 0;
        for (let i = 0; i < key.length; i++)
            seed = (seed * 31 + key.charCodeAt(i)) >>> 0;
        const points = [];
        for (let i = 0; i < 24; i++) {
            seed = (seed * 1103515245 + 12345) >>> 0;
            points.push(200 + (seed % 800));
        }
        return points;
    }

    readonly property bool backgroundIsLocal: root.tile.background?.kind === "live" && root.tile.background?.value === "photo"
    readonly property string backgroundSource: {
        const bg = root.tile.background;
        if (root.fullBleed || !bg || bg.kind === "color")
            return "";
        if (bg.kind === "url")
            return bg.value;
        if (bg.value === "music")
            return Statusphere.musicDevices(root.account)[0]?.spotify_art_url ?? "";
        if (bg.value === "game") {
            const g = Statusphere.gameDevices(root.account)[0];
            return g?.game_hero_url || g?.game_header_url || "";
        }
        if (bg.value === "photo")
            return Statusphere.currentPhotoFor(root.account)?.path ?? "";
        return "";
    }

    readonly property bool shaped: !root.fullBleed && root.resolvedShape !== "default"

    Rectangle {
        id: silhouette
        visible: !root.fullBleed && !root.shaped
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: root.backgroundSource ? Appearance.colors.colLayer2 : root.tint
        clip: true

        ThumbnailImage {
            visible: root.backgroundIsLocal
            anchors.fill: parent
            sourcePath: root.backgroundIsLocal ? root.backgroundSource : ""
            fillMode: Image.PreserveAspectCrop

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: silhouette.width
                    height: silhouette.height
                    radius: silhouette.radius
                }
            }
        }

        PresenceArt {
            visible: root.backgroundSource.length > 0 && !root.backgroundIsLocal
            anchors.fill: parent
            source: root.backgroundIsLocal ? "" : root.backgroundSource
        }

        Rectangle { // A form's own text needs to read over whatever art landed underneath it
            visible: root.backgroundSource.length > 0
            anchors.fill: parent
            color: Appearance.colors.colScrim
            opacity: 0.6
        }
    }

    function silhouetteShape(name: string): int {
        switch (name) {
        case "Pill":
            return MaterialShape.Shape.Pill;
        case "Arch":
            return MaterialShape.Shape.Arch;
        case "SemiCircle":
            return MaterialShape.Shape.SemiCircle;
        case "Diamond":
            return MaterialShape.Shape.Diamond;
        case "Pentagon":
            return MaterialShape.Shape.Pentagon;
        case "Cookie4Sided":
            return MaterialShape.Shape.Cookie4Sided;
        case "Cookie6Sided":
            return MaterialShape.Shape.Cookie6Sided;
        case "Cookie9Sided":
            return MaterialShape.Shape.Cookie9Sided;
        case "Clover4Leaf":
            return MaterialShape.Shape.Clover4Leaf;
        case "Heart":
            return MaterialShape.Shape.Heart;
        case "Sunny":
            return MaterialShape.Shape.Sunny;
        case "SoftBurst":
            return MaterialShape.Shape.SoftBurst;
        default:
            return MaterialShape.Shape.Circle;
        }
    }

    MaterialShape {
        visible: root.shaped
        anchors.centerIn: parent
        implicitSize: Math.min(parent.width, parent.height)
        shape: root.silhouetteShape(root.resolvedShape)
        color: root.tint
    }

    Item {
        id: content
        anchors.fill: parent
        // A fixed 12px eats most of a thumbnail-scale tile (a preset preview packs a
        // whole card into ~40px cells) and leaves nothing for text to fit in - scale
        // it with the tile instead.
        anchors.margins: root.fullBleed ? 0 : Math.max(4, Math.round(Math.min(width, height) * 0.1))
        clip: true

        PresenceMusic {
            anchors.fill: parent
            visible: root.tile.type === "music" && root.musicForm === "cover"
            device: Statusphere.musicDevices(root.account)[0] ?? null
        }

        Item {
            id: vinylForm
            anchors.fill: parent
            visible: root.tile.type === "music" && root.musicForm === "vinyl" && !root.thumbnail

            readonly property var musicDevice: Statusphere.musicDevices(root.account)[0] ?? null
            readonly property real progress: (vinylForm.musicDevice?.spotify_length ?? 0) > 0 ? (vinylForm.musicDevice.spotify_position ?? 0) / vinylForm.musicDevice.spotify_length : 0

            CircularProgress {
                anchors.centerIn: parent
                implicitSize: Math.round(Math.min(vinylForm.width, vinylForm.height))
                lineWidth: Math.max(3, implicitSize * 0.06)
                value: vinylForm.progress
                colPrimary: root.contentColor
                colSecondary: ColorUtils.transparentize(root.contentColor, 0.75)
            }

            Item {
                id: cover
                anchors.centerIn: parent
                width: Math.round(Math.min(vinylForm.width, vinylForm.height) * 0.68)
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
                    source: vinylForm.musicDevice?.spotify_art_url ?? ""
                }

                RotationAnimation on rotation {
                    running: vinylForm.musicDevice?.spotify_status === "playing"
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 9000
                }
            }
        }

        ColumnLayout {
            id: waveForm
            anchors.fill: parent
            visible: root.tile.type === "music" && root.musicForm === "wave" && !root.thumbnail
            spacing: 6

            readonly property var musicDevice: Statusphere.musicDevices(root.account)[0] ?? null

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                PresenceArt {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    source: waveForm.musicDevice?.spotify_art_url ?? ""
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: Statusphere.trackFor(waveForm.musicDevice)
                    color: root.contentColor
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                WaveVisualizer {
                    anchors.fill: parent
                    color: root.contentColor
                    live: waveForm.musicDevice?.spotify_status === "playing"
                    points: root.waveSeed(waveForm.musicDevice)
                }
            }
        }

        PresenceGame {
            anchors.fill: parent
            visible: root.tile.type === "game" && root.gameForm === "banner"
            device: Statusphere.gameDevices(root.account)[0] ?? null
        }

        RowLayout {
            id: gameTimer
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            visible: root.tile.type === "game" && root.gameForm === "timer" && !root.thumbnail
            spacing: 8

            readonly property var gameDevice: Statusphere.gameDevices(root.account)[0] ?? null

            MaterialSymbol {
                text: "sports_esports"
                iconSize: Appearance.font.pixelSize.large
                color: root.contentColor
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: gameTimer.gameDevice?.game_source ? Statusphere.labelForKey(gameTimer.gameDevice.game_source) : (Statusphere.gameFor(gameTimer.gameDevice) || "-")
                    color: root.mutedContentColor
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    animateChange: true
                    text: gameTimer.gameDevice ? Statusphere.sessionFor(Statusphere.gameStartedMsFor(gameTimer.gameDevice)) : ""
                    color: root.contentColor
                    font.pixelSize: Appearance.font.pixelSize.large
                }
            }
        }

        PresencePhoto {
            anchors.fill: parent
            visible: root.tile.type === "photo"
            photo: Statusphere.currentPhotoFor(root.account)
            thumbnail: root.thumbnail
        }

        CircularProgress {
            visible: root.tile.type === "scalar" && root.tile.form === "ring" && !root.thumbnail
            anchors.centerIn: parent
            implicitSize: Math.round(Math.min(content.width, content.height))
            lineWidth: Math.max(3, implicitSize * 0.08)
            value: root.hasData ? root.percent / 100 : 0
            colPrimary: root.contentColor
            colSecondary: ColorUtils.transparentize(root.contentColor, 0.75)

            Column {
                anchors.centerIn: parent
                spacing: 0

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    animateChange: true
                    text: root.hasData ? Math.round(root.percent) + "%" : "-"
                    color: root.contentColor
                    font.pixelSize: Appearance.font.pixelSize.large
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(Math.min(content.width, content.height) * 0.7)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.labelText
                    color: root.mutedContentColor
                    font.pixelSize: Appearance.font.pixelSize.smallest
                }
            }
        }

        ColumnLayout {
            visible: root.tile.type === "scalar" && root.tile.form === "bar" && !root.thumbnail
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 4

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.labelText
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.mutedContentColor
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                animateChange: true
                text: root.hasData ? Math.round(root.percent) + "%" : "-"
                font.pixelSize: Appearance.font.pixelSize.huge
                color: root.contentColor
            }
            StyledProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: root.hasData ? root.percent : 0
                valueBarHeight: 6
                wavy: true
                animateWave: false
                highlightColor: root.contentColor
                trackColor: ColorUtils.transparentize(root.contentColor, 0.75)
            }
        }

        ColumnLayout {
            visible: root.tile.type === "scalar" && (root.tile.form === "number" || root.tile.form === "weather") && !root.thumbnail
            anchors.centerIn: parent
            width: parent.width
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.numberDisplayLabel
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: root.mutedContentColor
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Appearance.font.pixelSize.smallest
                animateChange: true
                text: root.hasData ? root.numberDisplayValue : "-"
                font.pixelSize: Appearance.font.pixelSize.huge
                color: root.contentColor
            }
        }

        StyledText {
            visible: root.tile.type === "scalar" && (root.tile.form === "big" || root.tile.form === "clock") && !root.thumbnail
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            fontSizeMode: Text.Fit
            minimumPixelSize: Appearance.font.pixelSize.smallest
            text: root.hasData ? root.valueText : "-"
            font.pixelSize: Appearance.font.pixelSize.huge
            color: root.contentColor
        }

        ColumnLayout {
            visible: root.tile.type === "scalar" && (root.tile.form === "graph" || root.tile.form === "bars") && !root.thumbnail
            anchors.fill: parent
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.labelText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.mutedContentColor
                }
                StyledText {
                    animateChange: true
                    text: root.hasData ? root.valueText : "-"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.contentColor
                }
            }

            CardGraph {
                id: graph
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property var raw: Statusphere.graphValuesFor(root.device, root.tile.field)
                readonly property real lo: raw.length > 0 ? Math.min(...raw) : 0
                readonly property real hi: raw.length > 0 ? Math.max(...raw) : 1
                mode: root.tile.form === "bars" ? "bars" : "line"
                values: graph.raw.map(v => graph.hi > graph.lo ? (v - graph.lo) / (graph.hi - graph.lo) : 0.5)
                color: root.contentColor
            }
        }

        ColumnLayout {
            id: heatmap
            visible: root.tile.type === "scalar" && root.tile.form === "heatmap" && !root.thumbnail
            anchors.fill: parent
            spacing: 4

            readonly property var raw: Statusphere.graphValuesFor(root.device, root.tile.field)
            readonly property real hi: heatmap.raw.length > 0 ? Math.max(1, ...heatmap.raw) : 1

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.labelText
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.mutedContentColor
            }

            Item {
                id: dotsArea
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property int count: heatmap.raw.length
                // Every row count from 1 to count gives a column count (ceil(count / rows))
                // and a dot size bound by whichever of width/height is tighter; picking the
                // row count that maximises that size fills the box on one axis instead of
                // leaving slack on both, and a 2x1 strip no longer packs like a square tile.
                readonly property var packing: {
                    if (dotsArea.count <= 0)
                        return {
                            "cols": 1,
                            "rows": 1,
                            "size": 0
                        };
                    let best = null;
                    for (let rows = 1; rows <= dotsArea.count; rows++) {
                        const cols = Math.ceil(dotsArea.count / rows);
                        const size = Math.min((dotsArea.width - (cols - 1) * 4) / cols, (dotsArea.height - (rows - 1) * 4) / rows);
                        if (!best || size > best.size)
                            best = {
                                "cols": cols,
                                "rows": rows,
                                "size": size
                            };
                    }
                    return best;
                }
                readonly property int cols: dotsArea.packing.cols
                readonly property int rows: dotsArea.packing.rows
                readonly property real dotSize: Math.max(0, dotsArea.packing.size)

                Grid {
                    id: dots
                    anchors.centerIn: parent
                    columns: dotsArea.cols
                    spacing: 4

                    Repeater {
                        model: heatmap.raw

                        delegate: Rectangle {
                            id: dot
                            required property real modelData
                            width: dotsArea.dotSize
                            height: dotsArea.dotSize
                            radius: dotsArea.dotSize / 3
                            color: root.contentColor
                            opacity: 0.15 + 0.75 * (dot.modelData / heatmap.hi)
                        }
                    }
                }
            }
        }

        ColumnLayout {
            visible: root.tile.type === "scalar" && root.tile.form === "text" && !root.thumbnail
            anchors.fill: parent
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                MaterialSymbol {
                    visible: (root.field?.icon ?? "").length > 0
                    text: root.field?.icon ?? ""
                    iconSize: Appearance.font.pixelSize.smaller
                    color: root.mutedContentColor
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.labelText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.mutedContentColor
                }
            }
            StyledText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                fontSizeMode: Text.Fit
                minimumPixelSize: Appearance.font.pixelSize.smallest
                animateChange: true
                text: root.hasData ? root.valueText : "-"
                font.pixelSize: Appearance.font.pixelSize.huge
                color: root.contentColor
            }
        }
    }
}
