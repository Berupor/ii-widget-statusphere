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
        dial.enableAnimation = Math.abs(form.progress - dial.value) >= form.smallestAnimatedStep;
        dial.value = form.progress;
    }
    onProgressChanged: form.showProgress()
    Component.onCompleted: {
        dial.enableAnimation = false;
        dial.value = form.progress;
    }

    WavyRing {
        id: dial
        anchors.centerIn: parent
        implicitSize: Math.round(Math.min(form.width, form.height))
        lineWidth: Math.max(2, implicitSize * 0.05)
        waveAmplitude: Math.max(1.5, implicitSize * 0.012)
        waveLength: Math.max(12, implicitSize * 0.12)
        colPrimary: form.card.contentColor
        colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.75)
        animateWave: form.card.animating

        readonly property real innerBox: 2 * dial.arcRadius * Math.SQRT1_2

        RingCenterText {
            anchors.centerIn: parent
            card: form.card
            innerBox: dial.innerBox
        }
    }
}
