//@ probe statusphere -g 430x900 -s 2000
/**
 * The room drawn with owner-built card layouts: members on the standard layout
 * (no _layout on their device, so they fall back to CardLayouts.standardDetailFor
 * for the detail card and to PresenceRow's own picture/music stack for the row),
 * one per preset, and one fully custom layout exercising a MaterialShape
 * silhouette, a bar tile and a URL background, plus a tile kept (dimmed) and
 * one hidden when its field has no data.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick

Item {
    id: root
    clip: true

    function cover(file) {
        return String(Qt.resolvedUrl(`covers/${file}`));
    }

    readonly property int now: 1780000000

    readonly property var customRow: [
        {
            "type": "scalar",
            "field": "cpu",
            "device": null,
            "form": "bar",
            "size": "4x1",
            "shape": "default",
            "color": "primary",
            "background": {
                "kind": "color",
                "value": "primaryContainer"
            },
            "onMissing": "hide"
        },
        {
            "type": "scalar",
            "field": "mem",
            "device": null,
            "form": "ring",
            "size": "1x1",
            "shape": "Cookie6Sided",
            "color": "secondaryContainer",
            "onMissing": "dim"
        },
        {
            "type": "scalar",
            "field": "region",
            "device": null,
            "form": "text",
            "size": "2x1",
            "shape": "default",
            "color": "primary",
            "background": {
                "kind": "url",
                "value": root.cover("teardrop.jpg")
            },
            "onMissing": "hide"
        },
        {
            "type": "scalar",
            "field": "gpu",
            "device": null,
            "form": "text",
            "size": "1x1",
            "shape": "default",
            "color": "errorContainer",
            "background": {
                "kind": "color",
                "value": "errorContainer"
            },
            "onMissing": "hide"
        },
        {
            "type": "scalar",
            "field": "battery",
            "device": null,
            "form": "number",
            "size": "1x1",
            "shape": "default",
            "color": "tertiaryContainer",
            "background": {
                "kind": "color",
                "value": "tertiaryContainer"
            },
            "onMissing": "dim"
        }
    ]

    readonly property var customDetail: [
        {
            "type": "scalar",
            "field": "cpu",
            "device": null,
            "form": "bar",
            "size": "2x1",
            "shape": "default",
            "color": "primary",
            "background": {
                "kind": "color",
                "value": "primaryContainer"
            },
            "onMissing": "hide"
        },
        {
            "type": "scalar",
            "field": "mem",
            "device": null,
            "form": "number",
            "size": "1x1",
            "shape": "Heart",
            "color": "secondaryContainer",
            "onMissing": "dim"
        },
        {
            "type": "scalar",
            "field": "battery",
            "device": null,
            "form": "ring",
            "size": "1x1",
            "shape": "default",
            "color": "errorContainer",
            "background": {
                "kind": "color",
                "value": "errorContainer"
            },
            "onMissing": "dim"
        },
        {
            "type": "scalar",
            "field": "*",
            "device": null,
            "form": "text",
            "size": "4x1",
            "shape": "default",
            "color": "secondaryContainer",
            "background": {
                "kind": "color",
                "value": "secondaryContainer"
            },
            "onMissing": "hide"
        }
    ]

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-std",
                    "device_id": "dev-std",
                    "device_name": "desktop",
                    "account_name": "Standard Sam",
                    "last_seen": root.now,
                    "cpu_percent": 41,
                    "memory_used_mb": 8000,
                    "memory_total_mb": 16000,
                    "disk_used_percent": 55,
                    "disk_free_gb": 120,
                    "active_workspace": 3,
                    "spotify_status": "playing",
                    "spotify_track": "Standard Track",
                    "spotify_artist": "Standard Artist",
                    "spotify_position": 40,
                    "spotify_length": 200,
                    "spotify_art_url": root.cover("nightcall.jpg")
                },
                {
                    "account_id": "acc-thinkpad",
                    "device_id": "dev-thinkpad",
                    "device_name": "thinkpad",
                    "account_name": "Thinkpad",
                    "last_seen": root.now,
                    "cpu_percent": 8,
                    "cpu_count": 8,
                    "memory_used_mb": 6554,
                    "memory_total_mb": 16384,
                    "disk_used_percent": 18,
                    "disk_free_gb": 781,
                    "load_avg_1m": 1.97,
                    "uptime_hours": 8,
                    "spotify_status": "playing",
                    "spotify_track": "Midnight City",
                    "spotify_artist": "M83",
                    "spotify_position": 90,
                    "spotify_length": 243
                },
                {
                    "account_id": "acc-std-server",
                    "device_id": "dev-std-server",
                    "device_name": "vps-plain",
                    "account_name": "Plain Server",
                    "_kind": "server",
                    "last_seen": root.now,
                    "cpu_percent": 3,
                    "cpu_count": 2,
                    "memory_used_mb": 900,
                    "memory_total_mb": 2048,
                    "disk_used_percent": 47,
                    "disk_free_gb": 21,
                    "load_avg_1m": 0.12,
                    "uptime_hours": 400,
                    "package_count": 412
                },
                {
                    "account_id": "acc-std-desk",
                    "device_id": "dev-std-desk",
                    "device_name": "desk",
                    "account_name": "Desk Dana",
                    "last_seen": root.now,
                    "cpu_percent": 23,
                    "cpu_count": 16,
                    "memory_used_mb": 12000,
                    "memory_total_mb": 32000,
                    "disk_used_percent": 64,
                    "disk_free_gb": 330,
                    "load_avg_1m": 2.4,
                    "uptime_hours": 51,
                    "package_count": 1650,
                    "active_workspace": 2,
                    "active_app": "firefox",
                    "active_window": "Statusphere - pull requests - Mozilla Firefox"
                },
                {
                    "account_id": "acc-std-busy",
                    "device_id": "dev-std-busy",
                    "device_name": "work",
                    "account_name": "Busy Ben",
                    "last_seen": root.now,
                    "cpu_percent": 51,
                    "cpu_count": 8,
                    "memory_used_mb": 7000,
                    "memory_total_mb": 16000,
                    "disk_used_percent": 80,
                    "disk_free_gb": 90,
                    "load_avg_1m": 3.1,
                    "uptime_hours": 3,
                    "active_app": "busy",
                    "custom_fields": ["mood"],
                    "mood": "heads down"
                },
                {
                    "account_id": "acc-music",
                    "device_id": "dev-music",
                    "device_name": "laptop",
                    "account_name": "Melody",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.packs.row.musicHead,
                        "detail": CardLayouts.packs.detail.musicHead
                    },
                    "spotify_status": "playing",
                    "spotify_track": "Preset Track",
                    "spotify_artist": "Preset Artist",
                    "spotify_position": 90,
                    "spotify_length": 240,
                    "spotify_art_url": root.cover("teardrop.jpg"),
                    "custom_fields": ["top_artist", "streak", "quote", "listening", "playlist", "genre"],
                    "top_artist": "Preset Artist",
                    "streak": "9",
                    "quote": "Turn it up",
                    "listening": "31",
                    "playlist": "Neon Drive",
                    "genre": "Synthwave"
                },
                {
                    "account_id": "acc-hardware",
                    "device_id": "dev-hardware",
                    "device_name": "vps-cards-1",
                    "account_name": "Rig",
                    "_kind": "server",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.packs.row.coder,
                        "detail": CardLayouts.packs.detail.coder
                    },
                    "active_window": "nvim - server.go",
                    "active_app": "tmux",
                    "active_workspace": 3,
                    "package_count": 984,
                    "cpu_percent": 63,
                    "memory_used_mb": 11000,
                    "memory_total_mb": 16000
                },
                {
                    "account_id": "acc-gamer",
                    "device_id": "dev-gamer",
                    "device_name": "tower",
                    "account_name": "Gio",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.packs.row.nightOwl,
                        "detail": CardLayouts.packs.detail.nightOwl
                    },
                    "spotify_status": "playing",
                    "spotify_track": "Night Drive",
                    "spotify_artist": "The Midnight",
                    "spotify_position": 60,
                    "spotify_length": 220,
                    "spotify_art_url": root.cover("nightcall.jpg"),
                    "uptime_hours": 31,
                    "custom_fields": ["active_window", "mood"],
                    "active_window": "Discord",
                    "mood": "🌙"
                },
                {
                    "account_id": "acc-custom",
                    "device_id": "dev-custom",
                    "device_name": "workstation",
                    "account_name": "Custom Cara",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": root.customRow,
                        "detail": root.customDetail
                    },
                    "cpu_percent": 38,
                    "memory_used_mb": 6000,
                    "memory_total_mb": 16000,
                    "custom_fields": ["region"],
                    "region": "fra-1"
                },
                {
                    "account_id": "acc-multi",
                    "device_id": "dev-multi-old",
                    "device_name": "old",
                    "account_name": "Multi",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now - 1000,
                        "marker": "old",
                        "row": [],
                        "detail": []
                    },
                    "cpu_percent": 10
                },
                {
                    "account_id": "acc-multi",
                    "device_id": "dev-multi-new",
                    "device_name": "new",
                    "account_name": "Multi",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "marker": "new",
                        "row": [],
                        "detail": []
                    },
                    "cpu_percent": 12
                },
                {
                    "account_id": "acc-probe",
                    "device_id": "dev-probe",
                    "device_name": "probe",
                    "account_name": "Probe",
                    "last_seen": root.now,
                    "custom_fields": ["local_time_day", "local_time_night", "weather_test"],
                    "local_time_day": "13:15",
                    "local_time_night": "02:30",
                    "weather_test": "9° Rain · Lisbon, PT"
                },
                {
                    "account_id": "acc-empty-layout",
                    "device_id": "dev-empty-layout",
                    "device_name": "empty",
                    "account_name": "Empty Layout",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now
                    }
                },
                {
                    "account_id": "acc-bad-tiles",
                    "device_id": "dev-bad-tiles",
                    "device_name": "malformed",
                    "account_name": "Bad Tiles",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": "not-an-array",
                        "detail": [
                            {
                                "type": "bogus",
                                "field": "x"
                            },
                            {
                                "type": "scalar",
                                "field": "cpu",
                                "form": "bar",
                                "size": "2x1"
                            },
                            {
                                "type": "scalar",
                                "field": "mem",
                                "form": "number",
                                "size": "99x99"
                            },
                            {
                                "type": "scalar",
                                "field": "disk",
                                "form": "heatmap",
                                "size": "2x1"
                            }
                        ]
                    }
                },
                {
                    "account_id": "acc-bad-layout-value",
                    "device_id": "dev-bad-layout-value",
                    "device_name": "string-layout",
                    "account_name": "Bad Layout Value",
                    "last_seen": root.now,
                    "_layout": "not-an-object"
                },
                {
                    "account_id": "acc-row-only",
                    "device_id": "dev-row-only",
                    "device_name": "row-only",
                    "account_name": "Row Only",
                    "last_seen": root.now,
                    "cpu_percent": 33,
                    "_layout": {
                        "updated_at": root.now,
                        "row": [
                            {
                                "type": "scalar",
                                "field": "cpu",
                                "form": "number",
                                "size": "1x1"
                            }
                        ]
                    }
                },
                {
                    "account_id": "acc-detail-invalid",
                    "device_id": "dev-detail-invalid",
                    "device_name": "detail-invalid",
                    "account_name": "Detail Invalid",
                    "last_seen": root.now,
                    "cpu_percent": 77,
                    "_layout": {
                        "updated_at": root.now,
                        "detail": [
                            {
                                "type": "bogus",
                                "field": "x"
                            },
                            {
                                "type": "scalar",
                                "field": "mem",
                                "size": "99x99"
                            }
                        ]
                    }
                },
                {
                    "account_id": "acc-detail-only",
                    "device_id": "dev-detail-only",
                    "device_name": "detail-only",
                    "account_name": "Detail Only",
                    "last_seen": root.now,
                    "cpu_percent": 15,
                    "_layout": {
                        "updated_at": root.now,
                        "detail": [
                            {
                                "type": "scalar",
                                "field": "cpu",
                                "form": "ring",
                                "size": "1x1"
                            }
                        ]
                    }
                },
                {
                    "account_id": "acc-empty-row",
                    "device_id": "dev-empty-row",
                    "device_name": "empty-row",
                    "account_name": "Empty Row",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": []
                    }
                }
            ],
            "photos": [
                {
                    "account_id": "acc-gamer",
                    "path": root.cover("sm2-hero.jpg"),
                    "created_at": "2026-08-07T12:00:00Z",
                    "expires_at": "2099-01-01T00:00:00Z"
                },
                {
                    "account_id": "acc-empty-row",
                    "path": root.cover("nightcall.jpg"),
                    "created_at": "2026-08-07T12:00:00Z",
                    "expires_at": "2099-01-01T00:00:00Z"
                }
            ]
        })

    readonly property var standardAccounts: ["acc-std", "acc-thinkpad", "acc-std-server", "acc-std-desk", "acc-std-busy"]

    function standardGrid(accountId) {
        return standardCards.itemAt(root.standardAccounts.indexOf(accountId))?.children[0] ?? null;
    }

    function checks() {
        const grids = root.standardAccounts.map(id => root.standardGrid(id));
        return [
            {
                "name": "the standard detail card packs without holes for every field mix",
                "got": grids.map(g => g ? CardLayouts.emptyCells(g.placed) : -1),
                "want": root.standardAccounts.map(() => 0)
            },
            {
                "name": "the standard detail card shows every field it was given",
                "got": grids.map(g => g ? g.placed.length === g.tiles.length : false),
                "want": root.standardAccounts.map(() => true)
            },
            {
                "name": "no wide tile of the standard detail card holds a single number",
                "got": grids.reduce((wide, g) => wide.concat(g ? g.placed.filter(p => p.rows === 1 && p.cols > 1 && p.tile.form !== "text").map(p => p.tile.field) : []), []),
                "want": []
            },
            {
                "name": "a laptop reporting only metrics gets two full rows",
                "got": root.standardGrid("acc-thinkpad")?.rowsUsed,
                "want": 2
            },
            {
                "name": "no layout on the snapshot falls back to the standard detail tiles",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-std"], "detail").some(t => t.field === "cpu"),
                "want": true
            },
            {
                "name": "a preset applied to a device counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-music"]),
                "want": true
            },
            {
                "name": "the most recently changed device layout wins across an account's devices",
                "got": Statusphere.layoutFor(Statusphere.accountsById["acc-multi"])?.marker,
                "want": "new"
            },
            {
                "name": "a hidden tile with no data drops out, a dimmed one keeps its place",
                "got": probeGrid.placed.length,
                "want": 2
            },
            {
                "name": "every row got drawn",
                "got": rows.count === Statusphere.memberCount && tab.height > 0,
                "want": true
            },
            {
                "name": "a tile's text takes the on-role of its background role, not a hardcoded one",
                "got": contentColorProbe.contentColor,
                "want": Appearance.colors.colOnSecondaryContainer
            },
            {
                "name": "an auto-shaped clock reads sun by day",
                "got": clockDayProbe.resolvedShape,
                "want": "Sunny"
            },
            {
                "name": "an auto-shaped clock reads circle by night",
                "got": clockNightProbe.resolvedShape,
                "want": "Circle"
            },
            {
                "name": "a weather tile pulls the temperature out of the value",
                "got": weatherProbe.numberDisplayValue,
                "want": "9°"
            },
            {
                "name": "a music tile's vinyl and wave forms are not full-bleed, like a scalar tile",
                "got": vinylProbe.fullBleed || waveProbe.fullBleed,
                "want": false
            },
            {
                "name": "a layout with no row/detail keys falls back to empty tiles, not a crash",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-empty-layout"], "row").length === 0 && Statusphere.surfaceTiles(Statusphere.accountsById["acc-empty-layout"], "detail").length === 0,
                "want": true
            },
            {
                "name": "a tile list that is not an array falls back to empty, not a crash",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-bad-tiles"], "row").length === 0,
                "want": true
            },
            {
                "name": "an unknown tile type is dropped, a valid tile next to it is kept",
                "got": (() => {
                    const tiles = Statusphere.surfaceTiles(Statusphere.accountsById["acc-bad-tiles"], "detail");
                    return tiles.every(t => t.type !== "bogus") && tiles.some(t => t.field === "cpu");
                })(),
                "want": true
            },
            {
                "name": "an unknown tile size is dropped",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-bad-tiles"], "detail").every(t => t.field !== "mem"),
                "want": true
            },
            {
                "name": "a retired history form falls back to number instead of vanishing",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-bad-tiles"], "detail").find(t => t.field === "disk")?.form,
                "want": "number"
            },
            {
                "name": "a non-object _layout value is ignored, not a crash",
                "got": Statusphere.layoutFor(Statusphere.accountsById["acc-bad-layout-value"]),
                "want": null
            },
            {
                "name": "a row-only layout still gets the standard detail tiles",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-row-only"], "row").length === 1 && Statusphere.surfaceTiles(Statusphere.accountsById["acc-row-only"], "detail").some(t => t.field === "cpu" && t.form === "ring"),
                "want": true
            },
            {
                "name": "a detail made only of invalid tiles falls back to the standard detail",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-detail-invalid"], "detail").some(t => t.field === "cpu" && t.form === "ring"),
                "want": true
            },
            {
                "name": "a missing row key (detail-only layout) gives friends the default row stack",
                "got": detailOnlyRowProbe.customLayout === false && detailOnlyRowProbe.rowTiles.length === 0,
                "want": true
            },
            {
                "name": "row: [] is owned by the layout, not treated as no row at all",
                "got": Statusphere.ownsSurface(Statusphere.accountsById["acc-empty-row"], "row") && Statusphere.surfaceTiles(Statusphere.accountsById["acc-empty-row"], "row").length === 0,
                "want": true
            },
            {
                "name": "row: [] renders header only, not the default music/photo/game stack",
                "got": emptyRowProbe.hasPhoto === true && emptyRowProbe.customLayout === true && emptyRowProbe.rowTiles.length === 0,
                "want": true
            },
            {
                "name": "row: [] leaves no gap under the header - same height as a stack with nothing to show",
                "got": Math.abs(emptyRowProbe.implicitHeight - detailOnlyRowProbe.implicitHeight) < 1,
                "want": true
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    // Which part the shot frames, the other one sits just outside it.
    // `-p framed=thinkpad` shoots the standard card with its details open.
    property string framed: "room"

    PresenceTab {
        id: tab
        x: root.framed === "room" ? 0 : root.width
        width: root.width
        height: root.height
    }

    PresenceRow {
        x: root.framed === "thinkpad" ? 0 : root.width
        width: root.width
        modelData: "acc-thinkpad"
        showDetails: true
    }

    PresenceRow {
        id: detailOnlyRowProbe
        x: root.width
        width: root.width
        modelData: "acc-detail-only"
    }

    PresenceRow {
        id: emptyRowProbe
        x: root.width
        width: root.width
        modelData: "acc-empty-row"
    }

    Repeater {
        id: standardCards
        model: root.standardAccounts

        delegate: PresenceDetailCard {
            required property string modelData
            visible: false
            width: 400
            account: Statusphere.accountsById[modelData]
        }
    }

    Repeater {
        id: rows
        model: Statusphere.accountIds
        delegate: Item {}
    }

    CardGrid {
        id: probeGrid
        visible: false
        width: 400
        maxRows: 2
        account: Statusphere.accountsById["acc-std"]
        tiles: [
            {
                "type": "scalar",
                "field": "cpu",
                "device": null,
                "form": "text",
                "size": "1x1",
                "shape": "default",
                "color": "primary",
                "background": {
                    "kind": "color",
                    "value": "primaryContainer"
                },
                "onMissing": "hide"
            },
            {
                "type": "scalar",
                "field": "gpu",
                "device": null,
                "form": "text",
                "size": "1x1",
                "shape": "default",
                "color": "secondary",
                "background": {
                    "kind": "color",
                    "value": "secondaryContainer"
                },
                "onMissing": "hide"
            },
            {
                "type": "scalar",
                "field": "battery",
                "device": null,
                "form": "text",
                "size": "1x1",
                "shape": "default",
                "color": "tertiary",
                "background": {
                    "kind": "color",
                    "value": "tertiaryContainer"
                },
                "onMissing": "dim"
            }
        ]
    }

    CardTile {
        id: contentColorProbe
        visible: false
        account: Statusphere.accountsById["acc-std"]
        tile: ({
                "type": "scalar",
                "field": "cpu",
                "device": null,
                "form": "ring",
                "size": "1x1",
                "shape": "default",
                "color": "secondaryContainer",
                "background": {
                    "kind": "color",
                    "value": "secondaryContainer"
                },
                "onMissing": "hide"
            })
    }

    CardTile {
        id: clockDayProbe
        visible: false
        account: Statusphere.accountsById["acc-probe"]
        tile: ({
                "type": "scalar",
                "field": "local_time_day",
                "device": null,
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "tertiaryContainer",
                "background": {
                    "kind": "color",
                    "value": "tertiaryContainer"
                },
                "onMissing": "hide"
            })
    }

    CardTile {
        id: clockNightProbe
        visible: false
        account: Statusphere.accountsById["acc-probe"]
        tile: ({
                "type": "scalar",
                "field": "local_time_night",
                "device": null,
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "tertiaryContainer",
                "background": {
                    "kind": "color",
                    "value": "tertiaryContainer"
                },
                "onMissing": "hide"
            })
    }

    CardTile {
        id: weatherProbe
        visible: false
        account: Statusphere.accountsById["acc-probe"]
        tile: ({
                "type": "scalar",
                "field": "weather_test",
                "device": null,
                "form": "weather",
                "size": "1x1",
                "shape": "auto",
                "color": "primaryContainer",
                "background": {
                    "kind": "color",
                    "value": "primaryContainer"
                },
                "onMissing": "hide"
            })
    }

    CardTile {
        id: vinylProbe
        visible: false
        account: Statusphere.accountsById["acc-music"]
        tile: ({
                "type": "music",
                "field": "",
                "device": null,
                "form": "vinyl",
                "size": "2x2",
                "shape": "default",
                "color": "primaryContainer",
                "background": {
                    "kind": "color",
                    "value": "primaryContainer"
                },
                "onMissing": "hide"
            })
    }

    CardTile {
        id: waveProbe
        visible: false
        account: Statusphere.accountsById["acc-music"]
        tile: ({
                "type": "music",
                "field": "",
                "device": null,
                "form": "wave",
                "size": "2x1",
                "shape": "default",
                "color": "secondaryContainer",
                "background": {
                    "kind": "color",
                    "value": "secondaryContainer"
                },
                "onMissing": "hide"
            })
    }
}
