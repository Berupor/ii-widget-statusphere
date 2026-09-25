//@ probe statusphere -g 440x210 -s 1500
/**
 * The README's incognito shot: holding your own avatar slides open
 * PresenceIncognitoPicker, and a friend who picked "Until I say" shows up to
 * everyone else as just a hidden line, window and all.
 */
import ".."
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property int now: 1780000000

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-you",
                    "device_id": "dev-you",
                    "device_name": "laptop",
                    "account_name": "You",
                    "last_seen": root.now
                },
                {
                    "account_id": "acc-nova",
                    "device_id": "dev-nova",
                    "device_name": "phone",
                    "account_name": "Nova",
                    "last_seen": root.now,
                    "active_window": "Signal",
                    "_incognito": true
                }
            ],
            "photos": []
        })

    function checks() {
        return [
            {
                "name": "the picker is open and Nova reads as hidden",
                "got": [picker.open, Statusphere.hiddenFor(Statusphere.accountsById["acc-nova"])],
                "want": [true, true]
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heldRow.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            RowLayout {
                id: heldRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 12
                }
                spacing: 12

                PresenceAvatar {
                    account: Statusphere.accountsById["acc-you"]
                    offline: false
                    hidden: false
                    away: false
                    shape: "Circle"
                    interactive: true
                }

                PresenceIncognitoPicker {
                    id: picker
                    Layout.fillWidth: true
                    open: true
                    hovered: 3
                }
            }
        }

        PresenceRow {
            Layout.fillWidth: true
            modelData: "acc-nova"
        }
    }
}
