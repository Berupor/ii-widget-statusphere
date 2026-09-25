//@ probe statusphere -g 960x900 -s 2500
/**
 * The README hero: five friends, each a different shape of the same room -
 * a night owl (clock over a GIF, window, moon), a music head (spinning vinyl), a
 * traveler (a shared photo next to a live weather tile, sun over Barcelona),
 * a coder (cpu ring, workspace number) and a friend just playing a game,
 * cover art and all, on the built-in row nobody had to design. Rows stay
 * collapsed - the point is reading the room at a glance, not every tile it owns.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property int now: 1780000000

    function cover(file) {
        return String(Qt.resolvedUrl(`covers/${file}`));
    }

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-nyx",
                    "device_id": "dev-nyx",
                    "device_name": "tower",
                    "account_name": "Nyx",
                    "last_seen": root.now,
                    "active_window": "mpv - late_night_mix.mkv",
                    "active_app": "mpv",
                    "_layout": {
                        "updated_at": root.now,
                        "row": [
                            Object.assign({}, CardLayouts.packs.row.nightOwl[0], {
                                "shape": "default",
                                "background": {
                                    "kind": "url",
                                    "value": root.cover("death-note-l.gif")
                                }
                            }),
                            CardLayouts.packs.row.nightOwl[1],
                            CardLayouts.packs.row.nightOwl[2]
                        ]
                    },
                    "custom_fields": ["local_time", "moon"],
                    "local_time": "03:12",
                    "moon": "🌔"
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
                        "avatarShape": CardLayouts.packAvatarShapes.musicHead
                    },
                    "spotify_status": "playing",
                    "spotify_track": "Nightcall",
                    "spotify_artist": "Kavinsky",
                    "spotify_position": 95,
                    "spotify_length": 240,
                    "spotify_art_url": root.cover("nightcall.jpg"),
                    "custom_fields": ["into_lately", "local_time"],
                    "into_lately": "Nightcall on loop",
                    "local_time": "21:40"
                },
                {
                    "account_id": "acc-nomad",
                    "device_id": "dev-nomad",
                    "device_name": "phone",
                    "account_name": "Wren",
                    "last_seen": root.now,
                    "active_window": "Photos - Barcelona",
                    "_layout": {
                        "updated_at": root.now,
                        "row": [
                            CardLayouts.packs.row.traveler[0],
                            CardLayouts.packs.row.traveler[1],
                            CardLayouts.tile({
                                "type": "scalar",
                                "field": "weather",
                                "form": "weatherLive",
                                "size": "1x1",
                                "shape": "auto",
                                "color": "primaryContainer",
                                "onMissing": "hide"
                            })
                        ]
                    },
                    "custom_fields": ["local_time", "weather"],
                    "local_time": "13:15",
                    "weather": "22;113;0;8;200;1;28;Waxing Crescent;390;1170;720;Barcelona"
                },
                {
                    "account_id": "acc-turing",
                    "device_id": "dev-turing",
                    "device_name": "desktop",
                    "account_name": "Turing",
                    "last_seen": root.now,
                    "active_window": "nvim - main.go",
                    "active_app": "nvim",
                    "active_workspace": 4,
                    "cpu_percent": 34,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.packs.row.coder,
                        "avatarShape": CardLayouts.packAvatarShapes.coder
                    }
                },
                {
                    "account_id": "acc-ghost",
                    "device_id": "dev-ghost",
                    "device_name": "console",
                    "account_name": "Ghost",
                    "last_seen": root.now,
                    "game_status": "playing",
                    "game_name": "Warhammer 40,000: Space Marine 2",
                    "game_display": "Warhammer 40,000: Space Marine 2",
                    "game_hero_url": root.cover("sm2-hero.jpg"),
                    "game_session_seconds": 3600
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

    function checks() {
        return [
            {
                "name": "all five friends made it into the room",
                "got": Statusphere.memberCount,
                "want": 5
            },
            {
                "name": "the traveler's weather tile is live, not the plain form",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-nomad"], "row").find(t => t.field === "weather")?.form,
                "want": "weatherLive"
            },
            {
                "name": "the ghost friend's game shows through the built-in row, no pack needed",
                "got": Statusphere.gameDevices(Statusphere.accountsById["acc-ghost"]).length > 0,
                "want": true
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    readonly property int columnWidth: 300

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.preferredWidth: root.columnWidth
                spacing: 12

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-nyx"
                }

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-echo"
                }
            }

            ColumnLayout {
                Layout.preferredWidth: root.columnWidth
                spacing: 12

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-nomad"
                }

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-turing"
                }
            }
        }

        PresenceRow {
            Layout.fillWidth: true
            modelData: "acc-ghost"
        }
    }
}
