pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import "CardLayouts.js" as CardLayouts

Item {
    id: root
    required property var account
    required property var tiles
    property int maxRows: CardLayouts.rowRows
    property bool thumbnail: false

    readonly property int columns: CardLayouts.columns
    readonly property real spacing: CardLayouts.gap
    readonly property real cellSize: (root.width - (root.columns - 1) * root.spacing) / root.columns

    readonly property var shownTiles: (root.tiles ?? []).map((tile, index) => ({
                "tile": tile,
                "index": index
            })).filter(t => t.tile.onMissing !== "hide" || Statusphere.tileHasData(root.account, t.tile))
    readonly property var placed: CardLayouts.pack(root.shownTiles.map(t => t.tile), root.maxRows).map(p => Object.assign({}, p, {
                "index": root.shownTiles[p.index].index
            }))
    readonly property int rowsUsed: CardLayouts.rowsUsed(root.placed)

    property bool selectable: false
    property int selectedIndex: -1
    signal tileClicked(int index)

    // Drag-to-reorder, editor-only: the grid packs first-fit, so a reorder is just a move
    // in the source array - the caller resolves the drop into an index and splices it.
    property bool reorderable: false
    signal tileMoved(int fromIndex, int toIndex)
    signal tileRemoveRequested(int index)
    property int dragIndex: -1
    property real dragOffsetX: 0
    property real dragOffsetY: 0

    function tileAt(px: real, py: real): var {
        return root.placed.find(p => {
            const left = p.col * (root.cellSize + root.spacing);
            const top = p.row * (root.cellSize + root.spacing);
            const w = p.cols * root.cellSize + (p.cols - 1) * root.spacing;
            const h = p.rows * root.cellSize + (p.rows - 1) * root.spacing;
            return px >= left && px < left + w && py >= top && py < top + h;
        }) ?? null;
    }

    implicitHeight: root.rowsUsed > 0 ? root.rowsUsed * root.cellSize + (root.rowsUsed - 1) * root.spacing : 0

    Repeater {
        model: root.placed

        delegate: CardTile {
            id: cardTile
            required property var modelData
            readonly property bool dragged: root.reorderable && root.dragIndex === cardTile.modelData.index

            account: root.account
            tile: cardTile.modelData.tile
            thumbnail: root.thumbnail
            x: cardTile.modelData.col * (root.cellSize + root.spacing) + (cardTile.dragged ? root.dragOffsetX : 0)
            y: cardTile.modelData.row * (root.cellSize + root.spacing) + (cardTile.dragged ? root.dragOffsetY : 0)
            z: cardTile.dragged ? 10 : 0
            width: cardTile.modelData.cols * root.cellSize + (cardTile.modelData.cols - 1) * root.spacing
            height: cardTile.modelData.rows * root.cellSize + (cardTile.modelData.rows - 1) * root.spacing

            Rectangle {
                visible: root.selectable && root.selectedIndex === cardTile.modelData.index
                anchors.fill: parent
                anchors.margins: -2
                radius: Appearance.rounding.large + 2
                color: "transparent"
                border.width: 2
                border.color: Appearance.colors.colPrimary

                Rectangle {
                    visible: root.reorderable
                    width: 18
                    height: 18
                    radius: 9
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: -6
                    color: Appearance.colors.colError

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 12
                        color: Appearance.colors.colOnError
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tileRemoveRequested(cardTile.modelData.index)
                    }
                }
            }

            MouseArea {
                id: tileMouseArea
                visible: root.selectable
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                property point pressRoot: Qt.point(0, 0)

                onPressed: mouse => {
                    tileMouseArea.pressRoot = tileMouseArea.mapToItem(root, mouse.x, mouse.y);
                    if (root.reorderable)
                        root.dragIndex = cardTile.modelData.index;
                }
                onPositionChanged: mouse => {
                    if (!root.reorderable || root.dragIndex !== cardTile.modelData.index)
                        return;
                    const cur = tileMouseArea.mapToItem(root, mouse.x, mouse.y);
                    root.dragOffsetX = cur.x - tileMouseArea.pressRoot.x;
                    root.dragOffsetY = cur.y - tileMouseArea.pressRoot.y;
                }
                onReleased: mouse => {
                    if (!root.reorderable) {
                        root.tileClicked(cardTile.modelData.index);
                        return;
                    }
                    const cur = tileMouseArea.mapToItem(root, mouse.x, mouse.y);
                    const moved = Math.abs(cur.x - tileMouseArea.pressRoot.x) > 4 || Math.abs(cur.y - tileMouseArea.pressRoot.y) > 4;
                    if (!moved) {
                        root.tileClicked(cardTile.modelData.index);
                    } else {
                        const target = root.tileAt(cur.x, cur.y);
                        if (target && target.index !== cardTile.modelData.index)
                            root.tileMoved(cardTile.modelData.index, target.index);
                        else
                            root.tileClicked(cardTile.modelData.index);
                    }
                    root.dragIndex = -1;
                    root.dragOffsetX = 0;
                    root.dragOffsetY = 0;
                }
            }
        }
    }
}
