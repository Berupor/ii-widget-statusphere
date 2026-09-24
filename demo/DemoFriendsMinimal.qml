//@ probe statusphere -g 420x420 -s 1500
/**
 * The spare end of the spectrum: a short note and a clock, row collapsed and
 * detail expanded, on its own so it reads as restraint rather than emptiness
 * next to a denser pack.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property int now: 1780000000

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-ren",
                    "device_id": "dev-ren",
                    "device_name": "phone",
                    "account_name": "Ren",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": CardLayouts.presets.minimal.row,
                        "detail": CardLayouts.presets.minimal.detail
                    },
                    "custom_fields": ["quote", "local_time", "mood"],
                    "quote": "Here, mostly",
                    "local_time": "20:05",
                    "mood": "🍃"
                }
            ],
            "photos": []
        })

    function checks() {
        return [
            {
                "name": "the minimal pack counts as a custom layout",
                "got": Statusphere.hasCustomLayout(Statusphere.accountsById["acc-ren"]),
                "want": true
            },
            {
                "name": "the row drew its detail card open",
                "got": renRow.height > 150,
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
            id: renRow
            Layout.fillWidth: true
            modelData: "acc-ren"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
