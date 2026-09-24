//@ probe statusphere -g 420x420 -s 1500
/**
 * The spare end of the spectrum: uptime, cpu and load, row collapsed and
 * detail expanded, on its own so it reads as restraint rather than emptiness
 * next to a denser pack.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property int now: 1780000000

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-ren",
                    "device_id": "dev-ren",
                    "device_name": "phone",
                    "account_name": "Ren",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.minimal.row,
                        "detail": CardLayouts.presets.minimal.detail
                    },
                    "uptime_hours": 74,
                    "cpu_percent": 8,
                    "load_avg_1m": 0.3,
                    "cpu_count": 4,
                    "memory_used_mb": 3100,
                    "memory_total_mb": 8192
                }
            ],
            "photos": []
        })

    // A generic visual-tree walk, for pinning what a tile actually renders with
    // instead of just the data that went in.
    function findAll(item, pred, out) {
        if (pred(item))
            out.push(item);
        for (const c of item.children ?? [])
            root.findAll(c, pred, out);
        return out;
    }

    function checks() {
        const grids = root.findAll(root, it => it.rowsUsed !== undefined && it.placed !== undefined, []);
        const packedSolid = grids.every(g => g.placed.reduce((sum, p) => sum + p.cols * p.rows, 0) === g.rowsUsed * g.columns);

        return [
            {
                "name": "the minimal pack counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-ren"]),
                "want": true
            },
            {
                "name": "the row drew its detail card open",
                "got": renRow.height > 150,
                "want": true
            },
            {
                "name": "no pack row is left with an empty grid cell",
                "got": grids.length > 0 && packedSolid,
                "want": true
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        PresenceRow {
            id: renRow
            Layout.fillWidth: true
            modelData: "acc-ren"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
