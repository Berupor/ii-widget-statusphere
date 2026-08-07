pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property string modelData

    readonly property var account: Statusphere.accountsById[root.modelData] ?? null
    readonly property bool offline: root.account?.offline ?? true
    readonly property bool hidden: Statusphere.hiddenFor(root.account)
    readonly property bool isSelf: root.modelData === Statusphere.selfAccountId
    readonly property bool isServer: Statusphere.isServer(root.account)
    readonly property string health: root.offline ? "" : Statusphere.healthFor(root.account)
    readonly property bool canPick: root.isSelf && Statusphere.available && Statusphere.opt("incognito")
    readonly property var devices: root.account?.devices ?? []
    readonly property var playing: Statusphere.musicDevices(root.account)
    readonly property var gaming: Statusphere.opt("games") ? Statusphere.gameDevices(root.account) : []
    readonly property var currentPhoto: Statusphere.currentPhotoFor(root.account)
    readonly property bool hasPhoto: Statusphere.opt("photos") && root.currentPhoto !== null
    readonly property bool canShare: root.isSelf && Statusphere.canShare
    readonly property bool expandable: root.devices.length > 1
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
                        text: root.offline ? Statusphere.offlineLineFor(root.account) : Statusphere.statusFor(root.account)
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
                visible: root.bothPictures && !root.expanded
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
            visible: root.showPhoto && !root.expanded
            photo: root.currentPhoto
        }

        PresenceGame {
            id: game
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: root.showGame && !root.expanded
            device: root.gaming[0] ?? null
        }

        Rectangle {
            visible: music.visible && music.showingCompact && (root.showPhoto || root.showGame)
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
        }

        PresenceMusic { // One art with the rest of the stack peeking out behind it, unless a photo already fills the space
            id: music
            Layout.fillWidth: true
            visible: root.playing.length > 0 && !root.expanded
            compact: root.showPhoto || root.showGame
            device: root.playing[0] ?? null
            stackedDevice: root.playing[1] ?? null
            stackedCount: root.playing.length - 1
        }

        ColumnLayout { // Expanded: the music once per track, then what each device is up to
            Layout.fillWidth: true
            Layout.leftMargin: avatar.implicitWidth + 12 // Under the name, not under the face
            visible: root.expanded
            spacing: 8

            Repeater {
                model: root.expanded ? root.playing : []

                delegate: ColumnLayout {
                    id: trackEntry
                    required property var modelData
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
                        device: trackEntry.modelData
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
                model: root.expanded ? root.devices : []

                delegate: StyledText {
                    required property var modelData
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: Statusphere.deviceStatusFor(modelData)
                }
            }
        }

        PresenceDetailCard { // Right click: the noisy stuff (cpu/mem/disk, workspace, weather)
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.showDetails || (root.serverDetailsForced && !root.serverDetailsCollapsed)
            account: root.account
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
    property bool serverDetailsCollapsed: false

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
                root.serverDetailsCollapsed = !root.serverDetailsCollapsed;
                return;
            }
            root.showDetails = !root.showDetails;
        }
    }
}
