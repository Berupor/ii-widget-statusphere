pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Flow {
    id: root
    spacing: 4
    required property var options
    property string current: ""
    signal picked(string name)

    Repeater {
        model: root.options
        delegate: Rectangle {
            id: shapeSwatch
            required property string modelData
            width: 30
            height: 30
            radius: Appearance.rounding.small
            color: root.current === shapeSwatch.modelData ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2
            border.width: root.current === shapeSwatch.modelData ? 2 : 0
            border.color: Appearance.colors.colPrimary

            MaterialSymbol {
                visible: shapeSwatch.modelData === "auto"
                anchors.centerIn: parent
                text: "auto_awesome"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer2
            }

            Rectangle {
                visible: shapeSwatch.modelData === "default"
                anchors.centerIn: parent
                width: 15
                height: 15
                radius: Appearance.rounding.small
                color: "transparent"
                border.width: 2
                border.color: Appearance.colors.colOnLayer2
            }

            SineCookie {
                visible: shapeSwatch.modelData === "SineCookie"
                anchors.centerIn: parent
                implicitSize: 15
                color: Appearance.colors.colOnLayer2
            }

            MaterialShape {
                visible: !["default", "auto", "SineCookie"].includes(shapeSwatch.modelData)
                anchors.centerIn: parent
                implicitSize: 15
                shape: MaterialShape.Shape[shapeSwatch.modelData] ?? MaterialShape.Shape.Circle
                color: Appearance.colors.colOnLayer2
            }

            MouseArea {
                id: shapeSwatchArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(shapeSwatch.modelData)
            }

            StyledToolTip {
                extraVisibleCondition: false
                alternativeVisibleCondition: shapeSwatchArea.containsMouse
                text: shapeSwatch.modelData
            }
        }
    }
}
