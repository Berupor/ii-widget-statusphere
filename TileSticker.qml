import qs.modules.common
import QtQuick
import QtQuick.Layouts

// A bare number or word with no label reads as decoration, not data, so a sticker keeps
// the same small caption the number/weather forms show above their value.
ColumnLayout {
    id: form
    required property var card
    spacing: 2

    NotedLabel {
        Layout.fillWidth: true
        card: form.card
        horizontalAlignment: Text.AlignHCenter
        largestSize: Appearance.font.pixelSize.smallest
    }
    ShrinkThenWrapText {
        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(Math.min(form.width, form.height) * 0.4))
        maxLines: 3
        animateChange: true
        text: form.card.shownValueText
        color: form.card.contentColor
    }
}
