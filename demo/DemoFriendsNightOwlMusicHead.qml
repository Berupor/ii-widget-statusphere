//@ probe statusphere -g 420x1200 -s 1500
/**
 * Two friend packs on their own, row collapsed and detail expanded: a night
 * gamer (session timer, an active-hours heatmap, a night clock, a mood sticker)
 * next to a music head (a spinning vinyl, top artist and streak, a lyric
 * quote and a listening heatmap in the detail card).
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
                    "account_id": "acc-nyx",
                    "device_id": "dev-nyx",
                    "device_name": "tower",
                    "account_name": "Nyx",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.nightOwl.row,
                        "detail": CardLayouts.presets.nightOwl.detail
                    },
                    "game_status": "playing",
                    "game_source": "steam",
                    "game_name": "Cyberpunk 2077",
                    "game_display": "Cyberpunk 2077",
                    "game_header_url": root.cover("cp2077-header.jpg"),
                    "game_session_seconds": 6000,
                    "custom_fields": ["active_hours", "local_time", "mood"],
                    "active_hours": "6",
                    "active_hours_history": [0, 1, 3, 6, 5, 2, 4, 6, 3, 1, 0, 0],
                    "local_time": "02:47",
                    "mood": "🌙"
                },
                {
                    "account_id": "acc-echo",
                    "device_id": "dev-echo",
                    "device_name": "laptop",
                    "account_name": "Echo",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.musicHead.row,
                        "detail": CardLayouts.presets.musicHead.detail
                    },
                    "spotify_status": "playing",
                    "spotify_track": "Nightcall",
                    "spotify_artist": "Kavinsky",
                    "spotify_position": 95,
                    "spotify_length": 240,
                    "spotify_art_url": root.cover("nightcall.jpg"),
                    "custom_fields": ["top_artist", "streak", "quote", "genre", "listening", "playlist"],
                    "top_artist": "Kavinsky",
                    "streak": "12",
                    "quote": "Turn it up",
                    "genre": "Synthwave",
                    "listening": "38",
                    "playlist": "Neon Drive",
                    "listening_history": [12, 18, 25, 30, 22, 38, 15]
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
                "name": "the night owl pack counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-nyx"]),
                "want": true
            },
            {
                "name": "the music head pack counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-echo"]),
                "want": true
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
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

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
