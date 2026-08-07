pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * One device's current game. Steam serves a header capsule for every title, but the wide
 * hero and the transparent logo only exist where the publisher uploaded them - so the card
 * loses them one at a time: hero+logo, hero alone, header, then just the name and the clock.
 */
Rectangle {
    id: root
    required property var device
    property bool compact: false // A photo already fills the card, so keep this to one thin line
    property bool _expanded: false // Tapped open out of the compact line

    onCompactChanged: if (!root.compact)
        root._expanded = false

    readonly property bool showingCompact: root.compact && !root._expanded

    readonly property string name: root.device?.game_name ?? ""
    readonly property string logo: root.device?.game_logo_url ?? ""
    // A cover is 2:3 and comes out of a wide band as a random slice of box art, so it is
    // not in the chain - only the two pictures that were cut wide to begin with.
    readonly property var bannerUrls: [root.device?.game_hero_url ?? "", root.device?.game_header_url ?? ""].filter(url => url.length > 0)
    readonly property bool bannerDead: art.status === Image.Error && art.currentFallbackIndex >= art.fallbacks.length
    readonly property bool hasBanner: !root.showingCompact && root.bannerUrls.length > 0 && !root.bannerDead

    radius: root.showingCompact ? 0 : Appearance.rounding.normal
    color: root.showingCompact ? "transparent" : Appearance.colors.colLayer2
    implicitHeight: content.implicitHeight + (root.showingCompact ? 0 : 24)
    clip: true // Content is full height immediately; without this the bg catches up visibly

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // The music card's interpolation without the length: a session only climbs and has
    // nothing to run against, so anchor on what the device sent and keep our own clock.
    readonly property real elapsed: root.device?.game_status ? root.projectedSeconds(root._nowMs) : 0

    property real _nowMs: Date.now()
    property real _anchorMs: Date.now()
    property real _anchorSeconds: 0
    property string _anchorKey: ""

    Timer {
        interval: 1000
        running: root.visible && root.device?.game_status === "playing"
        repeat: true
        onTriggered: root._nowMs = Date.now()
    }

    function projectedSeconds(nowMs: real): real {
        return Math.max(0, root._anchorSeconds + (nowMs - root._anchorMs) / 1000);
    }

    function sync(): void {
        const d = root.device;
        const key = String(d?.game_appid ?? d?.game_name ?? "");
        const fresh = key !== root._anchorKey;

        if (fresh) {
            // StyledImage walks its list by assigning source, so a binding there is gone after
            // the first miss and the index never rewinds. A new title restarts the walk by hand.
            art.currentFallbackIndex = 0;
            art.source = root.bannerUrls[0] ?? "";
        }

        // Inside one session the count only rises, so a step back is a restart, not drift.
        const raw = d?.game_session_seconds ?? 0;
        if (!fresh && Math.abs(raw - root.projectedSeconds(Date.now())) <= 5)
            return;
        root._anchorMs = Date.now();
        root._nowMs = root._anchorMs;
        root._anchorSeconds = raw;
        root._anchorKey = key;
    }

    Component.onCompleted: root.sync()
    onDeviceChanged: root.sync()

    MouseArea { // Tap the opened-up card to collapse it back to the compact line
        anchors.fill: content
        enabled: root.compact && !root.showingCompact
        cursorShape: Qt.PointingHandCursor
        onClicked: root._expanded = false
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: root.showingCompact ? 0 : 12
        }
        spacing: 10

        Item {
            id: banner
            Layout.fillWidth: true
            visible: root.hasBanner

            // Hero is 3.1:1 and header 2.14:1, so the loaded picture sets the height rather
            // than one of the two getting cropped into a band it was never cut for.
            readonly property real natural: art.implicitWidth > 0 ? width * art.implicitHeight / art.implicitWidth : 0
            implicitHeight: banner.natural > 0 ? Math.round(Math.max(80, Math.min(200, banner.natural))) : 120

            layer.enabled: true // clip squares the bounding box and leaves the corners
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: banner.width
                    height: banner.height
                    radius: Appearance.rounding.small
                }
            }

            StyledImage {
                id: art
                anchors.fill: parent
                fallbacks: root.bannerUrls.slice(1) // source is assigned in sync(), never bound
                fillMode: Image.PreserveAspectCrop
                cache: true
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: Math.round(banner.height * 0.75)
                // Black, not colScrim: this has to carry a light logo over a white sky (Space
                // Marine 2 has one), and darkening someone else's art is not the palette's call.
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(0, 0, 0, 0)
                    }
                    GradientStop {
                        position: 0.45
                        color: Qt.rgba(0, 0, 0, 0.32)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(0, 0, 0, 0.85)
                    }
                }
            }

            StyledImage { // Bottom left, where Steam's own library grid puts it
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: 12
                }
                width: Math.round(banner.width * 0.45)
                height: Math.round(banner.height * 0.42)
                source: root.logo
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft
                verticalAlignment: Image.AlignBottom
                cache: true
            }
        }

        RowLayout { // Spelled out under the art: a stylised logo is a picture, not a label
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                text: "sports_esports"
            }

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
                font.pixelSize: root.showingCompact ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.normal
                color: root.showingCompact ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer2
                text: root.name
            }

            Row { // Digits in equal cells, else the row twitches every second
                Layout.alignment: Qt.AlignVCenter
                visible: root.elapsed > 0

                TextMetrics {
                    id: digitCell
                    text: "0123456789"
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.variableAxes: Appearance.font.variableAxes.main
                }

                Repeater {
                    model: StringUtils.friendlyTimeForSeconds(root.elapsed).split("")

                    delegate: StyledText {
                        required property string modelData
                        shouldUseNumberFont: false
                        width: /\d/.test(modelData) ? digitCell.width / 10 : implicitWidth
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        text: modelData
                    }
                }
            }
        }
    }

    MouseArea { // Tap the strip to open the card
        anchors.fill: content
        enabled: root.showingCompact
        cursorShape: Qt.PointingHandCursor
        onClicked: root._expanded = true
    }
}
