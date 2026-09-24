//@ probe statusphere -g 430x900 -s 3000
/**
 * The room drawn with owner-built card layouts: members on the standard layout
 * (no _layout on their device, so they fall back to CardLayouts.standardDetailFor
 * for the detail card and to PresenceRow's own picture/music stack for the row),
 * one per pack, and one fully custom layout exercising a MaterialShape
 * silhouette, a bar tile and a URL background, plus a tile kept (dimmed) and
 * one hidden when its field has no data.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import qs.modules.common.widgets
import Quickshell
import QtQuick

Item {
    id: root
    clip: true

    function cover(file) {
        return String(Qt.resolvedUrl(`covers/${file}`));
    }

    readonly property int now: 1780000000

    readonly property string pictureUrl: "https://upload.wikimedia.org/wikipedia/commons/3/3f/JPEG_example_flower.jpg"
    readonly property var notHttpsUrls: ["http://example.org/a.jpg", "ftp://example.org/a.jpg", "file:///etc/hostname", "javascript:alert(1)", "https://", " https://example.org/a.jpg", 42]
    readonly property var photoBackground: ({
            "kind": "live",
            "value": "photo"
        })

    readonly property var pictureRow: [
        CardLayouts.tile({
            "type": "picture",
            "url": root.pictureUrl,
            "size": "2x1"
        }),
        CardLayouts.tile({
            "type": "picture",
            "url": root.pictureUrl,
            "size": "1x1",
            "shape": "Cookie9Sided"
        }),
        CardLayouts.tile({
            "type": "picture",
            "url": "http://example.org/a.jpg",
            "size": "1x1",
            "onMissing": "dim"
        })
    ]

    readonly property var pictureDetail: [
        CardLayouts.tile({
            "type": "scalar",
            "field": "active_window",
            "form": "text",
            "size": "2x1",
            "background": root.photoBackground
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "cpu",
            "form": "number",
            "size": "1x1",
            "shape": "Cookie9Sided",
            "background": root.photoBackground
        }),
        CardLayouts.tile({
            "type": "photo",
            "size": "1x1"
        }),
        CardLayouts.tile({
            "type": "picture",
            "url": "ftp://example.org/a.jpg",
            "size": "1x1"
        }),
        CardLayouts.tile({
            "type": "picture",
            "url": root.pictureUrl,
            "size": "2x2",
            "shape": "Circle"
        }),
        CardLayouts.tile({
            "type": "picture",
            "url": root.pictureUrl,
            "size": "4x1"
        })
    ]

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
                                "size": "2x1",
                                "background": {
                                    "kind": "color",
                                    "value": "primaryContainer"
                                }
                            },
                            {
                                "type": "scalar",
                                "field": "mem",
                                "form": "number",
                                "size": "99x99"
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
                },
                {
                    "account_id": "acc-pictures",
                    "device_id": "dev-pictures",
                    "device_name": "pictures",
                    "account_name": "Pictures",
                    "last_seen": root.now,
                    "cpu_percent": 42,
                    "active_window": "Firefox",
                    "_layout": {
                        "updated_at": root.now,
                        "row": root.pictureRow,
                        "detail": root.pictureDetail
                    }
                }
            ],
            "photos": [
                {
                    "account_id": "acc-pictures",
                    "path": root.cover("rdr2-hero.jpg"),
                    "created_at": "2026-08-07T12:00:00Z",
                    "expires_at": "2099-01-01T00:00:00Z"
                },
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

    function findAll(item, pred, out) {
        if (!item)
            return out;
        if (pred(item))
            out.push(item);
        for (const c of item.children ?? [])
            root.findAll(c, pred, out);
        return out;
    }

    function tilesIn(item) {
        return root.findAll(item, it => it.tile !== undefined && it.hasArt !== undefined, []);
    }

    function vinylCover(tile) {
        return root.findAll(tile, it => Array.from(it.children ?? []).some(c => c.cacheFilePath !== undefined) && it.layer.enabled, [])[0] ?? null;
    }

    function shownVinyls() {
        return root.tilesIn(tab).filter(t => t.tile.form === "vinyl" && t.visible).concat([vinylProbe]);
    }

    // Rotation read a second apart: a spinning cover has moved, a paused one has not
    property var earlyRotations: []

    Timer {
        running: true
        interval: 1000
        onTriggered: root.earlyRotations = root.shownVinyls().map(t => root.vinylCover(t)?.rotation ?? null)
    }

    function spun() {
        return root.shownVinyls().map((t, i) => {
            const now = root.vinylCover(t)?.rotation ?? null;
            return now !== null && root.earlyRotations[i] !== null && now !== root.earlyRotations[i];
        });
    }

    function waving(tile) {
        return root.findAll(tile, it => it.animateWave !== undefined && it.valueBarHeight !== undefined, []).map(b => b.wavy && b.animateWave);
    }

    function detailCardsIn(row) {
        return root.findAll(row, it => it.tiles !== undefined && it.account !== undefined && it.maxRows === undefined, []).length;
    }

    function pictureTiles() {
        return root.findAll(picturesRow, it => it.tile !== undefined && it.hasArt !== undefined && it.visible, []);
    }

    function pictureTile(pred) {
        return root.pictureTiles().find(t => pred(t.tile)) ?? null;
    }

    function shownImages(tile) {
        return root.findAll(tile, it => it.sourceSize !== undefined && it.status !== undefined && String(it.source).length > 0, []);
    }

    function tileArtOf(item) {
        let it = item;
        while (it && it.objectName !== "tileArt")
            it = it.parent;
        return it;
    }

    function maskShapeOf(tile) {
        const art = root.findAll(tile, it => it.objectName === "tileArt", [])[0];
        const mask = art?.layer.enabled ? root.findAll(tile, it => it.objectName === "tileArtMask", [])[0] : null;
        const shown = mask ? Array.from(mask.children).filter(c => c.opacity > 0) : [];
        if (shown.length !== 1)
            return null;
        return shown[0].shape !== undefined ? shown[0].shape : `radius ${shown[0].radius}`;
    }

    function drawnThroughTileMask(tile) {
        const images = root.shownImages(tile);
        const scrims = root.findAll(tile, it => it.visible && it.color !== undefined && it.opacity > 0 && it.opacity < 1 && it.width === tile.width && it.height === tile.height, []);
        return images.length > 0 && images.concat(scrims).every(it => root.tileArtOf(it) !== null);
    }

    readonly property real devicePixelRatio: (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1

    function decodedWithinTile(tile) {
        const image = root.shownImages(tile)[0];
        if (!image)
            return null;
        return image.sourceSize.width > 0 && image.sourceSize.height > 0 && image.sourceSize.width <= Math.ceil(tile.width * root.devicePixelRatio) && image.sourceSize.height <= Math.ceil(tile.height * root.devicePixelRatio);
    }

    readonly property var maskedTiles: ({
            "photoBackgroundRounded": t => t.type === "scalar" && t.field === "active_window",
            "photoBackgroundCookie": t => t.type === "scalar" && t.field === "cpu",
            "photoTile": t => t.type === "photo",
            "pictureRounded": t => t.type === "picture" && t.size === "2x1",
            "pictureCircle": t => t.type === "picture" && t.shape === "Circle"
        })
    function checks() {
        const grids = root.standardAccounts.map(id => root.standardGrid(id));
        return [
            {
                "name": "a picture tile keeps an https url through sanitizeTile",
                "got": Statusphere.sanitizeTile({
                    "type": "picture",
                    "url": root.pictureUrl,
                    "size": "2x1"
                })?.url,
                "want": root.pictureUrl
            },
            {
                "name": "a picture tile's url that is not https is blanked, the tile itself stays",
                "got": root.notHttpsUrls.map(url => Statusphere.sanitizeTile({
                        "type": "picture",
                        "url": url
                    })).map(t => [t?.type, t?.url]),
                "want": root.notHttpsUrls.map(() => ["picture", ""])
            },
            {
                "name": "an https picture renders the image straight from its url",
                "got": root.pictureTiles().filter(t => t.tile.type === "picture" && t.tile.url === root.pictureUrl).map(t => root.shownImages(t).map(i => String(i.source))),
                "want": [[root.pictureUrl], [root.pictureUrl], [root.pictureUrl], [root.pictureUrl]]
            },
            {
                "name": "an https picture is decoded no larger than its tile, in 2x1, 1x1, 2x2 and 4x1",
                "got": root.pictureTiles().filter(t => t.tile.type === "picture" && t.tile.url === root.pictureUrl).map(t => [t.tile.size, root.decodedWithinTile(t)]).sort(),
                "want": [["1x1", true], ["2x1", true], ["2x2", true], ["4x1", true]]
            },
            {
                "name": "a picture that is not https renders missing: dimmed with no image when kept, dropped when hidden",
                "got": [(() => {
                        const t = root.pictureTile(t => t.type === "picture" && t.onMissing === "dim");
                        return t ? [t.hasData, t.dimmed, root.shownImages(t).length] : null;
                    })(), root.pictureTiles().some(t => t.tile.type === "picture" && t.tile.onMissing === "hide" && t.tile.url === "")],
                "want": [[false, true, 0], false]
            },
            {
                "name": "the shared photo tile still shows the account's current photo, not a url",
                "got": (() => {
                    const t = root.pictureTile(t => t.type === "photo");
                    const art = t ? root.findAll(t, it => it.photo !== undefined && it.url !== undefined, [])[0] : null;
                    return art ? [art.photo?.path, art.url, root.shownImages(t).length] : null;
                })(),
                "want": [root.cover("rdr2-hero.jpg"), "", 1]
            },
            {
                "name": "photo backgrounds, the photo tile and the picture tile draw their image and scrim inside the tile's art layer",
                "got": Object.keys(root.maskedTiles).map(key => {
                    const t = root.pictureTile(root.maskedTiles[key]);
                    return [key, t ? root.drawnThroughTileMask(t) : null];
                }),
                "want": Object.keys(root.maskedTiles).map(key => [key, true])
            },
            {
                "name": "the art layer is masked by the tile's own shape: a rounded rect for default, the MaterialShape otherwise",
                "got": Object.keys(root.maskedTiles).map(key => {
                    const t = root.pictureTile(root.maskedTiles[key]);
                    return [key, t ? root.maskShapeOf(t) : null];
                }),
                "want": Object.keys(root.maskedTiles).map(key => {
                    const t = root.pictureTile(root.maskedTiles[key]);
                    return [key, !t ? "no tile" : t.tile.shape === "default" ? `radius ${Appearance.rounding.large}` : MaterialShape.Shape[t.tile.shape]];
                })
            },
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
                "name": "a preset applied to a device owns its row and detail",
                "got": ["row", "detail"].map(surface => Statusphere.ownsSurface(Statusphere.accountsById["acc-music"], surface)),
                "want": [true, true]
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
                "name": "a weather tile pulls the temperature out of the value and captions it with the city",
                "got": root.findAll(weatherProbe, it => it.text !== undefined && it.font !== undefined, []).map(it => it.text),
                "want": ["Lisbon, PT", "9°"]
            },
            {
                "name": "a ring tile builds only its ring: no music, game or cover art behind it",
                "got": (() => {
                    const ring = root.tilesIn(thinkpadRow).find(t => t.tile.form === "ring");
                    return ring ? root.findAll(ring, it => it.stackedCount !== undefined || it.bannerUrls !== undefined || it.cacheFilePath !== undefined, []).length : -1;
                })(),
                "want": 0
            },
            {
                "name": "a vinyl tile spins while its friend plays and it is on screen, a hidden one stands still",
                "got": root.spun(),
                "want": [true, false]
            },
            {
                "name": "a hidden wave tile of a playing friend does not animate its wave",
                "got": root.waving(waveProbe),
                "want": [false]
            },
            {
                "name": "a row builds its detail card only while the details are open",
                "got": [root.detailCardsIn(detailOnlyRowProbe), root.detailCardsIn(emptyRowProbe), root.detailCardsIn(thinkpadRow)],
                "want": [0, 0, 1]
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
                "name": "a colour background from an old layout is dropped, the tile's own colour paints it",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-bad-tiles"], "detail").find(t => t.field === "cpu")?.background,
                "want": undefined
            },
            {
                "name": "an unknown tile size is dropped",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-bad-tiles"], "detail").every(t => t.field !== "mem"),
                "want": true
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
        id: thinkpadRow
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
        id: picturesRow
        x: root.framed === "pictures" ? 0 : root.width
        width: root.width
        modelData: "acc-pictures"
        showDetails: true
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
