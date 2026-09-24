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

    readonly property var device: Statusphere.deviceForTile(root.account, root.tile)
    readonly property bool hasData: Statusphere.tileHasData(root.account, root.tile)
    readonly property bool dimmed: !root.hasData && root.tile.onMissing === "dim"
    opacity: root.dimmed ? 0.45 : 1

    readonly property var field: root.tile.type === "scalar" ? Statusphere.fieldFor(root.device, root.tile.field) : null
    readonly property real percent: root.field?.percent ?? 0
    readonly property string valueText: root.field?.value ?? "-"
    readonly property string labelText: root.field?.label ?? root.tile.field

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

    function onRoleColor(role: string): color {
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
    readonly property color onTint: root.onRoleColor(root.tile.color)
    readonly property bool composite: root.tile.type === "music" || root.tile.type === "game" || root.tile.type === "photo"
    readonly property bool shaped: !root.composite && root.tile.shape !== "default"

    readonly property bool backgroundIsLocal: root.tile.background?.kind === "live" && root.tile.background?.value === "photo"
    readonly property string backgroundSource: {
        const bg = root.tile.background;
        if (root.composite || !bg || bg.kind === "color")
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

    Rectangle {
        id: silhouette
        visible: !root.composite && !root.shaped
        anchors.fill: parent
        radius: Appearance.rounding.normal
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
        default:
            return MaterialShape.Shape.Circle;
        }
    }

    MaterialShape {
        visible: root.shaped
        anchors.centerIn: parent
        implicitSize: Math.min(parent.width, parent.height)
        shape: root.silhouetteShape(root.tile.shape)
        color: root.tint
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.composite ? 0 : 10
        clip: root.composite

        PresenceMusic {
            anchors.fill: parent
            visible: root.tile.type === "music"
            device: Statusphere.musicDevices(root.account)[0] ?? null
        }

        PresenceGame {
            anchors.fill: parent
            visible: root.tile.type === "game"
            device: Statusphere.gameDevices(root.account)[0] ?? null
        }

        PresencePhoto {
            anchors.fill: parent
            visible: root.tile.type === "photo"
            photo: Statusphere.currentPhotoFor(root.account)
        }

        CircularProgress {
            visible: root.tile.type === "scalar" && root.tile.form === "ring"
            anchors.centerIn: parent
            implicitSize: Math.round(Math.min(content.width, content.height))
            lineWidth: Math.max(3, implicitSize * 0.08)
            value: root.hasData ? root.percent / 100 : 0
            colPrimary: root.onTint
            colSecondary: ColorUtils.transparentize(root.onTint, 0.75)

            StyledText {
                anchors.centerIn: parent
                text: root.hasData ? Math.round(root.percent) + "%" : "-"
                color: root.onTint
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        ColumnLayout {
            visible: root.tile.type === "scalar" && root.tile.form === "bar"
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 4

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.labelText
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.onTint
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.hasData ? Math.round(root.percent) + "%" : "-"
                font.pixelSize: Appearance.font.pixelSize.huge
                color: root.onTint
            }
            StyledProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: root.hasData ? root.percent : 0
                valueBarHeight: 6
                highlightColor: root.onTint
                trackColor: ColorUtils.transparentize(root.onTint, 0.75)
            }
        }

        ColumnLayout {
            visible: root.tile.type === "scalar" && root.tile.form === "number"
            anchors.centerIn: parent
            spacing: 2

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.valueText
                font.pixelSize: Appearance.font.pixelSize.huge
                color: root.onTint
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                elide: Text.ElideRight
                text: root.labelText
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: root.onTint
            }
        }

        Graph {
            id: graph
            visible: root.tile.type === "scalar" && root.tile.form === "graph"
            anchors.fill: parent

            readonly property var raw: Statusphere.graphValuesFor(root.device, root.tile.field)
            readonly property real lo: raw.length > 0 ? Math.min(...raw) : 0
            readonly property real hi: raw.length > 0 ? Math.max(...raw) : 1
            values: graph.raw.map(v => graph.hi > graph.lo ? (v - graph.lo) / (graph.hi - graph.lo) : 0.5)
            color: root.onTint
        }

        RowLayout {
            visible: root.tile.type === "scalar" && root.tile.form === "text"
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 6

            MaterialSymbol {
                text: Statusphere.iconForField(root.tile.field)
                iconSize: Appearance.font.pixelSize.normal
                color: root.onTint
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.labelText
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.onTint
            }
            StyledText {
                horizontalAlignment: Text.AlignRight
                text: root.valueText
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.onTint
            }
        }
    }
}
