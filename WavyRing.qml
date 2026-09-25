import QtQuick
import QtQuick.Shapes
import qs.modules.common

Item {
    id: root

    property int implicitSize: 30
    property int lineWidth: 2
    property real value: 0
    property color colPrimary: Appearance.m3colors.m3onSecondaryContainer
    property color colSecondary: Appearance.colors.colSecondaryContainer
    property real gapAngle: 360 / 18
    property bool enableAnimation: true
    property int animationDuration: 800
    property var easingType: Easing.OutCubic

    property real waveAmplitude: 1.6
    property real waveLength: 40
    property bool animateWave: true

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    property real degree: value * 360
    property real centerX: root.width / 2
    property real centerY: root.height / 2
    property real arcRadius: root.implicitSize / 2 - root.lineWidth - root.waveAmplitude
    property real startAngle: -90
    property real waveFrequency: (2 * Math.PI * root.arcRadius) / root.waveLength
    property real wavePhase: 0

    NumberAnimation on wavePhase {
        running: root.animateWave
        from: 0
        to: 360
        duration: 2000
        loops: Animation.Infinite
    }

    Behavior on degree {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
        }
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.colSecondary
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle - root.gapAngle
                sweepAngle: -(360 - root.degree - 2 * root.gapAngle)
            }
        }

        ShapePath {
            strokeColor: root.colPrimary
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            PathPolyline {
                path: {
                    const rad = root.startAngle * Math.PI / 180;
                    if (root.degree <= 0)
                        return [Qt.point(root.centerX + root.arcRadius * Math.cos(rad), root.centerY + root.arcRadius * Math.sin(rad))];

                    const steps = Math.max(20, Math.floor(root.degree * 1.5));
                    const pts = [];
                    for (let i = 0; i <= steps; i++) {
                        const currentDeg = root.startAngle + root.degree * i / steps;
                        const currentRad = currentDeg * Math.PI / 180;
                        let edgeFactor = 1;
                        if (i < 4)
                            edgeFactor = i / 4;
                        if (steps - i < 4)
                            edgeFactor = (steps - i) / 4;
                        const waveOffset = root.waveAmplitude * Math.sin((currentDeg * root.waveFrequency + root.wavePhase) * Math.PI / 180) * edgeFactor;
                        const r = root.arcRadius + waveOffset;
                        pts.push(Qt.point(root.centerX + r * Math.cos(currentRad), root.centerY + r * Math.sin(currentRad)));
                    }
                    return pts;
                }
            }
        }
    }
}
