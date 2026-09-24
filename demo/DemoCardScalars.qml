//@ probe statusphere -g 620x420 -s 1500
/**
 * A close-up of the four scalar chart forms at a size where the curve, the
 * bars, the ring gap and the headline value are actually legible - the friend
 * packs only ever show them shrunk into a 1x1/2x1 cell.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property int now: 1780000000

    readonly property var scalarTiles: [
        CardLayouts.tile({
            "type": "scalar",
            "field": "cpu",
            "form": "graph",
            "size": "2x1",
            "color": "primaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "signal",
            "form": "bars",
            "size": "2x1",
            "color": "secondaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "cpu",
            "form": "ring",
            "size": "1x1",
            "color": "tertiaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "sessions",
            "form": "number",
            "size": "1x1",
            "color": "primaryContainer",
            "onMissing": "hide"
        })
    ]

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-scalars",
                    "device_id": "dev-scalars",
                    "device_name": "desktop",
                    "account_name": "Scalars",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": root.scalarTiles,
                        "detail": []
                    },
                    "cpu_percent": 63,
                    "cpu_history": [12, 18, 22, 34, 30, 44, 51, 47, 60, 55, 63, 58],
                    "custom_fields": ["signal", "sessions"],
                    "signal": "82%",
                    "signal_history": [3, 5, 4, 6, 8, 7, 9, 6, 5, 8],
                    "sessions": "128"
                }
            ],
            "photos": []
        })

    function checks() {
        return [
            {
                "name": "graph, bars, ring and number tiles all place on the grid",
                "got": grid.placed.length,
                "want": 4
            },
            {
                "name": "the graph tile reads the cpu history for its curve",
                "got": Statusphere.graphValuesFor(Statusphere.deviceForTile(Statusphere.accountsById["acc-scalars"], root.scalarTiles[0]), "cpu").length,
                "want": 12
            },
            {
                "name": "the ring tile's percent comes from cpu_percent, not the graph history",
                "got": Statusphere.fieldFor(Statusphere.deviceForTile(Statusphere.accountsById["acc-scalars"], root.scalarTiles[2]), "cpu")?.percent,
                "want": 63
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    CardGrid {
        id: grid
        anchors.fill: parent
        anchors.margins: 16
        account: Statusphere.accountsById["acc-scalars"]
        tiles: root.scalarTiles
        maxRows: 2
    }
}
