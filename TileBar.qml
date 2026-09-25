import qs.modules.common
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: form
    required property var card
    spacing: 4

    NotedLabel {
        Layout.fillWidth: true
        card: form.card
    }
    ShrinkThenWrapText {
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.3))
        maxLines: 1
        animateChange: true
        text: form.card.hasData ? Math.round(form.card.percent) + "%" : "-"
        color: form.card.contentColor
    }
    WaveBar {
        Layout.fillWidth: true
        color: form.card.contentColor
        to: 100
        value: form.card.hasData ? form.card.percent : 0
        wavy: false
        animateWave: false
    }
}
