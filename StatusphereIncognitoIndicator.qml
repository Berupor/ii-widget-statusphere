pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.modules.ii.bar
import qs.services
import QtQuick
import QtQuick.Layouts

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
    }

    // A QQC2 ToolTip can't escape the bar's own thin layer-shell strip, so it always
    // ended up clamped back over the icon regardless of offset. StyledPopup (from
    // qs.modules.ii.bar, the same place the battery/resources popups next to this one
    // get it) gets its own layer-shell surface instead
    StyledPopup {
        hoverTarget: root

        ColumnLayout {
            spacing: 4

            StyledPopupHeaderRow {
                icon: "visibility_off"
                label: Statusphere.incognitoLabel()
            }

            StyledText {
                text: Translation.tr("Click to be visible again")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }
}
