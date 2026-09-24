pragma ComponentBehavior: Bound

import qs.services
import QtQuick

/** Owner-built tile grid: always 4 columns, cell size follows the viewer's width. */
Item {
    id: root
    required property var account
    required property var tiles
    property int maxRows: 2

    readonly property int columns: 4
    readonly property real spacing: 8
    readonly property real cellSize: (root.width - (root.columns - 1) * root.spacing) / root.columns

    function tileSpan(sizeKey): var {
        switch (sizeKey) {
        case "2x1":
            return {
                "cols": 2,
                "rows": 1
            };
        case "2x2":
            return {
                "cols": 2,
                "rows": 2
            };
        case "4x1":
            return {
                "cols": 4,
                "rows": 1
            };
        default:
            return {
                "cols": 1,
                "rows": 1
            };
        }
    }

    function fits(occupied, col, row, cols, rows): bool {
        if (col + cols > root.columns || row + rows > root.maxRows)
            return false;
        for (let r = row; r < row + rows; r++) {
            for (let c = col; c < col + cols; c++) {
                if (occupied[r]?.[c])
                    return false;
            }
        }
        return true;
    }

    function occupy(occupied, col, row, cols, rows): void {
        for (let r = row; r < row + rows; r++) {
            if (!occupied[r])
                occupied[r] = [];
            for (let c = col; c < col + cols; c++)
                occupied[r][c] = true;
        }
    }

    // First-fit top-left packing: a tile with nowhere left to go is dropped
    // rather than overflowing maxRows, so a full grid degrades instead of clipping.
    function pack(tiles): var {
        const occupied = [];
        const placed = [];
        for (const t of tiles ?? []) {
            if (t.onMissing === "hide" && !Statusphere.tileHasData(root.account, t))
                continue;
            const span = root.tileSpan(t.size);
            let spot = null;
            for (let r = 0; r + span.rows <= root.maxRows && !spot; r++) {
                for (let c = 0; c + span.cols <= root.columns && !spot; c++) {
                    if (root.fits(occupied, c, r, span.cols, span.rows))
                        spot = {
                            "col": c,
                            "row": r
                        };
                }
            }
            if (!spot)
                continue;
            root.occupy(occupied, spot.col, spot.row, span.cols, span.rows);
            placed.push({
                "tile": t,
                "col": spot.col,
                "row": spot.row,
                "cols": span.cols,
                "rows": span.rows
            });
        }
        return placed;
    }

    readonly property var placed: root.pack(root.tiles)
    readonly property int rowsUsed: root.placed.reduce((max, p) => Math.max(max, p.row + p.rows), 0)

    implicitHeight: root.rowsUsed > 0 ? root.rowsUsed * root.cellSize + (root.rowsUsed - 1) * root.spacing : 0

    Repeater {
        model: root.placed

        delegate: CardTile {
            id: cardTile
            required property var modelData

            account: root.account
            tile: cardTile.modelData.tile
            x: cardTile.modelData.col * (root.cellSize + root.spacing)
            y: cardTile.modelData.row * (root.cellSize + root.spacing)
            width: cardTile.modelData.cols * root.cellSize + (cardTile.modelData.cols - 1) * root.spacing
            height: cardTile.modelData.rows * root.cellSize + (cardTile.modelData.rows - 1) * root.spacing
        }
    }
}
