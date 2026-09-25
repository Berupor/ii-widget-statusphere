import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Column {
    id: root
    required property var card
    required property real innerBox
    readonly property bool captionFits: ringValue.implicitHeight + ringCaption.implicitHeight <= root.innerBox && ringCaption.fitsOneLine

    width: root.innerBox
    spacing: 0

    StyledText {
        id: ringValue
        objectName: "ringValue"
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: Appearance.font.pixelSize.smallest
        animateChange: true
        text: root.card.hasData ? Math.round(root.card.percent) + "%" : "-"
        color: root.card.contentColor
        font.pixelSize: Math.max(Appearance.font.pixelSize.smallest, root.innerBox * 0.4)
    }
    ShrinkThenWrapText {
        id: ringCaption
        objectName: "ringCaption"
        visible: root.captionFits
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        largestSize: Math.max(Appearance.font.pixelSize.smallest, root.innerBox * 0.2)
        maxLines: 1
        text: root.card.labelText
        color: root.card.mutedContentColor
    }
}
