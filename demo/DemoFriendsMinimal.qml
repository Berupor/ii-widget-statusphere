//@ probe statusphere -g 420x420 -s 1500
/**
 * The spare end of the spectrum: a quote, a local clock and how long they've
 * been online, one mood line in the detail card - row collapsed and detail
 * expanded, on its own so it reads as restraint rather than emptiness next
 * to a denser pack.
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
                    "custom_fields": ["quote", "local_time", "since", "mood"],
                    "quote": "still here",
                    "local_time": "23:14",
                    "since": "3d",
                    "mood": "unbothered, in the moment"
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

        const texts = root.findAll(root, it => it.text !== undefined, []);
        const hasText = value => texts.some(t => t.text === value);

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
            },
            {
                "name": "no pack row is left with an empty grid cell",
                "got": grids.length > 0 && packedSolid,
                "want": true
            },
            {
                "name": "a big-form tile shows a label, not just a bare value",
                "got": hasText("Quote") && hasText("still here"),
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
