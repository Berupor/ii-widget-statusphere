import QtQuick

ShrinkThenWrapText {
    required property var card
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    maxLines: 3
    text: card.shownValueText
    color: card.contentColor
}
