//@ probe statusphere -g 420x1200 -s 2500
/**
 * Two more friend packs on their own, row collapsed and detail expanded: a
 * travelling photographer (a shared photo plus cpu, load, mem and uptime
 * accents) next to a coder (disk, cpu and workspace in the row, mem, uptime
 * and load in the detail card - the one pack that leans on the hardware
 * catalog as its centerpiece rather than an accent).
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    function cover(file) {
        return String(Qt.resolvedUrl(`covers/${file}`));
    }

    readonly property int now: 1780000000

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-nomad",
                    "device_id": "dev-nomad",
                    "device_name": "phone",
                    "account_name": "Nomad",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.traveler.row,
                        "detail": CardLayouts.presets.traveler.detail
                    },
                    "cpu_percent": 58,
                    "load_avg_1m": 2.1,
                    "cpu_count": 6,
                    "memory_used_mb": 9000,
                    "memory_total_mb": 16384,
                    "uptime_hours": 5,
                    "disk_used_percent": 63,
                    "disk_free_gb": 90,
                    "active_workspace": 7
                },
                {
                    "account_id": "acc-turing",
                    "device_id": "dev-turing",
                    "device_name": "desktop",
                    "account_name": "Turing",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.coder.row,
                        "detail": CardLayouts.presets.coder.detail
                    },
                    "cpu_percent": 34,
                    "memory_used_mb": 5200,
                    "memory_total_mb": 16384,
                    "active_workspace": 4,
                    "uptime_hours": 3,
                    "disk_used_percent": 47,
                    "disk_free_gb": 210,
                    "load_avg_1m": 1.4,
                    "cpu_count": 8
                }
            ],
            "photos": [
                {
                    "account_id": "acc-nomad",
                    "path": root.cover("teardrop.jpg"),
                    "created_at": "2026-09-20T12:00:00Z",
                    "expires_at": "2099-01-01T00:00:00Z"
                }
            ]
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

        const valueTexts = root.findAll(root, it => it.truncated !== undefined, []);
        const notTruncated = text => {
            const copies = valueTexts.filter(t => t.text === text);
            return copies.length > 0 && copies.every(t => !t.truncated);
        };

        return [
            {
                "name": "the traveler pack counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-nomad"]),
                "want": true
            },
            {
                "name": "the coder pack counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-turing"]),
                "want": true
            },
            {
                "name": "both rows drew their detail card open",
                "got": nomadRow.height > 200 && turingRow.height > 200,
                "want": true
            },
            {
                "name": "no pack row is left with an empty grid cell",
                "got": grids.length > 0 && packedSolid,
                "want": true
            },
            {
                "name": "a 1x1 number value shrinks to fit instead of eliding",
                "got": notTruncated("2.10 / 6"),
                "want": true
            },
            {
                "name": "a 2x1 text value shrinks to fit instead of eliding",
                "got": notTruncated("47%"),
                "want": true
            },
            {
                "name": "no pack tile uses the error role",
                "got": CardLayouts.names().every(n => {
                    const p = CardLayouts.get(n);
                    return [...p.row, ...p.detail].every(t => t.color !== "error" && (t.background?.value ?? "") !== "error");
                }),
                "want": true
            },
            {
                "name": "no field repeats within a pack across row and detail",
                "got": CardLayouts.names().every(n => {
                    const p = CardLayouts.get(n);
                    const fields = [...p.row, ...p.detail].filter(t => t.type === "scalar" && t.field !== "*").map(t => t.field);
                    return new Set(fields).size === fields.length;
                }),
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
            id: nomadRow
            Layout.fillWidth: true
            modelData: "acc-nomad"
            showDetails: true
        }

        PresenceRow {
            id: turingRow
            Layout.fillWidth: true
            modelData: "acc-turing"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
