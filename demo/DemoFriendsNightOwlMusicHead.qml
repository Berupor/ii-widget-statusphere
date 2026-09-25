//@ probe statusphere -g 420x1200 -s 1500
/**
 * Two friend packs on their own, row collapsed and detail expanded: a night
 * owl (a local clock, what window is open and the moon phase in the row, the
 * game, a wave line, the app, uptime, the night weather, the moon, a clock
 * and sunrise/sunset in the detail) next to a music head (a spinning vinyl,
 * what she's into lately and a clock) with the minimal detail card.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "lib"
import "lib/DemoCovers.js" as DemoCovers
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property int now: 1780000000

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-nyx",
                    "device_id": "dev-nyx",
                    "device_name": "tower",
                    "account_name": "Nyx",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.packs.row.nightOwl,
                        "detail": CardLayouts.packs.detail.nightOwl
                    },
                    "spotify_status": "playing",
                    "spotify_track": "Turn Off the Lights",
                    "spotify_artist": "Nite Jewel",
                    "spotify_position": 40,
                    "spotify_length": 210,
                    "spotify_art_url": DemoCovers.url("nightcall.jpg"),
                    "game_status": "playing",
                    "game_name": "Cyberpunk 2077",
                    "game_display": "Cyberpunk 2077",
                    "game_header_url": DemoCovers.url("cp2077-header.jpg"),
                    "game_session_seconds": 7200,
                    "uptime_hours": 27,
                    "active_app": "mpv",
                    "active_window": "mpv - late_night_mix.mkv",
                    "custom_fields": ["local_time", "weather", "moon", "sun"],
                    "weather": "7° Clear",
                    "local_time": "03:12",
                    "moon": "🌔",
                    "sun": "06:45 · 18:52"
                },
                {
                    "account_id": "acc-echo",
                    "device_id": "dev-echo",
                    "device_name": "laptop",
                    "account_name": "Echo",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.packs.row.musicHead,
                        "detail": CardLayouts.packs.detail.minimal,
                        "avatarShape": CardLayouts.packAvatarShapes.musicHead
                    },
                    "spotify_status": "playing",
                    "spotify_track": "Nightcall",
                    "spotify_artist": "Kavinsky",
                    "spotify_position": 95,
                    "spotify_length": 240,
                    "spotify_art_url": DemoCovers.url("nightcall.jpg"),
                    "custom_fields": ["into_lately", "mood", "local_time", "weather"],
                    "into_lately": "Nightcall on loop",
                    "mood": "🎧 driving home the long way",
                    "local_time": "21:40",
                    "weather": "11° Clear"
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

    // CardTile keeps every form as an always-live sibling and toggles visible per branch,
    // so a property scan needs the ancestor chain checked too, not just the item's own flag.
    function isShown(item) {
        for (let n = item; n && n !== root; n = n.parent) {
            if (n.visible === false)
                return false;
        }
        return true;
    }

    function checks() {
        const grids = root.findAll(root, it => it.rowsUsed !== undefined && it.placed !== undefined, []);
        const packedSolid = grids.every(g => g.placed.reduce((sum, p) => sum + p.cols * p.rows, 0) === g.rowsUsed * g.columns);

        const waveVisualizers = root.findAll(root, it => it.maxVisualizerValue !== undefined, []);
        const waveBars = root.findAll(root, it => it.wavy !== undefined && it.waveFrequency !== undefined && root.isShown(it), []);
        const nyxDevice = Statusphere.musicDevices(Statusphere.accountsById["acc-nyx"])[0];
        const expectedProgress = nyxDevice.spotify_position / nyxDevice.spotify_length;
        const nyxAvatar = root.findAll(nyxRow, it => it.holdProgress !== undefined, [])[0];
        const echoAvatar = root.findAll(echoRow, it => it.holdProgress !== undefined, [])[0];

        return [
            {
                "name": "the night owl pack owns its row and detail",
                "got": ["row", "detail"].map(surface => Statusphere.ownsSurface(Statusphere.accountsById["acc-nyx"], surface)),
                "want": [true, true]
            },
            {
                "name": "a music head row with a minimal detail owns its row and detail",
                "got": ["row", "detail"].map(surface => Statusphere.ownsSurface(Statusphere.accountsById["acc-echo"], surface)),
                "want": [true, true]
            },
            {
                "name": "a layout with no avatarShape keeps the default circle",
                "got": [Statusphere.avatarShapeFor(Statusphere.accountsById["acc-nyx"]), nyxAvatar.shape],
                "want": ["Circle", "Circle"]
            },
            {
                "name": "the music head pack's avatar shape carries through to the row's avatar",
                "got": [Statusphere.avatarShapeFor(Statusphere.accountsById["acc-echo"]), echoAvatar.shape],
                "want": ["SineCookie", "SineCookie"]
            },
            {
                "name": "a SineCookie avatar shape actually draws the wavy shape, not a plain circle",
                "got": root.findAll(echoAvatar, it => it.sides !== undefined && it.visible, []).length,
                "want": 1
            },
            {
                "name": "both rows drew their detail card open",
                "got": nyxRow.height > 200 && echoRow.height > 200,
                "want": true
            },
            {
                "name": "no pack row is left with an empty grid cell",
                "got": grids.length > 0 && packedSolid,
                "want": true
            },
            {
                "name": "the wave form draws a wavy progress line, not a blurred visualizer",
                "got": waveVisualizers.length === 0 && waveBars.length === 1 && waveBars[0].wavy === true,
                "want": true
            },
            {
                "name": "the wave form's progress line reflects spotify_position/spotify_length",
                "got": Math.abs(waveBars[0].value - expectedProgress) < 0.001,
                "want": true
            },
            {
                "name": "Nyx's header says the game her detail card pictures, not the window her row tile shows",
                "got": Statusphere.statusFor(Statusphere.accountsById["acc-nyx"], nyxRow.visibleSurfaces),
                "want": "Playing Cyberpunk 2077 · 2h"
            },
            {
                "name": "sessionFor reads elapsed time, not the calendar day it crossed - pinned just past a manufactured local midnight, not whenever the harness happens to run",
                "got": (() => {
                    const midnight = new Date();
                    midnight.setHours(24, 0, 11, 0); // Rolls over to tomorrow 00:00:11 local
                    const pinned = midnight.getTime();
                    const before = Statusphere._now;
                    Statusphere._now = pinned;
                    const result = [Statusphere.sessionFor(pinned - 13 * 60000), Statusphere.sessionFor(pinned - 25 * 3600000)];
                    Statusphere._now = before;
                    return result;
                })(),
                "want": ["13m", "1d"]
            }
        ];
    }

    DemoCoverSeed {
        onSeeded: Statusphere.ingest(JSON.stringify(root.room))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        PresenceRow {
            id: nyxRow
            Layout.fillWidth: true
            modelData: "acc-nyx"
            showDetails: true
        }

        PresenceRow {
            id: echoRow
            Layout.fillWidth: true
            modelData: "acc-echo"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
