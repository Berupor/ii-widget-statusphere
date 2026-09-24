//@ probe statusphere -g 420x1200 -s 1500
/**
 * Two friend packs on their own, row collapsed and detail expanded: a night
 * gamer (session timer, an active-hours heatmap, a night clock, a mood sticker)
 * next to a music head (a spinning vinyl, a wave strip, a lyric quote).
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
                    "custom_fields": ["mood", "quote", "genre"],
                    "mood": "🎧",
                    "quote": "Turn it up",
                    "genre": "Synthwave"
                }
            ],
            "photos": []
        })

    function checks() {
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
