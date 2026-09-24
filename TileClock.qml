import qs.modules.common
import QtQuick

ShrinkThenWrapText {
    required property var card
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(Math.min(width, height) * 0.4))
    maxLines: 3
    text: card.shownValueText
    color: card.contentColor
}
