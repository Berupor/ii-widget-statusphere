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
    // A pack preview squeezes a surface into ~20px cells with no room for text -
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
    readonly property string notedLabelText: root.field?.note ? `${root.labelText} · ${root.field.note}` : root.labelText
    readonly property string shownValueText: root.hasData ? root.withSymbolsAttached(root.valueText) : "-"

    readonly property var symbolCodeRanges: [[0x21, 0x2F], [0x3A, 0x40], [0x5B, 0x60], [0x7B, 0x7E], [0x2000, 0x2BFF], [0xFE00, 0xFE0F], [0x1F000, 0x1FAFF]]

    function isSymbol(token: string): bool {
        return [...token].every(ch => root.symbolCodeRanges.some(([from, to]) => ch.codePointAt(0) >= from && ch.codePointAt(0) <= to));
    }

    function withSymbolsAttached(text: string): string {
        const nbsp = "\u00A0";
        return text.replace(/^(\S+) +(?=\S)/, (whole, first) => root.isSymbol(first) ? first + nbsp : whole).replace(/(\S) +(\S+)$/, (whole, before, last) => root.isSymbol(last) ? before + nbsp + last : whole);
    }

    component ShrinkThenWrapText: StyledText {
        id: fitText
        property real largestSize: Appearance.font.pixelSize.huge
        property real wrapBelow: Appearance.font.pixelSize.normal
        property int maxLines: 2
        readonly property bool canWrap: fitText.maxLines > 1 && /[ \t\n]/.test(fitText.text)
        readonly property real oneLineSize: Math.min(fitText.largestSize, Math.floor(fitText.largestSize * fitText.width / Math.max(1, oneLineMetrics.advanceWidth)))
        readonly property real shrinkFloor: fitText.canWrap ? fitText.wrapBelow : Appearance.font.pixelSize.smallest
        readonly property bool fitsOneLine: fitText.oneLineSize >= fitText.shrinkFloor

        font.pixelSize: fitText.fitsOneLine ? fitText.oneLineSize : fitText.shrinkFloor
        wrapMode: fitText.fitsOneLine ? Text.NoWrap : Text.WordWrap
        maximumLineCount: fitText.maxLines
        fontSizeMode: Text.Fit
        minimumPixelSize: Appearance.font.pixelSize.smallest
        elide: Text.ElideRight

        TextMetrics {
            id: oneLineMetrics
            font.family: fitText.shouldUseNumberFont ? Appearance.font.family.numbers : Appearance.font.family.main
            font.pixelSize: fitText.largestSize
            text: fitText.text
        }
    }

    // StyledProgressBar draws its line as thick as the bar item is tall and swings the wave
    // past that height, so the wave gets its room from a wrapper instead of a taller bar.
    component WaveBar: Item {
        property alias value: waveBarLine.value
        property alias to: waveBarLine.to
        property alias animateWave: waveBarLine.animateWave
        implicitHeight: waveBarLine.valueBarHeight * (1 + 2 * waveBarLine.waveAmplitudeMultiplier)

        StyledProgressBar {
            id: waveBarLine
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            from: 0
            valueBarHeight: root.waveLineWidth
            waveFrequency: width / root.waveLength
            wavy: true
            highlightColor: root.contentColor
            trackColor: ColorUtils.transparentize(root.contentColor, 0.75)
        }
    }

    component NotedLabel: ShrinkThenWrapText {
        id: notedLabel
        largestSize: Appearance.font.pixelSize.smaller
        maxLines: 1
        text: notedMetrics.advanceWidth <= notedLabel.width ? root.notedLabelText : root.labelText
        color: root.mutedContentColor

        TextMetrics {
            id: notedMetrics
            font.family: Appearance.font.family.main
            font.pixelSize: notedLabel.largestSize
            text: root.notedLabelText
        }
    }

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
    // StyledProgressBar counts waves per bar width and ties their height to the line
    // width, so a fixed wave length keeps a narrow tile from turning into a zigzag.
    readonly property real waveLength: 40
    readonly property real waveLineWidth: 4

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
        // A fixed 12px eats most of a thumbnail-scale tile (a pack preview squeezes a
        // surface into ~20px cells) and leaves nothing for text to fit in - scale it
        // with the tile instead.
        anchors.margins: root.fullBleed ? 0 : Math.max(4, Math.round(Math.min(root.width, root.height) * 0.1))
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
            readonly property bool hasPosition: (vinylForm.musicDevice?.spotify_length ?? 0) > 0
            readonly property real progress: vinylForm.hasPosition ? (vinylForm.musicDevice.spotify_position ?? 0) / vinylForm.musicDevice.spotify_length : 0

            CircularProgress {
                visible: vinylForm.hasPosition
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
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            visible: root.tile.type === "music" && root.musicForm === "wave" && !root.thumbnail
            spacing: 6

            readonly property var musicDevice: Statusphere.musicDevices(root.account)[0] ?? null
            readonly property bool hasPosition: (waveForm.musicDevice?.spotify_length ?? 0) > 0
            readonly property real progress: waveForm.hasPosition ? (waveForm.musicDevice.spotify_position ?? 0) / waveForm.musicDevice.spotify_length : 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                PresenceArt {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    source: waveForm.musicDevice?.spotify_art_url ?? ""
                }
                ShrinkThenWrapText {
                    Layout.fillWidth: true
                    largestSize: Appearance.font.pixelSize.smaller
                    maxLines: 1
                    text: Statusphere.trackFor(waveForm.musicDevice)
                    color: root.contentColor
                }
            }

            WaveBar {
                Layout.fillWidth: true
                visible: waveForm.hasPosition
                to: 1
                value: waveForm.progress
                animateWave: waveForm.musicDevice?.spotify_status === "playing"
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
            cropped: true
        }

        CircularProgress {
            id: ring
            visible: root.tile.type === "scalar" && root.tile.form === "ring" && !root.thumbnail
            anchors.centerIn: parent
            implicitSize: Math.round(Math.min(content.width, content.height))
            lineWidth: Math.max(3, implicitSize * 0.08)
            value: root.hasData ? root.percent / 100 : 0
            colPrimary: root.contentColor
            colSecondary: ColorUtils.transparentize(root.contentColor, 0.75)

            readonly property real innerBox: (ring.implicitSize - 2 * ring.lineWidth) * Math.SQRT1_2
            readonly property bool captionFits: ringValue.implicitHeight + ringCaption.implicitHeight <= ring.innerBox && ringCaption.fitsOneLine

            Column {
                anchors.centerIn: parent
                width: ring.innerBox
                spacing: 0

                StyledText {
                    id: ringValue
                    objectName: "ringValue"
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: Appearance.font.pixelSize.smallest
                    animateChange: true
                    text: root.hasData ? Math.round(root.percent) + "%" : "-"
                    color: root.contentColor
                    font.pixelSize: Math.max(Appearance.font.pixelSize.smallest, ring.innerBox * 0.4)
                }
                ShrinkThenWrapText {
                    id: ringCaption
                    objectName: "ringCaption"
                    visible: ring.captionFits
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    largestSize: Math.max(Appearance.font.pixelSize.smallest, ring.innerBox * 0.2)
                    maxLines: 1
                    text: root.labelText
                    color: root.mutedContentColor
                }
            }
        }

        ColumnLayout {
            visible: root.tile.type === "scalar" && root.tile.form === "bar" && !root.thumbnail
            anchors.fill: parent
            spacing: 4

            NotedLabel {
                Layout.fillWidth: true
            }
            ShrinkThenWrapText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                maxLines: 1
                animateChange: true
                text: root.hasData ? Math.round(root.percent) + "%" : "-"
                color: root.contentColor
            }
            WaveBar {
                Layout.fillWidth: true
                to: 100
                value: root.hasData ? root.percent : 0
                animateWave: false
            }
        }

        ColumnLayout {
            visible: root.tile.type === "scalar" && (root.tile.form === "number" || root.tile.form === "weather") && !root.thumbnail
            anchors.centerIn: parent
            width: parent.width
            spacing: 2

            ShrinkThenWrapText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                largestSize: Appearance.font.pixelSize.smallest
                wrapBelow: Appearance.font.pixelSize.smallest
                text: root.numberDisplayLabel
                color: root.mutedContentColor
            }
            ShrinkThenWrapText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                maxLines: 1
                animateChange: true
                text: root.hasData ? root.numberDisplayValue : "-"
                color: root.contentColor
            }
        }

        ShrinkThenWrapText {
            visible: root.tile.type === "scalar" && root.tile.form === "clock" && !root.thumbnail
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            maxLines: 3
            text: root.shownValueText
            color: root.contentColor
        }

        // "big" is a value tile like any other - a bare number or word with no label
        // reads as decoration, not data, so it keeps the same small caption the
        // number/weather forms show above their value.
        ColumnLayout {
            visible: root.tile.type === "scalar" && root.tile.form === "big" && !root.thumbnail
            anchors.fill: parent
            spacing: 2

            NotedLabel {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                largestSize: Appearance.font.pixelSize.smallest
            }
            ShrinkThenWrapText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                maxLines: 3
                animateChange: true
                text: root.shownValueText
                color: root.contentColor
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
                NotedLabel {
                    Layout.fillWidth: true
                }
            }
            ShrinkThenWrapText {
                objectName: "textValue"
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                animateChange: true
                text: root.shownValueText
                color: root.contentColor
            }
        }
    }
}
