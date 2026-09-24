//@ probe statusphere -g 430x900 -s 2000
/**
 * The room drawn with owner-built card layouts: one member on the standard
 * layout (no _layout on its device, so it falls back to CardLayouts.standardDetail
 * for the detail card and to PresenceRow's own picture/music stack for the row),
 * one per preset, and one fully custom layout exercising a MaterialShape
 * silhouette, a graph tile and a URL background, plus a tile kept (dimmed) and
 * one hidden when its field has no data.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick

Item {
    id: root

    function cover(file) {
        return String(Qt.resolvedUrl(`covers/${file}`));
    }

    readonly property int now: 1780000000

    readonly property var customRow: [
        {
            "type": "scalar",
            "field": "cpu",
            "device": null,
            "form": "graph",
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
                    "account_id": "acc-music",
                    "device_id": "dev-music",
                    "device_name": "laptop",
                    "account_name": "Melody",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.music.row,
                        "detail": CardLayouts.presets.music.detail
                    },
                    "cpu_percent": 22,
                    "memory_used_mb": 4000,
                    "memory_total_mb": 16000,
                    "spotify_status": "playing",
                    "spotify_track": "Preset Track",
                    "spotify_artist": "Preset Artist",
                    "spotify_position": 90,
                    "spotify_length": 240,
                    "spotify_art_url": root.cover("teardrop.jpg")
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
                        "row": CardLayouts.presets.hardware.row,
                        "detail": CardLayouts.presets.hardware.detail
                    },
                    "cpu_percent": 63,
                    "cpu_history": [12, 18, 22, 30, 44, 51, 47, 60, 55, 63, 58, 63],
                    "cpu_count": 8,
                    "memory_used_mb": 11000,
                    "memory_total_mb": 16000,
                    "disk_used_percent": 47,
                    "disk_free_gb": 210
                },
                {
                    "account_id": "acc-gamer",
                    "device_id": "dev-gamer",
                    "device_name": "tower",
                    "account_name": "Gio",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.gamer.row,
                        "detail": CardLayouts.presets.gamer.detail
                    },
                    "cpu_percent": 71,
                    "memory_used_mb": 9000,
                    "memory_total_mb": 16000,
                    "game_status": "playing",
                    "game_source": "steam",
                    "game_appid": "1174180",
                    "game_name": "Red Dead Redemption 2",
                    "game_display": "Red Dead Redemption 2",
                    "game_hero_url": root.cover("rdr2-hero.jpg"),
                    "game_header_url": root.cover("rdr2-header.jpg"),
                    "game_logo_url": root.cover("rdr2-logo.png"),
                    "game_session_seconds": 2400
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
                    "cpu_history": [5, 9, 14, 12, 20, 25, 22, 30, 28, 35, 33, 38],
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
                }
            ],
            "photos": [
                {
                    "account_id": "acc-gamer",
                    "path": root.cover("sm2-hero.jpg"),
                    "created_at": "2026-08-07T12:00:00Z",
                    "expires_at": "2099-01-01T00:00:00Z"
                }
            ]
        })

    function checks() {
        return [
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
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    PresenceTab {
        id: tab
        anchors.fill: parent
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
}
