import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    property string caption: form.card.labelText
    property string value: form.card.valueText

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: 2

        ShrinkThenWrapText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            largestSize: Math.max(Appearance.font.pixelSize.smallest, Math.round(form.height * 0.15))
            wrapBelow: Appearance.font.pixelSize.smallest
            text: form.caption
            color: form.card.mutedContentColor
        }
        ShrinkThenWrapText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.4))
            maxLines: 1
            animateChange: true
            text: form.card.hasData ? form.value : "-"
            color: form.card.contentColor
        }
    }
}
