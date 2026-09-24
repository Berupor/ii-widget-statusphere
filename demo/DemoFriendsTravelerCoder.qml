//@ probe statusphere -g 420x1200 -s 1500
/**
 * Two more friend packs on their own, row collapsed and detail expanded: a
 * travelling photographer (local clock, weather, a shared photo) next to a
 * coder (current project, a commit heatmap, a small cpu accent - the one
 * pack that reaches into the hardware catalog, and not as its centerpiece).
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
                    "account_id": "acc-nomad",
                    "device_id": "dev-nomad",
                    "device_name": "phone",
                    "account_name": "Nomad",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.traveler.row,
                        "detail": CardLayouts.presets.traveler.detail
                    },
                    "weather": "9° Rain · Lisbon, PT",
                    "custom_fields": ["local_time", "mood", "region", "trip_day", "caption"],
                    "local_time": "13:15",
                    "mood": "📷",
                    "region": "PT-11",
                    "trip_day": "42",
                    "caption": "Somewhere new"
                },
                {
                    "account_id": "acc-turing",
                    "device_id": "dev-turing",
                    "device_name": "desktop",
                    "account_name": "Turing",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.coder.row,
                        "detail": CardLayouts.presets.coder.detail
                    },
                    "cpu_percent": 34,
                    "active_workspace": 4,
                    "custom_fields": ["project", "commits", "focus", "note"],
                    "project": "statusphere · nvim",
                    "commits": "5",
                    "commits_history": [1, 0, 3, 2, 4, 1, 5],
                    "focus": "45%",
                    "note": "Refactoring the tile grid"
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
                "name": "the traveler pack counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-nomad"]),
                "want": true
            },
            {
                "name": "the coder pack counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-turing"]),
                "want": true
            },
            {
                "name": "both rows drew their detail card open",
                "got": nomadRow.height > 200 && turingRow.height > 200,
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
            id: nomadRow
            Layout.fillWidth: true
            modelData: "acc-nomad"
            showDetails: true
        }

        PresenceRow {
            id: turingRow
            Layout.fillWidth: true
            modelData: "acc-turing"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
