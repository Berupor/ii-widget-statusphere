pragma ComponentBehavior: Bound

import qs.services
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** Right-click-expanded details: the account's detail-surface tile grid, custom or standard. */
Item {
    id: root
    required property var account

    readonly property var tiles: Statusphere.surfaceTiles(root.account, "detail")

    implicitHeight: grid.implicitHeight

    CardGrid {
        id: grid
        anchors {
            left: parent.left
            right: parent.right
        }
        account: root.account
        tiles: root.tiles
        maxRows: CardLayouts.detailRows
    }
}
