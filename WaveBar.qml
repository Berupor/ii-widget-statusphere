import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

// StyledProgressBar draws its line as thick as the bar item is tall and swings the wave
// past that height, so the wave gets its room from a wrapper instead of a taller bar.
// It also counts waves per bar width and ties their height to the line width, so a fixed
// wave length keeps a narrow tile from turning into a zigzag.
Item {
    id: waveBar
    required property color color
    property alias value: waveBarLine.value
    property alias to: waveBarLine.to
    property alias animateWave: waveBarLine.animateWave
    property alias wavy: waveBarLine.wavy
    readonly property real waveLength: 40
    readonly property real lineWidth: 4
    implicitHeight: waveBarLine.valueBarHeight * (1 + 2 * waveBarLine.waveAmplitudeMultiplier)

    StyledProgressBar {
        id: waveBarLine
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        from: 0
        valueBarHeight: waveBar.lineWidth
        waveFrequency: width / waveBar.waveLength
        highlightColor: waveBar.color
        trackColor: ColorUtils.transparentize(waveBar.color, 0.75)
    }
}
