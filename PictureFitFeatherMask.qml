import QtQuick
import Qt5Compat.GraphicalEffects

/** Fades a fitted image out along the axis with margins, so it has no hard seam against the blurred backdrop. */
Item {
    id: root
    required property real paintedWidth
    required property real paintedHeight
    property real featherFraction: 0.13

    readonly property bool hasMarginX: root.paintedWidth > 1 && root.width - root.paintedWidth > 1
    readonly property bool hasMarginY: root.paintedHeight > 1 && root.height - root.paintedHeight > 1
    readonly property real featherX: root.paintedWidth * root.featherFraction
    readonly property real featherY: root.paintedHeight * root.featherFraction

    Rectangle {
        anchors.fill: parent
        color: "white"
        visible: !root.hasMarginX && !root.hasMarginY
    }

    LinearGradient {
        visible: root.hasMarginX
        x: (root.width - root.paintedWidth) / 2
        y: 0
        width: root.paintedWidth
        height: root.height
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: root.featherX / root.paintedWidth
                color: "white"
            }
            GradientStop {
                position: 1 - root.featherX / root.paintedWidth
                color: "white"
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }

    LinearGradient {
        visible: root.hasMarginY
        x: 0
        y: (root.height - root.paintedHeight) / 2
        width: root.width
        height: root.paintedHeight
        start: Qt.point(0, 0)
        end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: root.featherY / root.paintedHeight
                color: "white"
            }
            GradientStop {
                position: 1 - root.featherY / root.paintedHeight
                color: "white"
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }
}
