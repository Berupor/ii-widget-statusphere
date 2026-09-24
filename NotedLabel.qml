import qs.modules.common
import QtQuick

ShrinkThenWrapText {
    id: notedLabel
    required property var card
    largestSize: Appearance.font.pixelSize.smaller
    maxLines: 1
    text: notedMetrics.advanceWidth <= notedLabel.width ? notedLabel.card.notedLabelText : notedLabel.card.labelText
    color: notedLabel.card.mutedContentColor

    TextMetrics {
        id: notedMetrics
        font.family: Appearance.font.family.main
        font.pixelSize: notedLabel.largestSize
        text: notedLabel.card.notedLabelText
    }
}
