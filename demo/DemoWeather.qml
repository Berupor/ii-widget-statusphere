//@ probe statusphere -g 1300x660 -s 2500
/**
 * The animated live weather tile (TileWeatherLive + WeatherSky) at every condition, day
 * and night, both sizes - plus a few tiles that isolate one axis each: light vs heavy
 * rain, windy vs calm, a cold vs a hot reading, and a waxing crescent vs a waxing
 * gibbous moon. arcMoments steps the sun and moon around their arcs: sunrise, morning,
 * noon, late afternoon and sunset by day, dusk, midnight and pre-dawn by night. One
 * tile on the old "weather" kind with a legacy-format value closes it out, to keep the
 * untouched path exercised too.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "../Templates.js" as Templates
import qs.modules.common
import QtQuick

Item {
    id: root
    readonly property int now: 1780000000
    readonly property int tileUnit: 96
    readonly property int gap: 8

    readonly property int sunriseMin: 390
    readonly property int sunsetMin: 1170
    readonly property int dayNowMin: 720
    readonly property int nightNowMin: 1320

    function weatherValue(temp, code, precip, wind, windDir, sunrise, sunset, nowMin, moonIllum, moonPhase, city) {
        const isDay = nowMin >= sunrise && nowMin < sunset ? 1 : 0;
        return `${temp};${code};${precip};${wind};${windDir};${isDay};${moonIllum};${moonPhase};${sunrise};${sunset};${nowMin};${city}`;
    }

    readonly property var conditions: [
        {
            "key": "clear",
            "code": 113,
            "temp": 22,
            "nightTemp": 12,
            "precip": 0,
            "wind": 8,
            "windDir": 200,
            "city": "Barcelona",
            "moonIllum": 28,
            "moonPhase": "Waxing Crescent"
        },
        {
            "key": "clouds",
            "code": 119,
            "temp": 15,
            "nightTemp": 9,
            "precip": 0,
            "wind": 14,
            "windDir": 250,
            "city": "Amsterdam",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "rain",
            "code": 302,
            "temp": 14,
            "nightTemp": 11,
            "precip": 3.5,
            "wind": 18,
            "windDir": 230,
            "city": "Seattle",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "thunder",
            "code": 389,
            "temp": 26,
            "nightTemp": 21,
            "precip": 6,
            "wind": 22,
            "windDir": 90,
            "city": "Miami",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "snow",
            "code": 332,
            "temp": -3,
            "nightTemp": -8,
            "precip": 2,
            "wind": 12,
            "windDir": 320,
            "city": "Oslo",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "fog",
            "code": 248,
            "temp": 6,
            "nightTemp": 4,
            "precip": 0,
            "wind": 3,
            "windDir": 0,
            "city": "London",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        }
    ]

    readonly property var variants: [
        {
            "key": "rain_light",
            "code": 296,
            "temp": 16,
            "precip": 0.5,
            "wind": 5,
            "windDir": 180,
            "city": "Dublin",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "rain_heavy",
            "code": 308,
            "temp": 15,
            "precip": 8,
            "wind": 10,
            "windDir": 180,
            "city": "Mumbai",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "rain_windy",
            "code": 302,
            "temp": 13,
            "precip": 3,
            "wind": 45,
            "windDir": 90,
            "city": "Wellington",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "rain_calm",
            "code": 302,
            "temp": 13,
            "precip": 3,
            "wind": 1,
            "windDir": 0,
            "city": "Kyoto",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "clear_cold",
            "code": 113,
            "temp": -18,
            "precip": 0,
            "wind": 6,
            "windDir": 200,
            "city": "Yakutsk",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "clear_hot",
            "code": 113,
            "temp": 41,
            "precip": 0,
            "wind": 6,
            "windDir": 200,
            "city": "Phoenix",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "clear_full_moon",
            "code": 113,
            "temp": 8,
            "precip": 0,
            "wind": 5,
            "windDir": 180,
            "city": "Reykjavik",
            "now": 1320,
            "moonIllum": 96,
            "moonPhase": "Waxing Gibbous"
        }
    ]

    // Steps the sun (day) or moon (night) around their arcs, at the same sunrise/sunset
    // as root.sunriseMin/sunsetMin - noon (780) sits exactly at their midpoint.
    readonly property var arcMoments: [
        { "key": "arc_sunrise", "temp": 10, "now": root.sunriseMin, "day": true },
        { "key": "arc_morning", "temp": 14, "now": 540, "day": true },
        { "key": "arc_noon", "temp": 22, "now": 780, "day": true },
        { "key": "arc_late_afternoon", "temp": 19, "now": 1020, "day": true },
        { "key": "arc_sunset", "temp": 15, "now": root.sunsetMin - 1, "day": true },
        { "key": "arc_dusk", "temp": 12, "now": 1200, "day": false },
        { "key": "arc_midnight", "temp": 8, "now": 0, "day": false },
        { "key": "arc_predawn", "temp": 7, "now": 330, "day": false }
    ]

    readonly property string legacyKey: "weather_legacy"
    readonly property string legacyValue: "9° Rain · Lisbon, PT"

    function fieldEntries() {
        const entries = {};
        for (const c of root.conditions) {
            entries[`${c.key}_day`] = root.weatherValue(c.temp, c.code, c.precip, c.wind, c.windDir, root.sunriseMin, root.sunsetMin, root.dayNowMin, c.moonIllum, c.moonPhase, c.city);
            entries[`${c.key}_night`] = root.weatherValue(c.nightTemp, c.code, c.precip, c.wind, c.windDir, root.sunriseMin, root.sunsetMin, root.nightNowMin, c.moonIllum, c.moonPhase, c.city);
        }
        for (const v of root.variants)
            entries[v.key] = root.weatherValue(v.temp, v.code, v.precip, v.wind, v.windDir, root.sunriseMin, root.sunsetMin, v.now ?? root.dayNowMin, v.moonIllum, v.moonPhase, v.city);
        for (const a of root.arcMoments)
            entries[a.key] = root.weatherValue(a.temp, 113, 0, 6, 180, root.sunriseMin, root.sunsetMin, a.now, 62, "Waxing Gibbous", "Berlin");
        entries[root.legacyKey] = root.legacyValue;
        return entries;
    }
    readonly property var fields: root.fieldEntries()

    function wallTile(field, size, color, form) {
        return CardLayouts.tile({
            "type": "scalar",
            "field": field,
            "form": form ?? "weatherLive",
            "shape": "auto",
            "size": size,
            "color": color,
            "onMissing": "hide"
        });
    }

    readonly property var wallTiles: {
        const tiles = [];
        for (const c of root.conditions) {
            tiles.push(root.wallTile(`${c.key}_day`, "1x1", "primaryContainer"));
            tiles.push(root.wallTile(`${c.key}_night`, "1x1", "tertiaryContainer"));
            tiles.push(root.wallTile(`${c.key}_day`, "2x1", "primaryContainer"));
            tiles.push(root.wallTile(`${c.key}_night`, "2x1", "tertiaryContainer"));
        }
        for (const v of root.variants)
            tiles.push(root.wallTile(v.key, "1x1", "secondaryContainer"));
        for (const a of root.arcMoments) {
            const color = a.day ? "primaryContainer" : "tertiaryContainer";
            tiles.push(root.wallTile(a.key, "1x1", color));
            tiles.push(root.wallTile(a.key, "2x1", color));
        }
        tiles.push(root.wallTile(root.legacyKey, "2x1", "secondaryContainer", "weather"));
        return tiles;
    }

    readonly property var room: ({
            "members": [
                Object.assign({
                    "account_id": "acc-weather",
                    "device_id": "dev-weather",
                    "device_name": "desktop",
                    "account_name": "Weather Wall",
                    "last_seen": root.now,
                    "custom_fields": Object.keys(root.fields)
                }, root.fields)
            ],
            "photos": []
        })

    function findAll(item, pred, out) {
        if (!item)
            return out;
        if (pred(item))
            out.push(item);
        for (let i = 0; i < item.children.length; i++)
            root.findAll(item.children[i], pred, out);
        return out;
    }

    function tileFor(field, size) {
        return root.findAll(wall, it => it.tile !== undefined && it.tile.field === field && (size === undefined || it.tile.size === size), [])[0] ?? null;
    }

    function skyFor(field, size) {
        return root.findAll(root.tileFor(field, size), it => it.condition !== undefined && it.showsThunder !== undefined, [])[0] ?? null;
    }

    function textPartsOf(field, size) {
        return root.findAll(root.tileFor(field, size), it => it.text !== undefined && it.font !== undefined, []).map(it => it.text);
    }

    function bodyOf(field, size, name) {
        return root.findAll(root.tileFor(field, size), it => it.objectName === name, [])[0] ?? null;
    }

    function checks() {
        const clearDay = root.skyFor("clear_day", "1x1");
        const clearNight = root.skyFor("clear_night", "1x1");
        const thunderDay = root.skyFor("thunder_day", "1x1");
        const snowNight = root.skyFor("snow_night", "1x1");
        const rainLight = root.skyFor("rain_light");
        const rainHeavy = root.skyFor("rain_heavy");
        const rainWindy = root.skyFor("rain_windy");
        const rainCalm = root.skyFor("rain_calm");
        const clearCold = root.skyFor("clear_cold");
        const clearHot = root.skyFor("clear_hot");
        const arcDayKeys = ["arc_sunrise", "arc_morning", "arc_noon", "arc_late_afternoon", "arc_sunset"];
        const arcNightKeys = ["arc_dusk", "arc_midnight", "arc_predawn"];
        const sunXs = arcDayKeys.map(k => root.bodyOf(k, "2x1", "weatherSun")?.x);
        const sunNoonY = root.bodyOf("arc_noon", "2x1", "weatherSun")?.y;
        const sunSunriseY = root.bodyOf("arc_sunrise", "2x1", "weatherSun")?.y;
        const arcNoonFields = CardLayouts.weatherFieldsOf(root.fields.arc_noon);
        const weatherLiveCmd = Templates.kind("weatherLive").cmdFor("Tokyo");
        return [
            {
                "name": "every wall tile renders one CardTile",
                "got": root.findAll(wall, it => it.tile !== undefined, []).length,
                "want": root.wallTiles.length
            },
            {
                "name": "an auto-shaped weather tile picks its silhouette from the condition and day/night",
                "got": [root.tileFor("clear_day", "1x1")?.resolvedShape, root.tileFor("clear_night", "1x1")?.resolvedShape, root.tileFor("thunder_day", "1x1")?.resolvedShape, root.tileFor("snow_day", "1x1")?.resolvedShape, root.tileFor("rain_day", "1x1")?.resolvedShape, root.tileFor("fog_day", "1x1")?.resolvedShape],
                "want": ["Sunny", "Circle", "SoftBurst", "Cookie9Sided", "Cookie6Sided", "Pill"]
            },
            {
                "name": "the sky reads its condition and day/night off the compact value",
                "got": [clearDay?.condition, clearDay?.isDay, clearNight?.isDay, thunderDay?.showsThunder, thunderDay?.showsRain, snowNight?.showsSnow],
                "want": ["clear", true, false, true, true, true]
            },
            {
                "name": "heavier rain reads a higher intensity than light rain",
                "got": rainHeavy?.intensity > rainLight?.intensity,
                "want": true
            },
            {
                "name": "a windy reading tilts the falling rain more than a calm one",
                "got": Math.abs(rainWindy?.windTilt ?? 0) > Math.abs(rainCalm?.windTilt ?? 0),
                "want": true
            },
            {
                "name": "a hot reading warms the tone further than a cold one",
                "got": clearHot?.warmth > clearCold?.warmth,
                "want": true
            },
            {
                "name": "the compact value splits into a temperature and the city",
                "got": root.textPartsOf("clear_day", "1x1"),
                "want": ["Barcelona", "22°"]
            },
            {
                "name": "an old cached value ('temp° Condition · City') still renders",
                "got": root.textPartsOf(root.legacyKey, "2x1"),
                "want": ["Lisbon, PT", "9°"]
            },
            {
                "name": "the old weather kind keeps its own silhouette rule and builds no sky",
                "got": [CardLayouts.weatherShape(root.legacyValue), root.skyFor(root.legacyKey, "2x1")],
                "want": ["Cookie6Sided", null]
            },
            {
                "name": "weatherLive is a beta kind listed next to weather in the Live gallery group, with more than one sample to cycle",
                "got": [Templates.galleryGroups.find(g => g.title === "Live").entries.map(e => e.id), Templates.kind("weatherLive").beta, Templates.kind("weatherLive").samples.length > 1],
                "want": [["weather", "weatherLive", "clock", "moon", "sun", "commits", "battery"], true, true]
            },
            {
                "name": "cycling weatherLive's gallery samples changes its silhouette the way a real tile would, clear day through to clear night",
                "got": Templates.kind("weatherLive").samples.map(s => CardLayouts.weatherLiveShape(s.value)),
                "want": ["Sunny", "Cookie6Sided", "Cookie6Sided", "SoftBurst", "Cookie9Sided", "Pill", "Circle", "Sunny", "Sunny"]
            },
            {
                "name": "the compact value carries moon illumination and phase, a crescent waxing and a gibbous also waxing",
                "got": [CardLayouts.weatherFieldsOf(root.fields.clear_night).moonIllum, CardLayouts.weatherFieldsOf(root.fields.clear_night).moonPhase, CardLayouts.weatherFieldsOf(root.fields.clear_full_moon).moonIllum, CardLayouts.weatherFieldsOf(root.fields.clear_full_moon).moonPhase],
                "want": [28, "Waxing Crescent", 96, "Waxing Gibbous"]
            },
            {
                "name": "the sun moves monotonically along its arc as the day progresses, peaking near the top at noon",
                "got": [sunXs.every((x, i) => i === 0 || x > sunXs[i - 1]), sunNoonY < sunSunriseY],
                "want": [true, true]
            },
            {
                "name": "isDay follows sunrise/sunset rather than a fixed clock window",
                "got": arcDayKeys.concat(arcNightKeys).map(k => root.skyFor(k, "1x1")?.isDay),
                "want": [true, true, true, true, true, false, false, false]
            },
            {
                "name": "the compact value parses sunrise, sunset and now in minutes since midnight",
                "got": [arcNoonFields.sunriseMin, arcNoonFields.sunsetMin, arcNoonFields.nowMin],
                "want": [root.sunriseMin, root.sunsetMin, 780]
            },
            {
                "name": "weatherLive's cmdFor reads \"now\" from the city's local clock (%T), not the UTC observation_time",
                "got": [weatherLiveCmd.includes("format=%T"), weatherLiveCmd.includes("--arg now"), weatherLiveCmd.includes("observation_time")],
                "want": [true, true, false]
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
                width: CardLayouts.spanOf(tileItem.modelData.size).cols === 2 ? root.tileUnit * 2 + root.gap : root.tileUnit
                height: root.tileUnit
                account: Statusphere.accountsById["acc-weather"]
                tile: tileItem.modelData
            }
        }
    }
}
