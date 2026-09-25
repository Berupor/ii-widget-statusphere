import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: form
    required property var card
    readonly property real progress: form.card.hasData ? form.card.percent / 100 : 0
    readonly property real smallestAnimatedStep: 0.05

    function showProgress(): void {
        ring.enableAnimation = Math.abs(form.progress - ring.value) >= form.smallestAnimatedStep;
        ring.value = form.progress;
    }
    onProgressChanged: form.showProgress()
    Component.onCompleted: {
        ring.enableAnimation = false;
        ring.value = form.progress;
    }

    CircularProgress {
        id: ring
        anchors.centerIn: parent
        implicitSize: Math.round(Math.min(form.width, form.height))
        lineWidth: Math.max(3, implicitSize * 0.08)
        colPrimary: form.card.contentColor
        colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.75)

        readonly property real innerBox: (ring.implicitSize - 2 * ring.lineWidth) * Math.SQRT1_2
        readonly property bool captionFits: ringValue.implicitHeight + ringCaption.implicitHeight <= ring.innerBox && ringCaption.fitsOneLine

        Column {
            anchors.centerIn: parent
            width: ring.innerBox
            spacing: 0

            StyledText {
                id: ringValue
                objectName: "ringValue"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Appearance.font.pixelSize.smallest
                animateChange: true
                text: form.card.hasData ? Math.round(form.card.percent) + "%" : "-"
                color: form.card.contentColor
                font.pixelSize: Math.max(Appearance.font.pixelSize.smallest, ring.innerBox * 0.4)
            }
            ShrinkThenWrapText {
                id: ringCaption
                objectName: "ringCaption"
                visible: ring.captionFits
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                largestSize: Math.max(Appearance.font.pixelSize.smallest, ring.innerBox * 0.2)
                maxLines: 1
                text: form.card.labelText
                color: form.card.mutedContentColor
            }
        }
    }
}
