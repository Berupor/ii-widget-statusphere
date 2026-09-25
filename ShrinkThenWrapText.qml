import qs.modules.common
import qs.modules.common.widgets
import QtQuick

StyledText {
    id: fitText
    property real largestSize: Appearance.font.pixelSize.huge
    property real wrapBelow: Appearance.font.pixelSize.normal
    property int maxLines: 2
    readonly property bool canWrap: fitText.maxLines > 1 && /[ \t\n]/.test(fitText.text)
    readonly property real oneLineSize: Math.min(fitText.largestSize, Math.floor(fitText.largestSize * fitText.width / Math.max(1, oneLineMetrics.advanceWidth)))
    readonly property real shrinkFloor: fitText.canWrap ? fitText.wrapBelow : Appearance.font.pixelSize.smallest
    readonly property bool fitsOneLine: fitText.oneLineSize >= fitText.shrinkFloor

    font.pixelSize: fitText.fitsOneLine ? fitText.oneLineSize : fitText.shrinkFloor
    wrapMode: fitText.fitsOneLine ? Text.NoWrap : Text.WordWrap
    maximumLineCount: fitText.maxLines
    fontSizeMode: Text.Fit
    minimumPixelSize: Appearance.font.pixelSize.smallest
    elide: Text.ElideRight
    textFormat: Text.PlainText

    TextMetrics {
        id: oneLineMetrics
        font.family: fitText.shouldUseNumberFont ? Appearance.font.family.numbers : Appearance.font.family.main
        font.pixelSize: fitText.largestSize
        text: fitText.text
    }
}
