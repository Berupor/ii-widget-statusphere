pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects

/**
 * The picture of the game a device is in. The title and the session are said once, by
 * the row's status line. Steam serves a header capsule for every title, the wide hero
 * and the transparent logo only where the publisher uploaded them, so the picture
 * degrades a step at a time: hero, header, then nothing and the line carries it alone.
 */
Rectangle {
    id: root
    required property var device

    readonly property string logo: root.device?.game_logo_url ?? ""
    // A cover is 2:3 and comes out of a wide band as a random slice of box art, so it is
    // not in the chain - only the two pictures that were cut wide to begin with.
    readonly property var bannerUrls: [root.device?.game_hero_url ?? "", root.device?.game_header_url ?? ""].filter(url => url.length > 0)
    readonly property bool hasBanner: root.bannerUrls.length > 0 && art.status !== Image.Error

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    clip: true // Content is full height immediately; without this the bg catches up visibly

    // Hero is 3.1:1 and header 2.14:1, so the loaded picture sets the height rather than
    // one of the two getting cropped into a band it was never cut for. The ceiling is a
    // ratio: a pixel count is tuned for one card width and crops hard at the next.
    readonly property real natural: root.width * art.heightPerWidth
    implicitHeight: root.natural > 0 ? Math.round(Math.max(80, Math.min(root.width / 2, root.natural))) : 120

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Item {
        id: banner
        anchors.fill: parent

        layer.enabled: true // clip squares the bounding box and leaves the corners
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: banner.width
                height: banner.height
                radius: root.radius
            }
        }

        PresenceArt {
            id: art
            anchors.fill: parent
            radius: 0
            color: "transparent"
            fallbackIcon: ""
            source: root.bannerUrls[0] ?? ""
            fallbacks: root.bannerUrls.slice(1)
        }

        Rectangle { // Only where a logo has to be carried
            visible: root.logo.length > 0
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

        PresenceArt { // Bottom left, where Steam's own library grid puts it
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: 12
            }
            width: Math.round(banner.width * 0.45)
            height: Math.round(banner.height * 0.42)
            radius: 0
            color: "transparent"
            fallbackIcon: ""
            source: root.logo
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            verticalAlignment: Image.AlignBottom
        }
    }
}
