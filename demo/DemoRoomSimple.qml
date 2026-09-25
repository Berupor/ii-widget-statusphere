//@ probe statusphere -g 420x620 -s 1500
/**
 * The room at its plainest, no owner-built layouts at all: one friend playing
 * music with the app she's in named too, one just playing a game, one with
 * nothing more than the window she's in - the built-in row for each case,
 * not a pack - and one gone incognito, so the room says only that she's
 * hidden.
 */
import ".."
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import "lib"
import "lib/DemoCovers.js" as DemoCovers

Item {
    id: root
    readonly property int now: 1780000000

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-mira",
                    "device_id": "dev-mira",
                    "device_name": "workstation",
                    "account_name": "Mira",
                    "last_seen": root.now,
                    "active_app": "discord",
                    "spotify_status": "playing",
                    "spotify_track": "Nightcall",
                    "spotify_artist": "Kavinsky",
                    "spotify_position": 78,
                    "spotify_length": 258,
                    "spotify_art_url": DemoCovers.url("nightcall.jpg")
                },
                {
                    "account_id": "acc-dan",
                    "device_id": "dev-dan",
                    "device_name": "tower",
                    "account_name": "Dan",
                    "last_seen": root.now,
                    "game_status": "playing",
                    "game_name": "Red Dead Redemption 2",
                    "game_display": "Red Dead Redemption 2",
                    "game_header_url": DemoCovers.url("rdr2-header.jpg"),
                    "game_session_seconds": 5040
                },
                {
                    "account_id": "acc-zoe",
                    "device_id": "dev-zoe",
                    "device_name": "laptop",
                    "account_name": "Zoe",
                    "last_seen": root.now,
                    "active_window": "Statusphere - pull requests - Firefox"
                },
                {
                    "account_id": "acc-lena",
                    "device_id": "dev-lena",
                    "device_name": "phone",
                    "account_name": "Lena",
                    "last_seen": root.now,
                    "active_window": "Messages",
                    "_incognito": true
                }
            ],
            "photos": []
        })

    function checks() {
        return [
            {
                "name": "the room is what was fed in",
                "got": [Statusphere.memberCount, Statusphere.onlineCount],
                "want": [4, 4]
            },
            {
                "name": "only the music friend shows a music widget",
                "got": ["acc-mira", "acc-dan", "acc-zoe", "acc-lena"].map(id => Statusphere.musicDevices(Statusphere.accountsById[id]).length > 0),
                "want": [true, false, false, false]
            },
            {
                "name": "only the game friend shows a game widget",
                "got": ["acc-mira", "acc-dan", "acc-zoe", "acc-lena"].map(id => Statusphere.gameDevices(Statusphere.accountsById[id]).length > 0),
                "want": [false, true, false, false]
            },
            {
                "name": "the plain friend's status line names her window, not a bare Online",
                "got": Statusphere.statusFor(Statusphere.accountsById["acc-zoe"]),
                "want": "Statusphere - pull requests - Firefox"
            },
            {
                "name": "an incognito friend says only that she's hidden, window and all",
                "got": [Statusphere.hiddenFor(Statusphere.accountsById["acc-lena"]), Statusphere.statusFor(Statusphere.accountsById["acc-lena"]).includes("Messages")],
                "want": [true, false]
            }
        ];
    }

    DemoCoverSeed {
        onSeeded: Statusphere.ingest(JSON.stringify(root.room))
    }

    PresenceTab {
        anchors.fill: parent
    }
}
