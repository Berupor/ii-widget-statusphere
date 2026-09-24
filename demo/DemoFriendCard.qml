//@ probe statusphere -g 420x480 -s 1500
/**
 * One friend on the night owl pack, detail card open: a game banner, the
 * track as a wave line, the app, uptime, night weather, moon phase, a local
 * clock and sunrise/sunset. Row left empty (`row: []`) so nothing repeats
 * between the row and the detail card below it.
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
                    "_layout": {
                        "updated_at": root.now,
                        "row": [],
                        "detail": CardLayouts.packs.detail.nightOwl
                    },
                    "spotify_status": "playing",
                    "spotify_track": "Turn Off the Lights",
                    "spotify_artist": "Nite Jewel",
                    "spotify_position": 40,
                    "spotify_length": 210,
                    "spotify_art_url": root.cover("nightcall.jpg"),
                    "game_status": "playing",
                    "game_name": "Cyberpunk 2077",
                    "game_display": "Cyberpunk 2077",
                    "game_header_url": root.cover("cp2077-header.jpg"),
                    "game_session_seconds": 7200,
                    "uptime_hours": 27,
                    "active_app": "mpv",
                    "custom_fields": ["local_time", "weather", "moon", "sun"],
                    "weather": "7° Clear",
                    "local_time": "03:12",
                    "moon": "🌔",
                    "sun": "06:45 · 18:52"
                }
            ],
            "photos": []
        })

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
                "name": "the night owl detail pack owns detail, row stays empty",
                "got": ["row", "detail"].map(surface => Statusphere.ownsSurface(Statusphere.accountsById["acc-nyx"], surface)),
                "want": [true, true]
            },
            {
                "name": "an empty row draws no row grid",
                "got": Statusphere.surfaceTiles(Statusphere.accountsById["acc-nyx"], "row").length,
                "want": 0
            },
            {
                "name": "no pack tile is left with an empty grid cell",
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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
