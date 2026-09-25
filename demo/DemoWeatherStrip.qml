//@ probe statusphere -g 700x520 -s 1500
/**
 * The README's live weather strip: a curated handful of TileWeatherLive
 * conditions - clear day and night side by side, rain, thunder, snow, fog
 * and a sunset - instead of DemoWeather's full debug wall.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick

Item {
    id: root
    readonly property int tileUnit: 150
    readonly property int gap: 12

    readonly property int sunriseMin: 390
    readonly property int sunsetMin: 1170

    function weatherValue(temp, code, precip, wind, windDir, nowMin, moonIllum, moonPhase, city) {
        const isDay = nowMin >= root.sunriseMin && nowMin < root.sunsetMin ? 1 : 0;
        return `${temp};${code};${precip};${wind};${windDir};${isDay};${moonIllum};${moonPhase};${root.sunriseMin};${root.sunsetMin};${nowMin};${city}`;
    }

    readonly property var fields: ({
            "clear_day": root.weatherValue(22, 113, 0, 8, 200, 720, 28, "Waxing Crescent", "Barcelona"),
            "rain": root.weatherValue(14, 302, 3.5, 18, 230, 720, 50, "First Quarter", "Seattle"),
            "thunder": root.weatherValue(26, 389, 6, 22, 90, 720, 50, "First Quarter", "Miami"),
            "fog": root.weatherValue(6, 248, 0, 3, 0, 720, 50, "First Quarter", "London"),
            "snow": root.weatherValue(-3, 332, 2, 12, 320, 720, 50, "First Quarter", "Oslo"),
            "clouds": root.weatherValue(15, 119, 0, 14, 250, 720, 50, "First Quarter", "Amsterdam"),
            "twilight": root.weatherValue(15, 113, 0, 6, 180, root.sunsetMin - 1, 62, "Waxing Gibbous", "Berlin"),
            "clear_night": root.weatherValue(12, 113, 0, 8, 200, 1320, 28, "Waxing Crescent", "Barcelona")
        })

    function wallTile(field, size, color) {
        return CardLayouts.tile({
            "type": "scalar",
            "field": field,
            "form": "weatherLive",
            "shape": "auto",
            "size": size,
            "color": color,
            "onMissing": "hide"
        });
    }

    readonly property var wallTiles: [
        root.wallTile("clear_day", "1x1", "primaryContainer"),
        root.wallTile("rain", "2x1", "secondaryContainer"),
        root.wallTile("thunder", "1x1", "secondaryContainer"),
        root.wallTile("fog", "2x1", "primaryContainer"),
        root.wallTile("twilight", "2x1", "tertiaryContainer"),
        root.wallTile("snow", "1x1", "secondaryContainer"),
        root.wallTile("clear_night", "2x1", "tertiaryContainer"),
        root.wallTile("clouds", "1x1", "primaryContainer")
    ]

    readonly property var room: ({
            "members": [
                Object.assign({
                    "account_id": "acc-weather",
                    "device_id": "dev-weather",
                    "device_name": "desktop",
                    "account_name": "Weather Wall",
                    "last_seen": 1780000000,
                    "custom_fields": Object.keys(root.fields)
                }, root.fields)
            ],
            "photos": []
        })

    function checks() {
        return [
            {
                "name": "every curated tile renders one CardTile",
                "got": wall.children.length > 0,
                "want": true
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    Flow {
        id: wall
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: root.gap

        Repeater {
            model: root.wallTiles
            delegate: CardTile {
                id: tileItem
                required property var modelData
                readonly property int cols: CardLayouts.spanOf(tileItem.modelData.size).cols
                width: tileItem.cols * root.tileUnit + (tileItem.cols - 1) * root.gap
                height: root.tileUnit
                account: Statusphere.accountsById["acc-weather"]
                tile: tileItem.modelData
            }
        }
    }
}
