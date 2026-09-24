import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property var device: form.card.gameDevice

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: 8

        MaterialSymbol {
            text: "sports_esports"
            iconSize: Appearance.font.pixelSize.large
            color: form.card.contentColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: form.device?.game_source ? Statusphere.labelForKey(form.device.game_source) : (Statusphere.gameFor(form.device) || "-")
                color: form.card.mutedContentColor
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                animateChange: true
                text: form.device ? Statusphere.sessionFor(Statusphere.gameStartedMsFor(form.device)) : ""
                color: form.card.contentColor
                font.pixelSize: Appearance.font.pixelSize.large
            }
        }
    }
}
