import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property var device: form.card.gameDevice
    readonly property real iconSize: Math.max(Appearance.font.pixelSize.large, Math.round(form.height * 0.3))
    readonly property real labelSize: Math.max(Appearance.font.pixelSize.smaller, Math.round(form.height * 0.18))
    readonly property real valueSize: Math.max(Appearance.font.pixelSize.large, Math.round(form.height * 0.3))

    RowLayout {
        anchors.fill: parent
        spacing: 8

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: "sports_esports"
            iconSize: form.iconSize
            color: form.card.contentColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: form.device?.game_source ? Statusphere.labelForKey(form.device.game_source) : (Statusphere.gameFor(form.device) || "-")
                color: form.card.mutedContentColor
                font.pixelSize: form.labelSize
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                animateChange: true
                text: form.device ? Statusphere.sessionFor(Statusphere.gameStartedMsFor(form.device)) : ""
                color: form.card.contentColor
                font.pixelSize: form.valueSize
            }
        }
    }
}
