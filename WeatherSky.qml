import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts

Item {
    id: sky
    required property string value
    required property color tint
    required property color contentColor
    required property bool running
    // -1 leaves the rain and lightning on their own wall-clock loops; set to pin every
    // drop and strike to that many elapsed ms, for a frame that must render the same on
    // every run.
    property real animPhase: -1

    // No tile span reaches this sibling of TileWeatherLive, so the 2x1 layout is read
    // back off the rendered aspect ratio instead - keep sceneStart's fraction matching
    // TileWeatherLive's textFraction, the two split the same tile.
    readonly property bool wide: sky.width > sky.height * 1.5
    readonly property real sceneStart: sky.wide ? sky.width * 0.45 : 0

    readonly property var fields: CardLayouts.weatherFieldsOf(sky.value)
    readonly property string condition: CardLayouts.weatherConditionOf(sky.value) ?? "clouds"
    readonly property bool isDay: sky.fields ? sky.fields.isDay : true
    readonly property real tempC: sky.fields ? sky.fields.temp : 15
    readonly property real precipMM: sky.fields ? sky.fields.precipMM : (sky.condition === "snow" ? 1 : (sky.condition === "rain" || sky.condition === "thunder") ? 2 : 0)
    readonly property real windKmph: sky.fields ? sky.fields.windKmph : 6
    readonly property real windDirDeg: sky.fields ? sky.fields.windDirDeg : 0

    readonly property real sunriseMin: sky.fields ? sky.fields.sunriseMin : 390
    readonly property real sunsetMin: sky.fields ? sky.fields.sunsetMin : 1170
    readonly property real nowMin: sky.fields ? sky.fields.nowMin : 780
    // 0 at sunrise/sunset, up to 1 at the moment itself, over a ~50min approach on
    // either side - the horizon warms before the tone lifts off the temperature alone.
    readonly property real twilightWindow: 50
    readonly property real twilightStrength: Math.max(0, 1 - Math.min(Math.abs(sky.nowMin - sky.sunriseMin), Math.abs(sky.nowMin - sky.sunsetMin)) / sky.twilightWindow)
    readonly property real dayProgress: sky.arcProgress(sky.nowMin, sky.sunriseMin, sky.sunsetMin)
    readonly property real nightProgress: sky.arcProgress(((sky.nowMin - sky.sunsetMin) % 1440 + 1440) % 1440, 0, ((sky.sunriseMin - sky.sunsetMin) % 1440 + 1440) % 1440)

    readonly property bool showsRain: sky.condition === "rain" || sky.condition === "thunder"
    readonly property bool showsSnow: sky.condition === "snow"
    readonly property bool showsClouds: sky.condition === "clouds" || sky.showsRain || sky.showsSnow
    readonly property bool showsClear: sky.condition === "clear"
    readonly property bool showsFog: sky.condition === "fog"
    readonly property bool showsThunder: sky.condition === "thunder"

    readonly property real intensity: Math.max(0, Math.min(1, sky.precipMM / 8))
    readonly property real windTilt: Math.max(-24, Math.min(24, -(sky.windKmph / 40) * 24 * Math.sin(sky.windDirDeg * Math.PI / 180)))

    readonly property real coldC: -5
    readonly property real hotC: 32
    readonly property real warmth: Math.max(0, Math.min(1, (sky.tempC - sky.coldC) / (sky.hotC - sky.coldC)))
    readonly property real toneSaturation: 0.85
    // colPrimary runs pastel-light in this theme; clamped so the hue still reads as a
    // color instead of washing out toward white.
    readonly property real toneLightness: Math.min(Appearance.colors.colPrimary.hslLightness, 0.62)
    readonly property color coldTone: Qt.hsla(0.6, sky.toneSaturation, sky.toneLightness, 1)
    readonly property color hotTone: Qt.hsla(0.07, sky.toneSaturation, sky.toneLightness, 1)
    // Mixed in RGB: a hue rotation from blue to orange passes through green.
    readonly property color toneWash: ColorUtils.applyAlpha(ColorUtils.mix(sky.hotTone, sky.coldTone, sky.warmth), 0.48)
    readonly property color nightWash: ColorUtils.transparentize(Appearance.colors.colScrim, 0.45)

    readonly property color sunColor: ColorUtils.transparentize(sky.contentColor, 0.05)
    readonly property color rayColor: ColorUtils.transparentize(sky.contentColor, 0.25)
    readonly property color moonColor: ColorUtils.transparentize(sky.contentColor, 0.1)
    readonly property color earthshineColor: ColorUtils.transparentize(sky.contentColor, 0.85)
    readonly property color starColor: ColorUtils.transparentize(sky.contentColor, 0.25)
    readonly property color cloudColor: ColorUtils.transparentize(sky.contentColor, 0.55)
    readonly property color rainColor: ColorUtils.transparentize(sky.contentColor, 0.3)
    readonly property color snowColor: ColorUtils.transparentize(sky.contentColor, 0.1)
    readonly property color fogColor: ColorUtils.transparentize(sky.contentColor, 0.82)
    readonly property color flashColor: ColorUtils.transparentize(sky.contentColor, 0)
    readonly property color flashFaintColor: ColorUtils.transparentize(sky.contentColor, 0.6)

    clip: true

    function hash(n) {
        const v = Math.sin(n * 12.9898) * 43758.5453;
        return v - Math.floor(v);
    }

    readonly property int firstStrikeMs: 900
    readonly property int flashRiseMs: 70
    readonly property int flashFallMs: 220
    readonly property real flashPeak: 0.5

    function strikeGapMs(strike) {
        return 1800 + sky.hash(strike) * 3000;
    }

    function pinnedFlashOpacity(phase) {
        let strikeAt = sky.firstStrikeMs;
        let strike = 1;
        while (strikeAt + sky.strikeGapMs(strike) <= phase) {
            strikeAt += sky.strikeGapMs(strike);
            strike += 1;
        }
        const sinceStrike = phase - strikeAt;
        if (sinceStrike < 0)
            return 0;
        if (sinceStrike < sky.flashRiseMs)
            return sky.flashPeak * sinceStrike / sky.flashRiseMs;
        return sky.flashPeak * Math.max(0, 1 - (sinceStrike - sky.flashRiseMs) / sky.flashFallMs);
    }

    function arcProgress(pos, start, end) {
        return end > start ? Math.max(0, Math.min(1, (pos - start) / (end - start))) : 0;
    }

    // On a tall (1x1) tile TileWeatherLive centers the city and temperature over the
    // whole tile, so the arc has to stay low, clear of that text - the wide layout
    // keeps them in a left column instead and can let the arc reach for the top.
    readonly property real arcPeakFraction: sky.wide ? 0.06 : 0.74

    // A body's arc across the scene: low behind the left edge at progress 0, highest
    // near the top (sky.arcPeakFraction) at 0.5, low behind the right edge at 1 -
    // restMargin is how much of the disc sinks below the tile at rest, as a fraction of
    // its own size.
    function arcPos(progress, size, restMargin) {
        const left = sky.sceneStart - size / 2;
        const right = sky.width - size / 2;
        const restY = sky.height - (1 - restMargin) * size;
        const peakY = sky.height * sky.arcPeakFraction;
        return Qt.point(left + progress * (right - left), restY - (restY - peakY) * Math.sin(progress * Math.PI));
    }

    // A particle drifting by `travel` px over its fall needs its spawn band widened on
    // the upwind side by that much, or the downwind edge goes bare while the upwind one
    // still has particles converging into frame.
    function driftSpawnRange(travel, width) {
        return travel >= 0 ? {
            "min": -Math.abs(travel),
            "max": width
        } : {
            "min": 0,
            "max": width + Math.abs(travel)
        };
    }

    Rectangle {
        anchors.fill: parent
        color: sky.toneWash
    }

    Rectangle {
        anchors.fill: parent
        opacity: sky.twilightStrength * 0.6
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: sky.hotTone
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: sky.showsClear

        // At the low ends of the arc (sunrise, sunset) a third of the disc sinks below
        // the tile's own clip, in the empty band under the temperature; the Sunny
        // silhouette's bottom point is shallower than its top one, so a full half would
        // pinch into a sliver.
        Item {
            id: sun
            objectName: "weatherSun"
            visible: sky.isDay
            width: Math.min(sky.width, sky.height) * 0.28
            height: sun.width
            readonly property point pos: sky.arcPos(sky.dayProgress, sun.width, 0.32)
            x: sun.pos.x
            y: sun.pos.y

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: sky.sunColor
            }

            Repeater {
                model: sky.showsClear && sky.isDay ? 8 : 0
                delegate: Rectangle {
                    id: ray
                    required property int index
                    width: sun.width * 0.12
                    height: sun.width * 0.75
                    radius: width / 2
                    color: sky.rayColor
                    anchors.horizontalCenter: sun.horizontalCenter
                    transformOrigin: Item.Bottom
                    y: sun.height / 2 - ray.height
                    rotation: ray.index * (360 / 8)
                }
            }
        }

        Item {
            id: moon
            objectName: "weatherMoon"
            visible: !sky.isDay
            width: Math.min(sky.width, sky.height) * 0.26
            height: moon.width
            readonly property point pos: sky.arcPos(sky.nightProgress, moon.width, 0.5)
            x: moon.pos.x
            y: moon.pos.y

            // Waning Gibbous/Last Quarter/Waning Crescent are the only named phases on
            // the shrinking half; everything else (including New/Full, where the side
            // does not read anyway) lights the near side first, i.e. waxing.
            readonly property bool waxing: !["Waning Gibbous", "Last Quarter", "Waning Crescent"].includes(sky.fields?.moonPhase ?? "")
            readonly property real illum: Math.max(0, Math.min(100, sky.fields?.moonIllum ?? 50)) / 100
            readonly property real r: moon.width / 2
            readonly property real terminatorRx: Math.abs(1 - 2 * moon.illum) * moon.r
            readonly property int outerSweep: moon.waxing ? 1 : 0
            readonly property int innerSweep: moon.illum < 0.5 ? (moon.waxing ? 0 : 1) : (moon.waxing ? 1 : 0)
            // The lit lune: a half-circle limb on the lit side, closed by an inner
            // terminator ellipse whose x-radius shrinks to 0 at the half-lit quarters
            // and back out to r at new/full - Northern-hemisphere framing, so waxing
            // lights the right limb.
            readonly property string litPath: `M ${moon.r},0 A ${moon.r},${moon.r} 0 0 ${moon.outerSweep} ${moon.r},${2 * moon.r} A ${moon.terminatorRx},${moon.r} 0 0 ${moon.innerSweep} ${moon.r},0 Z`

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: sky.earthshineColor
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: sky.moonColor
                    strokeColor: "transparent"
                    PathSvg {
                        path: moon.litPath
                    }
                }
            }
        }

        Repeater {
            model: !sky.isDay ? 10 : 0
            delegate: Rectangle {
                id: star
                required property int index
                readonly property real phase: sky.hash(star.index)
                width: 2 + sky.hash(star.index + 5) * 1.5
                height: star.width
                radius: width / 2
                color: sky.starColor
                x: sky.hash(star.index) * sky.width
                y: sky.hash(star.index + 11) * sky.height * 0.16
                opacity: 0.25

                SequentialAnimation on opacity {
                    running: sky.running && !sky.isDay
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.9
                        duration: 900 + star.phase * 1400
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: 0.25
                        duration: 900 + star.phase * 1400
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    Item {
        id: fog
        anchors.fill: parent
        visible: sky.showsFog

        Repeater {
            model: sky.showsFog ? 3 : 0
            delegate: Rectangle {
                id: haze
                required property int index
                // Wide enough, and drifting in a narrow enough band, that both edges stay
                // covered by overflow at every point of the drift - or a still frame (not
                // sky.running) would freeze on the rest x below and leave the right edge bare.
                width: sky.width * 1.3
                height: sky.height * 0.4
                radius: height / 2
                color: sky.fogColor
                y: sky.height * (0.08 + 0.28 * haze.index)
                x: -sky.width * 0.15

                // Blurred here, on the shape itself, so drifting only moves the cached
                // layer texture instead of rerunning the blur every frame.
                layer.enabled: true
                layer.effect: GaussianBlur {
                    radius: Math.max(sky.width, sky.height) * 0.12
                    samples: 16
                    transparentBorder: true
                }

                SequentialAnimation on x {
                    running: sky.running && sky.showsFog
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: -sky.width * 0.05
                        duration: 5200 + haze.index * 900
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: -sky.width * 0.25
                        duration: 5200 + haze.index * 900
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !sky.isDay
        color: sky.nightWash
    }

    // Keep sky.wide and precipMaskWide's stops matching where TileWeatherLive puts the
    // caption/temperature: centered when the tile is tall, in a left column of the
    // same textFraction for any wide span (2x1, 4x1, ...).
    Item {
        id: precip
        anchors.fill: parent
        visible: sky.showsClouds
        clip: true

        layer.enabled: sky.showsClouds
        layer.effect: OpacityMask {
            maskSource: sky.wide ? precipMaskWide : precipMaskTall
        }

        Repeater {
            model: sky.showsRain ? Math.round(8 + sky.intensity * 16) : 0
            delegate: Rectangle {
                id: drop
                required property int index
                readonly property real fallDuration: 650 - sky.intensity * 250 + sky.hash(drop.index + 9) * 300
                readonly property real travelX: (sky.height + 2 * drop.height) * Math.tan(sky.windTilt * Math.PI / 180)
                readonly property var spawnRange: sky.driftSpawnRange(drop.travelX, sky.width)
                readonly property real startX: drop.spawnRange.min + sky.hash(drop.index + 3) * (drop.spawnRange.max - drop.spawnRange.min)
                readonly property real pinnedProgress: (sky.animPhase % drop.fallDuration) / drop.fallDuration
                width: 2
                height: sky.height * (0.16 + sky.hash(drop.index) * 0.14)
                radius: width / 2
                color: sky.rainColor
                rotation: -sky.windTilt
                x: sky.animPhase >= 0 ? drop.startX + drop.travelX * drop.pinnedProgress : drop.startX
                y: sky.animPhase >= 0 ? -drop.height + (sky.height + 2 * drop.height) * drop.pinnedProgress : -drop.height

                NumberAnimation on y {
                    running: sky.running && sky.showsRain && sky.animPhase < 0
                    from: -drop.height
                    to: sky.height + drop.height
                    duration: drop.fallDuration
                    loops: Animation.Infinite
                }
                NumberAnimation on x {
                    running: sky.running && sky.showsRain && sky.animPhase < 0
                    from: drop.startX
                    to: drop.startX + drop.travelX
                    duration: drop.fallDuration
                    loops: Animation.Infinite
                }
            }
        }

        Repeater {
            model: sky.showsSnow ? Math.round(6 + sky.intensity * 14) : 0
            delegate: Item {
                id: flake
                required property int index
                readonly property real snowTilt: sky.windTilt * 0.6
                readonly property real driftSpan: (sky.height + 2 * flake.height) * Math.tan(flake.snowTilt * Math.PI / 180)
                readonly property var spawnRange: sky.driftSpawnRange(flake.driftSpan, sky.width)
                readonly property real baseX: flake.spawnRange.min + sky.hash(flake.index + 4) * (flake.spawnRange.max - flake.spawnRange.min)
                readonly property real driftX: (flake.y + flake.height) * Math.tan(flake.snowTilt * Math.PI / 180)
                property real swayOffset: 0
                width: 3 + sky.hash(flake.index + 6) * 3
                height: flake.width
                rotation: -flake.snowTilt
                x: flake.baseX + flake.driftX + flake.swayOffset
                y: -flake.height

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: sky.snowColor
                }

                NumberAnimation on y {
                    running: sky.running && sky.showsSnow
                    from: -flake.height
                    to: sky.height + flake.height
                    duration: 2200 - sky.intensity * 500 + sky.hash(flake.index + 13) * 1200
                    loops: Animation.Infinite
                }
                SequentialAnimation on swayOffset {
                    running: sky.running && sky.showsSnow
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: sky.width * 0.08
                        duration: 1400 + sky.hash(flake.index + 17) * 900
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: -sky.width * 0.08
                        duration: 1400 + sky.hash(flake.index + 17) * 900
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        Item {
            id: clouds
            anchors.fill: parent
            clip: true

            Repeater {
                model: sky.showsClouds ? 3 : 0
                delegate: Item {
                    id: cloud
                    required property int index
                    readonly property real depth: 0.55 + sky.hash(cloud.index) * 0.45
                    readonly property real puffSize: Math.min(sky.width, sky.height) * (0.2 + 0.1 * cloud.depth)
                    readonly property real layerLeft: sky.sceneStart - cloud.width * 0.1
                    readonly property real layerRight: sky.width - cloud.width * 0.7
                    readonly property real baseX: cloud.layerLeft + sky.hash(cloud.index + 7) * Math.max(0, cloud.layerRight - cloud.layerLeft)
                    width: cloud.puffSize * 2.4
                    height: cloud.puffSize * 1.3
                    x: cloud.baseX
                    y: sky.height * 0.04 * sky.hash(cloud.index + 2) - cloud.height * 0.35
                    opacity: 0.22 + 0.18 * cloud.depth
                    scale: 0.85 + 0.3 * cloud.depth

                    // Blurred here, on the static puffs, so drifting only moves the cached
                    // layer texture instead of rerunning the blur every frame.
                    layer.enabled: true
                    layer.effect: GaussianBlur {
                        radius: Math.min(sky.width, sky.height) * 0.08
                        samples: 12
                        transparentBorder: true
                    }

                    Rectangle {
                        width: cloud.puffSize * 1.3
                        height: cloud.puffSize * 0.9
                        radius: height / 2
                        color: sky.cloudColor
                        anchors.centerIn: parent
                    }
                    Rectangle {
                        width: cloud.puffSize * 0.9
                        height: cloud.puffSize * 0.8
                        radius: height / 2
                        color: sky.cloudColor
                        x: cloud.puffSize * 0.15
                        y: cloud.puffSize * 0.1
                    }
                    Rectangle {
                        width: cloud.puffSize * 0.8
                        height: cloud.puffSize * 0.7
                        radius: height / 2
                        color: sky.cloudColor
                        x: cloud.width - width - cloud.puffSize * 0.15
                        y: cloud.puffSize * 0.18
                    }

                    SequentialAnimation on x {
                        running: sky.running && sky.showsClouds && sky.animPhase < 0
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: cloud.baseX + sky.width * (0.1 + sky.windKmph * 0.003)
                            duration: (7800 - sky.windKmph * 40) / cloud.depth
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: cloud.baseX - sky.width * (0.1 + sky.windKmph * 0.003)
                            duration: (7800 - sky.windKmph * 40) / cloud.depth
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: precipMaskTall
        visible: false
        width: sky.width
        height: sky.height
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "white"
            }
            GradientStop {
                position: 0.3
                color: "transparent"
            }
            GradientStop {
                position: 0.8
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: "white"
            }
        }
    }

    Rectangle {
        id: precipMaskWide
        visible: false
        width: sky.width
        height: sky.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: Math.max(0, sky.sceneStart / Math.max(1, sky.width) - 0.05)
                color: "transparent"
            }
            GradientStop {
                position: Math.min(1, sky.sceneStart / Math.max(1, sky.width) + 0.12)
                color: "white"
            }
        }
    }

    Rectangle {
        id: flash
        anchors.fill: parent
        color: sky.flashColor
        gradient: sky.wide ? flashGradient : null
        opacity: sky.showsThunder && sky.animPhase >= 0 ? sky.pinnedFlashOpacity(sky.animPhase) : 0

        Gradient {
            id: flashGradient
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: sky.flashFaintColor
            }
            GradientStop {
                position: 1
                color: sky.flashColor
            }
        }

        SequentialAnimation {
            id: flashPulse
            NumberAnimation {
                target: flash
                property: "opacity"
                to: sky.flashPeak
                duration: sky.flashRiseMs
            }
            NumberAnimation {
                target: flash
                property: "opacity"
                to: 0
                duration: sky.flashFallMs
            }
        }

        Timer {
            id: flashTimer
            property int strikes: 0
            interval: sky.firstStrikeMs
            running: sky.running && sky.showsThunder && sky.animPhase < 0
            repeat: true
            onTriggered: {
                flashPulse.restart();
                flashTimer.strikes += 1;
                flashTimer.interval = sky.strikeGapMs(flashTimer.strikes);
            }
        }
    }
}
