//@ probe statusphere -g 430x700 -s 2000
/**
 * The room drawn from made-up data: `ingest` takes the same json line the cli
 * prints, so nothing here is stubbed and the whole pipeline runs. `-p scenario=`
 * picks the state - `plain` is the everyday room, `edge` is everything that has
 * ever looked wrong: long names, a nameless account, a stalled player, a server
 * in bad health, an account with more devices than fit.
 */
import ".." // The widget's own types and its Statusphere singleton, via its qmldir
import qs.modules.common
import QtQuick

Item {
    id: root

    property string scenario: "plain"

    // Art out of demo/covers/, so a shot needs no network and stays the same
    function cover(file) {
        return String(Qt.resolvedUrl(`covers/${file}`));
    }

    readonly property int now: 1780000000
    readonly property var rooms: ({
        "plain": {
            "members": [
                {
                    "account_id": "acc-you",
                    "device_id": "dev-you-laptop",
                    "device_name": "thinkpad",
                    "account_name": "You",
                    "_role": "owner",
                    "last_seen": root.now
                },
                {
                    "account_id": "acc-mira",
                    "device_id": "dev-mira-desk",
                    "device_name": "workstation",
                    "account_name": "Mira",
                    "last_seen": root.now,
                    "spotify_status": "playing",
                    "spotify_track": "Nightcall",
                    "spotify_artist": "Kavinsky",
                    "spotify_position": 78,
                    "spotify_length": 258,
                    "spotify_art_url": root.cover("nightcall.jpg"),
                    "game_status": "playing",
                    "game_source": "steam",
                    "game_appid": "1174180",
                    "game_name": "Red Dead Redemption 2",
                    "game_display": "Red Dead Redemption 2",
                    "game_hero_url": root.cover("rdr2-hero.jpg"),
                    "game_header_url": root.cover("rdr2-header.jpg"),
                    "game_logo_url": root.cover("rdr2-logo.png"),
                    "game_session_seconds": 5040
                },
                {
                    "account_id": "acc-dan",
                    "device_id": "dev-dan-desk",
                    "device_name": "tower",
                    "account_name": "Dan",
                    "last_seen": root.now
                },
                {
                    "account_id": "acc-dan",
                    "device_id": "dev-dan-phone",
                    "device_name": "pixel",
                    "account_name": "Dan",
                    "last_seen": root.now - 5,
                    "spotify_status": "paused",
                    "spotify_track": "Teardrop",
                    "spotify_artist": "Massive Attack",
                    "spotify_position": 12,
                    "spotify_length": 330,
                    "spotify_art_url": root.cover("teardrop.jpg")
                },
                {
                    "account_id": "acc-lena",
                    "account_name": "Lena",
                    "_offline": true
                }
            ],
            "photos": []
        },
        "edge": {
            "members": [
                {
                    "account_id": "acc-long",
                    "device_id": "dev-long",
                    "device_name": "a-very-long-machine-name-that-will-not-fit",
                    "account_name": "Wilhelmina-Josephine Featherstonehaugh-Marchetti",
                    "last_seen": root.now,
                    "spotify_status": "playing",
                    "spotify_track": "A track title long enough to need eliding somewhere",
                    "spotify_artist": "An artist with an equally unreasonable name",
                    "spotify_length": 191,
                    "spotify_position": 190, // A second left, and it never advances
                    "game_status": "playing",
                    "game_source": "steam",
                    "game_appid": "2183900",
                    "game_name": "Warhammer 40,000: Space Marine 2",
                    "game_hero_url": root.cover("sm2-hero.jpg"),
                    "game_header_url": root.cover("sm2-header.jpg"),
                    "game_logo_url": root.cover("sm2-logo.png"),
                    "game_session_seconds": 359999 // The widest the clock ever gets
                },
                {
                    "account_id": "acc-nameless",
                    "device_id": "dev-nameless",
                    "last_seen": root.now,
                    "game_status": "playing",
                    "game_source": "steam",
                    "game_appid": "1091500",
                    "game_name": "Cyberpunk 2077",
                    // No hero for this one: the card has to walk down to the header
                    "game_hero_url": root.cover("no-such-hero.jpg"),
                    "game_header_url": root.cover("cp2077-header.jpg"),
                    "game_session_seconds": 47
                },
                {
                    "account_id": "acc-box",
                    "device_id": "dev-box",
                    "device_name": "vps-fra-1",
                    "account_name": "fra-1",
                    "_kind": "server",
                    "_health": "degraded",
                    "_health_note": "disk almost full",
                    "last_seen": root.now,
                    "cpu_percent": 87.4,
                    "cpu_count": 8,
                    "memory_used_mb": 6100,
                    "memory_total_mb": 8192,
                    "disk_used_percent": 91,
                    "disk_free_gb": 4.2,
                    "uptime_hours": 1320
                },
                {
                    "account_id": "acc-many",
                    "device_id": "dev-many-1",
                    "device_name": "laptop",
                    "account_name": "Six Devices",
                    "last_seen": root.now,
                    // Steam knows the name and nothing else: no banner, just the line
                    "game_status": "playing",
                    "game_source": "steam",
                    "game_name": "A Game Whose Name Is Far Too Long To Fit On One Line",
                    "game_session_seconds": 3600
                },
                {
                    "account_id": "acc-many",
                    "device_id": "dev-many-2",
                    "device_name": "phone",
                    "account_name": "Six Devices",
                    "last_seen": root.now - 200 // Stale enough to rank below the rest
                },
                {
                    "account_id": "acc-many",
                    "device_id": "dev-many-3",
                    "device_name": "tablet",
                    "account_name": "Six Devices",
                    "last_seen": root.now
                },
                {
                    "account_id": "acc-dead-box",
                    "account_name": "ams-2",
                    "_kind": "server",
                    "_offline": true
                }
            ],
            // A photo, a game and music on one card: everything below the photo has
            // to fold into a line, and each folded line needs its own hairline.
            "photos": [
                {
                    "account_id": "acc-long",
                    "path": root.cover("rdr2-hero.jpg"),
                    "created_at": "2026-08-07T12:00:00Z",
                    "expires_at": "2099-01-01T00:00:00Z"
                }
            ]
        }
    })

    readonly property var room: root.rooms[root.scenario] ?? root.rooms.plain

    function checks() {
        const many = Statusphere.accountsById["acc-many"];
        return [
            {
                "name": "the room is what was fed in",
                "got": [Statusphere.memberCount, Statusphere.onlineCount],
                "want": root.scenario === "edge" ? [5, 4] : [4, 3]
            },
            {
                "name": "offline members sort last",
                "got": Statusphere.accountIds[Statusphere.memberCount - 1],
                "want": root.scenario === "edge" ? "acc-dead-box" : "acc-lena"
            },
            {
                "name": "an account with no name falls back to its id",
                "got": root.scenario === "edge" ? Statusphere.nameFor(Statusphere.accountsById["acc-nameless"]) : "",
                "want": root.scenario === "edge" ? "acc-name" : ""
            },
            {
                "name": "a server stays a server, health and all",
                "got": root.scenario === "edge" ? [Statusphere.isServer(Statusphere.accountsById["acc-box"]), Statusphere.healthFor(Statusphere.accountsById["acc-box"])] : [false, ""],
                "want": root.scenario === "edge" ? [true, "degraded"] : [false, ""]
            },
            {
                "name": "the device playing music leads its account",
                "got": root.scenario === "edge" ? (many?.primary?.device_id ?? "") : (Statusphere.accountsById["acc-dan"]?.primary?.device_id ?? ""),
                "want": root.scenario === "edge" ? "dev-many-1" : "dev-dan-phone"
            },
            {
                "name": "a game shows up on the device running it",
                "got": root.scenario === "edge" ? Statusphere.gameDevices(Statusphere.accountsById["acc-nameless"]).length : Statusphere.gameFor(Statusphere.accountsById["acc-mira"]?.primary),
                "want": root.scenario === "edge" ? 1 : "Red Dead Redemption 2"
            },
            {
                "name": "a session reads like a photo's age, and keeps counting past a day",
                "got": [Statusphere.sessionFor(0), Statusphere.sessionFor(Date.now() - 30000), Statusphere.sessionFor(Date.now() - 780000), Statusphere.sessionFor(Date.now() - 5040000), Statusphere.sessionFor(Date.now() - 359999000)],
                "want": ["", "Now", "13m", "1h", "4d"]
            },
            {
                "name": "the status line names the game, so the card is only its picture",
                "got": Statusphere.statusFor(Statusphere.accountsById[root.scenario === "edge" ? "acc-nameless" : "acc-mira"]),
                "want": root.scenario === "edge" ? "Playing Cyberpunk 2077 · Now" : "Playing Red Dead Redemption 2 · 1h"
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

        readonly property var rowsRepeater: null
    }

    // The tab builds its own rows; this one only counts them for the checks above
    Repeater {
        id: rows
        model: Statusphere.accountIds
        delegate: Item {}
    }
}
