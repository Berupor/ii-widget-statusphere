//@ probe statusphere -g 420x1200 -s 2500
/**
 * Two more friend packs on their own, row collapsed and detail expanded: a
 * travelling photographer (a shared photo, a local clock and the weather in
 * the row, then the photo and weather large, a clock, sunrise/sunset and a
 * line for where she is in the detail card - no system metrics) next to a
 * coder (what window is open, workspace and cpu in the row, the app, what's
 * playing and a local clock in the detail, package count and load as the
 * accent).
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "../Templates.js" as Templates
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
                        "row": CardLayouts.packs.row.traveler,
                        "detail": CardLayouts.packs.detail.traveler
                    },
                    "custom_fields": ["local_time", "weather", "sun", "where_i_am"],
                    "local_time": "13:15",
                    "weather": "9° Rain · Tokyo, JP",
                    "sun": "05:52 · 17:38",
                    "where_i_am": "Somewhere new, off the map"
                },
                {
                    "account_id": "acc-turing",
                    "device_id": "dev-turing",
                    "device_name": "desktop",
                    "account_name": "Turing",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.packs.row.coder,
                        "detail": CardLayouts.packs.detail.coder
                    },
                    "active_window": "nvim - main.go",
                    "active_app": "kitty",
                    "active_workspace": 4,
                    "package_count": 1523,
                    "cpu_percent": 34,
                    "load_avg_1m": 1.2,
                    "cpu_count": 8,
                    "custom_fields": ["local_time"],
                    "local_time": "16:05",
                    "memory_used_mb": 5200,
                    "memory_total_mb": 16384,
                    "spotify_status": "playing",
                    "spotify_track": "Midnight City",
                    "spotify_artist": "M83",
                    "spotify_position": 120,
                    "spotify_length": 244,
                    "spotify_art_url": root.cover("nightcall.jpg")
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

    readonly property var allPacks: ["row", "detail"].reduce((all, surface) => all.concat(CardLayouts.packsFor(surface).map(p => Object.assign({
                        "surface": surface
                    }, p))), [])

    readonly property var quietDevice: ({
            "cpu_percent": 40,
            "memory_used_mb": 8192,
            "memory_total_mb": 16384,
            "disk_used_percent": 50,
            "disk_free_gb": 100,
            "load_avg_1m": 1.1,
            "cpu_count": 8,
            "uptime_hours": 5,
            "active_workspace": 2,
            "active_window": "Terminal",
            "active_app": "kitty",
            "package_count": 900,
            "custom_fields": ["local_time", "weather", "moon", "sun"],
            "local_time": "10:00",
            "weather": "20° Clear",
            "moon": "🌔",
            "sun": "06:00 · 20:00"
        })
    readonly property var quietAccount: ({
            "id": "quiet-demo",
            "primary": root.quietDevice,
            "devices": [root.quietDevice],
            "offline": false,
            "_photo": null
        })

    function packTextField(tiles) {
        return tiles.find(t => t.type === "scalar" && Statusphere.isCustomFieldKey(t.field) && !Templates.seedsItself(Templates.kind(Templates.kindByForm[t.form])))?.field ?? null;
    }

    function shownOnQuiet(t) {
        return t.onMissing === "dim" || Statusphere.tileHasData(root.quietAccount, t);
    }

    function quietDashes(surface) {
        return CardLayouts.packsFor(surface).filter(p => {
            const textField = root.packTextField(p.tiles);
            return p.tiles.some(t => t.type === "scalar" && t.field !== textField && t.onMissing === "dim" && !Statusphere.tileHasData(root.quietAccount, t));
        }).map(p => p.name);
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
        const captionsOk = ["Somewhere new, off the map"].every(text => {
            const copies = captionTexts.filter(t => t.text === text);
            return copies.length > 0 && copies.every(t => t.wrapMode !== Text.Wrap) && copies.some(t => t.wrapMode === Text.WordWrap);
        });

        return [
            {
                "name": "the traveler pack owns its row and detail",
                "got": ["row", "detail"].map(surface => Statusphere.ownsSurface(Statusphere.accountsById["acc-nomad"], surface)),
                "want": [true, true]
            },
            {
                "name": "the coder pack owns its row and detail",
                "got": ["row", "detail"].map(surface => Statusphere.ownsSurface(Statusphere.accountsById["acc-turing"], surface)),
                "want": [true, true]
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
                "got": notTruncated("1.20 / 8"),
                "want": true
            },
            {
                "name": "a 2x1 text value shrinks to fit instead of eliding",
                "got": notTruncated("nvim - main.go"),
                "want": true
            },
            {
                "name": "no pack tile uses the error role",
                "got": root.allPacks.reduce((all, p) => all.concat(p.tiles), []).filter(t => t.color === "error" || (t.background?.value ?? "") === "error").length,
                "want": 0
            },
            {
                "name": "no field repeats within a pack",
                "got": root.allPacks.filter(p => {
                    const fields = p.tiles.filter(t => t.type === "scalar" && t.field !== "*").map(t => t.field);
                    return new Set(fields).size !== fields.length;
                }).map(p => `${p.surface} ${p.name}`),
                "want": []
            },
            {
                "name": "every pack fits its surface whole, with no holes",
                "got": root.allPacks.filter(p => {
                    const placed = CardLayouts.pack(p.tiles, CardLayouts.rowsFor(p.surface));
                    return placed.length !== p.tiles.length || CardLayouts.emptyCells(placed) !== 0;
                }).map(p => `${p.surface} ${p.name}`),
                "want": []
            },
            {
                "name": "row and detail each offer the five characters",
                "got": [CardLayouts.packsFor("row").map(p => p.name), CardLayouts.packsFor("detail").map(p => p.name)],
                "want": [["Night Owl", "Music Head", "Traveler", "Coder", "Minimal"], ["Night Owl", "Music Head", "Traveler", "Coder", "Minimal"]]
            },
            {
                "name": "on a quiet account with no music, game or photo, every row pack still shows a tile",
                "got": CardLayouts.packsFor("row").filter(p => p.tiles.some(t => root.shownOnQuiet(t))).map(p => p.name),
                "want": CardLayouts.packsFor("row").map(p => p.name)
            },
            {
                "name": "on a quiet account with seeded values, no pack tile dashes except its own text field",
                "got": root.quietDashes("row").concat(root.quietDashes("detail")),
                "want": []
            },
            {
                "name": "Turing's header status does not repeat active_window (row tile) or active_app (detail tile)",
                "got": Statusphere.statusFor(Statusphere.accountsById["acc-turing"], turingRow.visibleSurfaces),
                "want": ""
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
