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
    property bool compact: false // A photo already fills the card, so keep this to one line

    readonly property string name: root.device?.game_name ?? ""
    readonly property string logo: root.device?.game_logo_url ?? ""
    // A cover is 2:3 and comes out of a wide band as a random slice of box art, so it is
    // not in the chain - only the two pictures that were cut wide to begin with.
    readonly property var bannerUrls: [root.device?.game_hero_url ?? "", root.device?.game_header_url ?? ""].filter(url => url.length > 0)
    readonly property bool bannerDead: art.status === Image.Error && art.currentFallbackIndex >= art.fallbacks.length
    readonly property bool hasBanner: !root.compact && root.bannerUrls.length > 0 && !root.bannerDead

    radius: root.compact ? 0 : Appearance.rounding.normal
    color: root.compact ? "transparent" : Appearance.colors.colLayer2
    implicitHeight: content.implicitHeight + (root.compact ? 0 : 24)
    clip: true // Content is full height immediately; without this the bg catches up visibly

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    readonly property real startedMs: {
        const at = Date.parse(root.device?.game_started_at ?? "");
        if (!isNaN(at))
            return at;
        const secs = root.device?.game_session_seconds ?? 0;
        return secs > 0 ? Date.now() - secs * 1000 : 0;
    }

    // game_started_at does not move, so the label cannot drift; the singleton's 30s tick is
    // what re-reads the clock between roster lines, which is all a minute-grained label needs.
    readonly property string session: Statusphere._now > 0 ? Statusphere.sessionFor(root.startedMs) : ""

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: root.compact ? 0 : 12
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
                fallbacks: root.bannerUrls.slice(1) // source is assigned in reload(), never bound
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
                font.pixelSize: root.compact ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.normal
                color: root.compact ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer2
                text: root.name
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                visible: root.session.length > 0
                textFormat: Text.PlainText
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: root.session
            }
        }
    }

    // StyledImage walks its list by assigning source, so a binding there is gone after the
    // first miss and the index never rewinds. A new title restarts the walk by hand.
    function reload(): void {
        art.currentFallbackIndex = 0;
        art.source = root.bannerUrls[0] ?? "";
    }

    onDeviceChanged: if (String(root.device?.game_appid ?? root.name) !== root._loaded) {
        root._loaded = String(root.device?.game_appid ?? root.name);
        root.reload();
    }

    property string _loaded: ""
    Component.onCompleted: root.reload()
}
