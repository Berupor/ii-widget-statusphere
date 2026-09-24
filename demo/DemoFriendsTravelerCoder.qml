//@ probe statusphere -g 420x1200 -s 2500
/**
 * Two more friend packs on their own, row collapsed and detail expanded: a
 * travelling photographer (a shared photo, a local clock, the weather, a
 * flag and a trip day, then a region, a distance and a caption in the detail
 * card - all custom.json fields, no system metrics) next to a coder (what
 * window and app are open, workspace and package count, cpu and mem as a
 * small accent).
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
                    "custom_fields": ["local_time", "weather", "flag", "trip_day", "region", "distance", "caption"],
                    "local_time": "13:15",
                    "weather": "9° Rain · Tokyo, JP",
                    "flag": "🇯🇵",
                    "trip_day": "42",
                    "region": "JP-13",
                    "distance": "1240 km",
                    "caption": "Somewhere new"
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
                    "active_window": "nvim - main.go",
                    "active_app": "kitty",
                    "active_workspace": 4,
                    "package_count": 1523,
                    "cpu_percent": 34,
                    "memory_used_mb": 5200,
                    "memory_total_mb": 16384
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

        // A tooltip mirrors the same string in an untouched Text alongside the tile's
        // own - only the maximumLineCount: 3 one is the tile, so require no copy wraps
        // mid-word and at least one wraps at word boundaries.
        const captionTexts = root.findAll(root, it => it.wrapMode !== undefined && it.text !== undefined, []);
        const captionsOk = ["Somewhere new"].every(text => {
            const copies = captionTexts.filter(t => t.text === text);
            return copies.length > 0 && copies.every(t => t.wrapMode !== Text.Wrap) && copies.some(t => t.wrapMode === Text.WordWrap);
        });

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
                "name": "a caption tile wraps at word boundaries, not mid-word",
                "got": captionsOk,
                "want": true
            },
            {
                "name": "a weather tile's city caption is not truncated",
                "got": notTruncated("Tokyo, JP"),
                "want": true
            },
            {
                "name": "a 1x1 number value shrinks to fit instead of eliding",
                "got": notTruncated("1240 km"),
                "want": true
            },
            {
                "name": "a 2x1 text value shrinks to fit instead of eliding",
                "got": notTruncated("nvim - main.go"),
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
            },
            {
                "name": "Turing's header status does not repeat active_window (row tile) or active_app (detail tile)",
                "got": Statusphere.statusFor(Statusphere.accountsById["acc-turing"], turingRow.visibleSurfaces),
                "want": "Online"
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
