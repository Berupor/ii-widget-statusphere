pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

Rectangle {
    id: root
    required property string modelData

    readonly property var account: Statusphere.accountsById[root.modelData] ?? null
    readonly property bool offline: root.account?.offline ?? true
    readonly property bool hidden: Statusphere.hiddenFor(root.account)
    readonly property bool away: Statusphere.awayFor(root.account)
    readonly property bool isSelf: root.modelData === Statusphere.selfAccountId
    readonly property bool isServer: Statusphere.isServer(root.account)
    readonly property string health: root.offline ? "" : Statusphere.healthFor(root.account)
    readonly property bool canPick: root.isSelf && Statusphere.available && Statusphere.opt("incognito")
    readonly property var devices: root.account?.devices ?? []
    readonly property var playing: Statusphere.musicDevices(root.account)
    readonly property var gaming: Statusphere.gameDevices(root.account)
    readonly property var currentPhoto: Statusphere.currentPhotoFor(root.account)
    readonly property bool hasPhoto: root.currentPhoto !== null
    readonly property bool customLayout: Statusphere.ownsSurface(root.account, "row")
    readonly property var rowTiles: root.customLayout ? Statusphere.surfaceTiles(root.account, "row") : []
    readonly property var detailTiles: root.detailsShown ? Statusphere.surfaceTiles(root.account, "detail") : []
    readonly property bool canShare: root.isSelf && Statusphere.canShare
    readonly property bool expandable: root.devices.length > 1 && !root.hidden
    property bool expanded: false

    // One picture slot per row, and the later event takes it: a photo just shared beats a
    // session started this morning, and the other one waits behind the chip in the header.
    readonly property bool gameHasArt: root.gaming.length > 0 && game.hasBanner
    readonly property real photoAtMs: root.currentPhoto ? Date.parse(root.currentPhoto.created_at) : 0
    readonly property real gameAtMs: Statusphere.gameStartedMsFor(root.gaming[0] ?? null)
    readonly property bool bothPictures: root.hasPhoto && root.gameHasArt
    property bool slotSwapped: false
    readonly property bool showPhoto: root.hasPhoto && (!root.gameHasArt || ((root.photoAtMs >= root.gameAtMs) !== root.slotSwapped))
    readonly property bool showGame: root.gameHasArt && !root.showPhoto

    onBothPicturesChanged: if (!root.bothPictures)
        root.slotSwapped = false

    onExpandableChanged: if (!root.expandable)
        root.expanded = false

    property var playingIds: []
    property var deviceIds: []
    onPlayingChanged: root.keepIds("playingIds", root.playing)
    onDevicesChanged: root.keepIds("deviceIds", root.devices)
    Component.onCompleted: {
        root.keepIds("playingIds", root.playing);
        root.keepIds("deviceIds", root.devices);
    }

    function keepIds(name, devices) {
        const ids = devices.map(d => d.device_id);
        if (!CardLayouts.sameArray(root[name], ids))
            root[name] = ids;
    }

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    opacity: root.offline ? 0.6 : 1
    clip: true // Content is full height immediately; without this the bg catches up visibly

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MouseArea { // Under everything, so art sync and the details tooltip get their clicks first
        anchors.fill: parent
        enabled: root.expandable
        onClicked: root.expanded = !root.expanded
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            PresenceAvatar {
                id: avatar
                Layout.alignment: Qt.AlignVCenter
                account: root.account
                offline: root.offline
                hidden: root.hidden
                away: root.away
                shape: Statusphere.avatarShapeFor(root.account)
                interactive: root.canPick
                onHoldStarted: picker.open = true
                onHoldMoved: (x, y) => {
                    const point = avatar.mapToItem(picker, x, y);
                    picker.hoverAt(point.x, point.y);
                }
                onHoldEnded: {
                    picker.apply();
                    picker.open = false;
                    picker.hovered = -1;
                }
                onTapped: if (root.expandable)
                    root.expanded = !root.expanded
            }

            Item { // Who they are, or the picker while you're holding your own row
                Layout.fillWidth: true
                implicitHeight: Math.max(info.implicitHeight, picker.implicitHeight)

                ColumnLayout {
                    id: info
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2
                    opacity: picker.open ? 0 : 1

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        color: Appearance.colors.colOnLayer2
                        text: Statusphere.nameFor(root.account)
                    }

                    StyledText { // The blurred avatar already says they're hiding
                        Layout.fillWidth: true
                        visible: text.length > 0
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: {
                            if (root.health === "crit")
                                return Appearance.colors.colError;
                            if (root.health === "warn")
                                return Appearance.colors.colTertiary;
                            return Appearance.colors.colSubtext;
                        }
                        text: root.offline ? Statusphere.offlineLineFor(root.account) : Statusphere.statusFor(root.account, root.visibleSurfaces)
                    }
                }

                PresenceIncognitoPicker {
                    id: picker
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle { // What the picture slot is not showing, and the way back to it
                visible: !root.customLayout && !root.hidden && root.bothPictures && !root.expanded
                Layout.alignment: Qt.AlignVCenter
                radius: Appearance.rounding.full
                color: swapArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                implicitWidth: swapChip.implicitWidth + 14
                implicitHeight: swapChip.implicitHeight + 6

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                RowLayout {
                    id: swapChip
                    anchors.centerIn: parent
                    spacing: 3

                    MaterialSymbol {
                        text: root.showPhoto ? "sports_esports" : "image"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    StyledText { // The game is already named up in the status line
                        visible: text.length > 0
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        text: root.showPhoto ? "" : Statusphere.sessionFor(root.photoAtMs)
                    }
                }

                MouseArea {
                    id: swapArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.slotSwapped = !root.slotSwapped
                }

                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: swapArea.containsMouse
                    text: root.showPhoto ? Translation.tr("Show the game instead") : Translation.tr("Show the photo instead")
                }
            }

            Rectangle { // The status line only ever speaks for one device, so count them here
                visible: !root.offline && root.expandable
                Layout.alignment: Qt.AlignVCenter
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer2
                implicitWidth: deviceChip.implicitWidth + 14
                implicitHeight: deviceChip.implicitHeight + 6

                RowLayout {
                    id: deviceChip
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialSymbol {
                        text: root.expanded ? "expand_less" : "devices"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        text: root.devices.length
                    }
                }
            }
        }

        PresencePhoto {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: !root.customLayout && !root.hidden && root.showPhoto && !root.expanded
            photo: root.currentPhoto
        }

        PresenceGame {
            id: game
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: !root.customLayout && !root.hidden && root.showGame && !root.expanded
            device: root.gaming[0] ?? null
        }

        Rectangle {
            visible: (music.item?.showingCompact ?? false) && (root.showPhoto || root.showGame)
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
        }

        Loader { // One art with the rest of the stack peeking out behind it, unless a photo already fills the space
            id: music
            Layout.fillWidth: true
            active: !root.customLayout && !root.hidden && root.playing.length > 0 && !root.expanded
            visible: active
            sourceComponent: PresenceMusic {
                compact: root.showPhoto || root.showGame
                device: root.playing[0] ?? null
                stackedDevice: root.playing[1] ?? null
                stackedCount: root.playing.length - 1
            }
        }

        CardGrid { // The owner's own row layout, in place of the picture/music stack above
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: root.customLayout && !root.hidden && root.rowTiles.length > 0 && !root.expanded
            account: root.account
            tiles: root.rowTiles
            maxRows: CardLayouts.rowRows
        }

        ColumnLayout { // Expanded: the music once per track, then what each device is up to
            Layout.fillWidth: true
            Layout.leftMargin: avatar.implicitWidth + 12 // Under the name, not under the face
            visible: root.expanded
            spacing: 8

            Repeater {
                model: root.expanded ? root.playingIds : []

                delegate: ColumnLayout {
                    id: trackEntry
                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        visible: trackEntry.index > 0
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Appearance.colors.colOutlineVariant
                    }

                    PresenceMusic {
                        Layout.fillWidth: true
                        device: root.playing.find(d => d.device_id === trackEntry.modelData) ?? null
                    }
                }
            }

            Rectangle {
                visible: root.playing.length > 0
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }

            Repeater {
                model: root.expanded ? root.deviceIds : []

                delegate: StyledText {
                    id: deviceLine
                    required property string modelData
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: Statusphere.deviceStatusFor(root.devices.find(d => d.device_id === deviceLine.modelData) ?? null)
                }
            }
        }

        Loader { // Right click: the noisy stuff (cpu/mem/disk, workspace, weather)
            Layout.fillWidth: true
            Layout.topMargin: 4
            active: root.detailsShown
            visible: active
            sourceComponent: PresenceDetailCard {
                account: root.account
                tiles: root.detailTiles
            }
        }

        PresenceActions { // Middle click, own card only
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.showActions && root.canShare
            photo: root.currentPhoto
        }
    }

    property bool showDetails: false
    property bool showActions: false
    // Server cards show details by default (serverMetrics option), which used to make
    // them the one card right-click couldn't collapse - this tracks that dismissal separately
    readonly property bool serverDetailsForced: root.isServer && !root.offline && Statusphere.opt("serverMetrics")
    // Kept in the singleton, not here: a reconnect resorts accountIds and rebuilds this row
    readonly property bool serverDetailsCollapsed: Statusphere.detailsCollapsedFor(root.modelData)

    readonly property bool detailsShown: !root.hidden && (root.showDetails || (root.serverDetailsForced && !root.serverDetailsCollapsed))

    // Must track the CardGrid `visible:` condition above - a surface only covers a field
    // for the header while its tiles are actually on screen.
    readonly property var visibleSurfaces: {
        const surfaces = {};
        if (root.customLayout && root.rowTiles.length > 0 && !root.expanded)
            surfaces.row = root.rowTiles;
        if (root.detailsShown)
            surfaces.detail = root.detailTiles;
        return surfaces;
    }

    onCanShareChanged: if (!root.canShare)
        root.showActions = false

    MouseArea { // Both toggle a section above, growing the card in place
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.canShare)
                    root.showActions = !root.showActions;
                return;
            }
            if (root.serverDetailsForced) {
                Statusphere.toggleDetailsCollapsed(root.modelData);
                return;
            }
            root.showDetails = !root.showDetails;
        }
    }
}
