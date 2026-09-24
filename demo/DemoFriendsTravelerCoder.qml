//@ probe statusphere -g 420x1200 -s 2500
/**
 * Two more friend packs on their own, row collapsed and detail expanded: a
 * travelling photographer (local clock, weather, a shared photo) next to a
 * coder (current project, a commit heatmap, a small cpu accent - the one
 * pack that reaches into the hardware catalog, and not as its centerpiece).
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
                    "weather": "9° Rain · Lisbon, PT",
                    "custom_fields": ["local_time", "flag", "region", "trip_day", "caption", "distance"],
                    "local_time": "13:15",
                    "flag": "🇵🇹",
                    "region": "PT-11",
                    "trip_day": "42",
                    "caption": "Somewhere new",
                    "distance": "1240 km"
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
                    "custom_fields": ["project", "commits", "focus", "note", "language"],
                    "project": "statusphere · nvim",
                    "commits": "5",
                    "commits_history": [1, 0, 3, 2, 4, 1, 5],
                    "focus": "45%",
                    "note": "Refactoring the tile grid",
                    "language": "TypeScript"
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
        const captionTexts = root.findAll(root, it => it.wrapMode !== undefined && it.text !== undefined, []);
        // A tooltip mirrors the same string in an untouched Text alongside the tile's
        // own - only the maximumLineCount: 3 one is the tile, so require no copy wraps
        // mid-word and at least one wraps at word boundaries.
        const captionsOk = ["Somewhere new", "Refactoring the tile grid"].every(text => {
            const copies = captionTexts.filter(t => t.text === text);
            return copies.length > 0 && copies.every(t => t.wrapMode !== Text.Wrap) && copies.some(t => t.wrapMode === Text.WordWrap);
        });

        const heatmaps = root.findAll(root, it => it.packing !== undefined, []);
        const commitsDots = heatmaps.find(h => h.count === 7);

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
                "name": "a caption tile wraps at word boundaries, not mid-word",
                "got": captionsOk,
                "want": true
            },
            {
                "name": "no pack row is left with an empty grid cell",
                "got": grids.length > 0 && packedSolid,
                "want": true
            },
            {
                "name": "the commits heatmap sizes its dots to fill the tile, not a fixed square grid",
                "got": commitsDots ? Math.max(commitsDots.packing.size * commitsDots.cols / commitsDots.width, commitsDots.packing.size * commitsDots.rows / commitsDots.height) > 0.85 : false,
                "want": true
            },
            {
                "name": "a 1x1 number value shrinks to fit instead of eliding",
                "got": notTruncated("1240 km"),
                "want": true
            },
            {
                "name": "a 2x1 text value shrinks to fit instead of eliding",
                "got": notTruncated("TypeScript"),
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
