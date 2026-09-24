//@ probe statusphere -g 620x420 -s 1500
/**
 * A close-up of the scalar forms at a size where the bar fill, the ring gap
 * and the headline value are actually legible - the friend packs only ever
 * show them shrunk into a 1x1/2x1 cell.
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
            "form": "bar",
            "size": "2x1",
            "color": "primaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "mem",
            "form": "ring",
            "size": "1x1",
            "color": "secondaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "load",
            "form": "number",
            "size": "1x1",
            "color": "tertiaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "disk",
            "form": "big",
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
                    "memory_used_mb": 12288,
                    "memory_total_mb": 16384,
                    "load_avg_1m": 2.4,
                    "cpu_count": 8,
                    "disk_used_percent": 47,
                    "disk_free_gb": 120
                }
            ],
            "photos": []
        })

    function checks() {
        return [
            {
                "name": "bar, ring, number and big tiles all place on the grid",
                "got": grid.placed.length,
                "want": 4
            },
            {
                "name": "the bar tile's fill percent comes from cpu_percent",
                "got": Statusphere.fieldFor(Statusphere.deviceForTile(Statusphere.accountsById["acc-scalars"], root.scalarTiles[0]), "cpu")?.percent,
                "want": 63
            },
            {
                "name": "the ring tile's fill percent comes from the memory used/total ratio, not a fixed value",
                "got": Statusphere.fieldFor(Statusphere.deviceForTile(Statusphere.accountsById["acc-scalars"], root.scalarTiles[1]), "mem")?.percent,
                "want": 75
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
