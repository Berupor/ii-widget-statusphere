import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: form
    required property var card
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        MaterialSymbol {
            visible: (form.card.field?.icon ?? "").length > 0
            text: form.card.field?.icon ?? ""
            iconSize: Appearance.font.pixelSize.smaller
            color: form.card.mutedContentColor
        }
        NotedLabel {
            Layout.fillWidth: true
            card: form.card
        }
    }
    ShrinkThenWrapText {
        objectName: "textValue"
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        animateChange: true
        text: form.card.shownValueText
        color: form.card.contentColor
    }
}
