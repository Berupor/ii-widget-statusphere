pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls

/** Reminder that your room can't see you. Click to come back. */
MouseArea {
    id: root

    property bool shown: Statusphere.hiding && Statusphere.opt("incognitoIndicator")
    visible: shown
    implicitWidth: visible ? icon.implicitWidth : 0
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    onClicked: Statusphere.setIncognito(false, 0)

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        fill: 0 // Outline, like the indicators next to it - filled turns to mush at this size
        text: "visibility_off"
        iconSize: Appearance.font.pixelSize.large // The util buttons next to it, and this glyph is wide already
        color: Appearance.colors.colOnLayer1

        StyledToolTip {
            // Default (0,0) sits right on top of icon, which eats the click meant for
            // root's MouseArea - push it below both icon and root so it can't shadow them
            y: (root.height + icon.height) / 2 + 4
            // Popup's default closePolicy grabs outside presses to dismiss itself, which
            // swallows the click before root ever sees it - this tooltip only ever closes
            // by losing hover, so it has no business intercepting presses at all
            closePolicy: Popup.NoAutoClose
            extraVisibleCondition: false
            alternativeVisibleCondition: root.containsMouse
            text: `${Statusphere.incognitoLabel()}\n${Translation.tr("Click to be visible again")}`
        }
    }
}
