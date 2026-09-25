.pragma library

// Every tile type and its forms. A form's file is the component CardTile loads for it;
// fullBleed paints its own background instead of the tile's silhouette and colour, and
// is the only kind a pack thumbnail draws. autoShape picks the silhouette when a tile's
// shape is "auto", from the value it shows. A type with no forms draws nothing but art.
const tileTypes = {
    "scalar": {
        "label": "",
        "needsField": true,
        "defaultForm": "text",
        "forms": {
            "ring": {
                "label": "Ring",
                "file": "TileRing.qml"
            },
            "dial": {
                "label": "Dial",
                "file": "TileDial.qml"
            },
            "bar": {
                "label": "Bar",
                "file": "TileBar.qml"
            },
            "number": {
                "label": "Number",
                "file": "TileNumber.qml"
            },
            "text": {
                "label": "Text",
                "file": "TileText.qml"
            },
            "big": {
                "label": "Sticker",
                "file": "TileSticker.qml"
            },
            "clock": {
                "label": "Clock",
                "file": "TileClock.qml",
                "autoShape": clockShape
            },
            "weather": {
                "label": "Weather",
                "file": "TileWeather.qml",
                "autoShape": weatherShape
            },
            "weatherLive": {
                "label": "Live weather",
                "file": "TileWeatherLive.qml",
                "autoShape": weatherLiveShape,
                "sky": true
            },
            "moon": {
                "label": "Moon",
                "file": "TileSticker.qml"
            },
            "sun": {
                "label": "Sun",
                "file": "TileText.qml"
            }
        },
        "hasData": (data, account, t) => data.fieldFor(data.deviceForTile(account, t), t.field) !== null
    },
    "music": {
        "label": "Music",
        "reads": "music",
        "defaultForm": "cover",
        "forms": {
            "cover": {
                "label": "Cover",
                "file": "TileCover.qml",
                "fullBleed": true
            },
            "vinyl": {
                "label": "Vinyl",
                "file": "TileVinyl.qml"
            },
            "wave": {
                "label": "Wave",
                "file": "TileWave.qml"
            }
        },
        "hasData": (data, account) => data.musicDevices(account).length > 0
    },
    "game": {
        "label": "Game",
        "reads": "game",
        "defaultForm": "banner",
        "forms": {
            "banner": {
                "label": "Banner",
                "file": "TileBanner.qml",
                "fullBleed": true
            },
            "timer": {
                "label": "Session",
                "file": "TileTimer.qml"
            }
        },
        "hasData": (data, account) => data.gameDevices(account).length > 0
    },
    "video": {
        "label": "Video",
        "reads": "video",
        "defaultForm": "player",
        "forms": {
            "player": {
                "label": "Player",
                "file": "TileVideo.qml"
            }
        },
        "hasData": (data, account) => data.videoDevices(account).length > 0
    },
    "alarm": {
        "label": "Alarm",
        "reads": "alarm",
        "defaultForm": "clock",
        "forms": {
            "clock": {
                "label": "Clock",
                "file": "TileAlarm.qml"
            }
        },
        "hasData": (data, account) => data.alarmDevices(account).length > 0
    },
    "meeting": {
        "label": "Meeting",
        "reads": "meeting",
        "defaultForm": "banner",
        "forms": {
            "banner": {
                "label": "Banner",
                "file": "TileMeeting.qml"
            }
        },
        "hasData": (data, account) => data.meetingDevices(account).length > 0
    },
    "photo": {
        "label": "Photo",
        "art": "photo",
        "defaultForm": "",
        "forms": {},
        "hasData": (data, account) => data.currentPhotoFor(account) !== null
    },
    "picture": {
        "label": "Picture",
        "art": "picture",
        "defaultForm": "",
        "forms": {},
        "sanitize": t => Object.assign({}, t, {
            "url": pictureUrlOf(t)
        }),
        "hasData": (data, account, t) => pictureUrlOf(t) !== ""
    }
};

const noForm = {
    "label": "",
    "file": "",
    "fullBleed": true
};

function typeOf(t) {
    return tileTypes[t?.type] ?? null;
}

function formOf(t) {
    const type = typeOf(t);
    if (!type)
        return noForm;
    return type.forms[t.form] ?? type.forms[type.defaultForm] ?? noForm;
}

function formNamesOf(typeName) {
    return Object.keys(tileTypes[typeName]?.forms ?? {});
}

function isHttpsUrl(url) {
    return typeof url === "string" && /^https:\/\/\S+$/.test(url);
}

function pictureUrlOf(t) {
    return isHttpsUrl(t?.url) ? t.url : "";
}

function clockShape(value) {
    const m = String(value).match(/^(\d{1,2}):/);
    const hour = m ? parseInt(m[1], 10) : -1;
    return hour >= 6 && hour < 19 ? "Sunny" : "Circle";
}

function weatherShape(value) {
    const v = String(value).toLowerCase();
    if (/storm|thunder/.test(v))
        return "SoftBurst";
    if (/fog|mist/.test(v))
        return "Pill";
    if (/snow|ice|blizzard/.test(v))
        return "Cookie9Sided";
    if (/drizzle|sleet|overcast|cloud|rain/.test(v))
        return "Cookie6Sided";
    if (/clear|sun/.test(v))
        return "Sunny";
    return "Circle";
}

// Keep in sync with Templates.weatherJqFilter.
const weatherCompactPattern = /^(-?\d+);(\d+);(\d+(?:\.\d+)?);(\d+(?:\.\d+)?);(\d+(?:\.\d+)?);([01]);(\d+);([^;]*);(\d+);(\d+);(\d+);(.*)$/;

function weatherFieldsOf(value) {
    const m = weatherCompactPattern.exec(String(value));
    if (!m)
        return null;
    return {
        "temp": parseInt(m[1], 10),
        "code": parseInt(m[2], 10),
        "precipMM": parseFloat(m[3]),
        "windKmph": parseFloat(m[4]),
        "windDirDeg": parseFloat(m[5]),
        "isDay": m[6] === "1",
        "moonIllum": parseInt(m[7], 10),
        "moonPhase": m[8],
        "sunriseMin": parseInt(m[9], 10),
        "sunsetMin": parseInt(m[10], 10),
        "nowMin": parseInt(m[11], 10),
        "city": m[12]
    };
}

// wttr.in's weatherCode -> condition, https://www.worldweatheronline.com/weather-api/api/docs/weather-icons.aspx
const weatherConditionByCode = {
    113: "clear",
    116: "clouds",
    119: "clouds",
    122: "clouds",
    143: "fog",
    176: "rain",
    179: "snow",
    182: "snow",
    185: "snow",
    200: "clouds",
    227: "snow",
    230: "snow",
    248: "fog",
    260: "fog",
    263: "rain",
    266: "rain",
    281: "rain",
    284: "rain",
    293: "rain",
    296: "rain",
    299: "rain",
    302: "rain",
    305: "rain",
    308: "rain",
    311: "rain",
    314: "rain",
    317: "snow",
    320: "snow",
    323: "snow",
    326: "snow",
    329: "snow",
    332: "snow",
    335: "snow",
    338: "snow",
    350: "snow",
    353: "rain",
    356: "rain",
    359: "rain",
    362: "snow",
    365: "snow",
    368: "snow",
    371: "snow",
    374: "snow",
    377: "snow",
    386: "thunder",
    389: "thunder",
    392: "thunder",
    395: "thunder"
};

const possiblePrecipCodes = new Set([176, 179, 182, 185]);

function weatherConditionOf(value) {
    const fields = weatherFieldsOf(value);
    if (!fields)
        return null;
    if (possiblePrecipCodes.has(fields.code) && !(fields.precipMM > 0))
        return "clouds";
    return weatherConditionByCode[fields.code] ?? null;
}

function weatherLiveShape(value) {
    const condition = weatherConditionOf(value);
    switch (condition) {
    case "thunder":
        return "SoftBurst";
    case "snow":
        return "Cookie9Sided";
    case "rain":
    case "clouds":
        return "Cookie6Sided";
    case "fog":
        return "Pill";
    case "clear":
        return (weatherFieldsOf(value)?.isDay ?? true) ? "Sunny" : "Circle";
    default:
        return "Circle";
    }
}

// Names out of MaterialShape.Shape, plus SineCookie which isn't one - CardTile and
// PresenceAvatar special-case it by name. "default" is the rounded rect, "auto" defers to the form.
const shapes = ["Circle", "Pill", "Arch", "SemiCircle", "Diamond", "Pentagon", "Cookie4Sided", "Cookie6Sided", "Cookie9Sided", "Clover4Leaf", "Heart", "Sunny", "SoftBurst", "SineCookie"];
const shapeChoices = ["default", "auto"].concat(shapes);

function resolvedShape(t, value) {
    const span = spanOf(t.size);
    if (span.cols !== span.rows)
        return "default";
    if (t.shape !== "auto")
        return shapes.includes(t.shape) || t.shape === "default" ? t.shape : "Circle";
    return formOf(t).autoShape?.(value) ?? "Circle";
}

const fitKinds = ["cover", "blur", "stretch"];

function fitOf(t) {
    return fitKinds.includes(t?.fit) ? t.fit : "cover";
}

// Palette role -> [fill, content on it], keys of Appearance.colors.
const colorRoles = {
    "primary": ["colPrimary", "colOnPrimary"],
    "secondary": ["colSecondary", "colOnSecondary"],
    "tertiary": ["colTertiary", "colOnTertiary"],
    "error": ["colError", "colOnError"],
    "primaryContainer": ["colPrimaryContainer", "colOnPrimaryContainer"],
    "secondaryContainer": ["colSecondaryContainer", "colOnSecondaryContainer"],
    "tertiaryContainer": ["colTertiaryContainer", "colOnTertiaryContainer"],
    "errorContainer": ["colErrorContainer", "colOnErrorContainer"]
};
const unknownColorRole = ["colLayer2", "colOnLayer2"];

function colorKeysOf(role) {
    return colorRoles[role] ?? unknownColorRole;
}

function tile(props) {
    return Object.assign({
        field: "",
        device: null,
        form: tileTypes[props.type]?.defaultForm ?? "",
        shape: "default",
        color: "secondaryContainer",
        onMissing: "hide"
    }, props);
}

const backgroundKinds = ["live", "url"];

function withKnownBackground(t) {
    const bg = t.background;
    if (bg === undefined)
        return t;
    if (backgroundKinds.includes(bg?.kind) && (bg.kind !== "url" || isHttpsUrl(bg.value)))
        return t;
    const out = Object.assign({}, t);
    delete out.background;
    return out;
}

// Keep in agreement with the Go client: layout.FileName, custom fileName, presence.KeyLayout.
const layoutFileName = "layout.json";
const customFileName = "custom.json";
const layoutKey = "_layout";

const columns = 4;
const rowRows = 2;
const detailRows = 4;
const gap = 8;
const shortValueLength = 8;
const wideTextFields = ["active_window"];

const spans = {
    "1x1": {
        "cols": 1,
        "rows": 1,
        "icon": "crop_square"
    },
    "2x1": {
        "cols": 2,
        "rows": 1,
        "icon": "crop_landscape"
    },
    "2x2": {
        "cols": 2,
        "rows": 2,
        "icon": "grid_on"
    },
    "4x1": {
        "cols": 4,
        "rows": 1,
        "icon": "view_agenda"
    }
};
const sizes = Object.keys(spans);

function spanOf(size) {
    return spans[size] ?? spans["1x1"];
}

// First-fit top-left packing into a columns-wide grid: a tile with nowhere left to go
// is dropped rather than overflowing maxRows, so a full grid degrades instead of
// clipping. index points back into tiles.
function pack(tiles, maxRows) {
    const occupied = [];
    const free = (col, row, span) => {
        for (let r = row; r < row + span.rows; r++) {
            for (let c = col; c < col + span.cols; c++) {
                if (occupied[r]?.[c])
                    return false;
            }
        }
        return true;
    };
    const placed = [];
    tiles.forEach((t, index) => {
        const span = spanOf(t.size);
        let spot = null;
        for (let row = 0; row + span.rows <= maxRows && !spot; row++) {
            for (let col = 0; col + span.cols <= columns && !spot; col++) {
                if (free(col, row, span))
                    spot = {
                        "col": col,
                        "row": row
                    };
            }
        }
        if (!spot)
            return;
        for (let r = spot.row; r < spot.row + span.rows; r++) {
            occupied[r] = occupied[r] ?? [];
            for (let c = spot.col; c < spot.col + span.cols; c++)
                occupied[r][c] = true;
        }
        placed.push(Object.assign({
            "tile": t,
            "index": index,
            "cols": span.cols,
            "rows": span.rows
        }, spot));
    });
    return placed;
}

function rowsUsed(placed) {
    return placed.reduce((max, p) => Math.max(max, p.row + p.rows), 0);
}

function emptyCells(placed) {
    return rowsUsed(placed) * columns - placed.reduce((sum, p) => sum + p.cols * p.rows, 0);
}

const gaugeColors = ["primaryContainer", "tertiaryContainer"];

function standardTileFor(field, gaugeIndex) {
    if (field.percent !== null && field.percent !== undefined)
        return tile({
            "type": "scalar",
            "field": field.key,
            "form": "ring",
            "size": "1x1",
            "color": gaugeColors[gaugeIndex % gaugeColors.length]
        });
    const wide = wideTextFields.includes(field.key) || String(field.value).length > shortValueLength;
    return tile({
        "type": "scalar",
        "field": field.key,
        "form": wide ? "text" : "number",
        "size": wide ? "2x1" : "1x1"
    });
}

const heroesFirst = ["2x2", "2x1", "1x1", "4x1"];

// Rings first, then number tiles, grow to 2x2 heroes; the first text can take the whole
// row. Big tiles lead so the small ones fill in around them.
function grown(tiles, heroes, widenText) {
    const heroTiles = tiles.filter(t => t.form === "ring").concat(tiles.filter(t => t.form === "number")).slice(0, heroes);
    const text = widenText ? tiles.find(t => t.size === "2x1") : null;
    const out = tiles.map(t => heroTiles.includes(t) ? Object.assign({}, t, {
                "size": "2x2"
            }) : t === text ? Object.assign({}, t, {
                "size": "4x1"
            }) : t);
    return heroesFirst.reduce((sorted, size) => sorted.concat(out.filter(t => t.size === size)), []);
}

function scoresBelow(a, b) {
    const i = a.findIndex((v, k) => v !== b[k]);
    return i >= 0 && a[i] < b[i];
}

// The fallback detail card for a device with no _layout of its own: rings for
// percentages, number tiles for short values, text for long ones. Of the ways to grow
// a few of them, the one that packs with the fewest holes wins, then the one that drops
// the fewest tiles, then the one that changes the least. fields is
// Statusphere.detailFieldsFor(account).
// An empty detail surface - no _layout, or one whose detail tiles are all missing or
// invalid - reads the same as the standard card everywhere it's shown: on the friend's
// card and in the owner's own editor preview.
function fallbackDetail(tiles, fields) {
    return tiles.length > 0 ? tiles : standardDetailFor(fields);
}

function standardDetailFor(fields) {
    let gauges = 0;
    const tiles = fields.map(f => standardTileFor(f, f.percent !== null && f.percent !== undefined ? gauges++ : 0));
    let best = null;
    for (const widenText of [false, true]) {
        for (let heroes = 0; heroes <= 3; heroes++) {
            const candidate = grown(tiles, heroes, widenText);
            const placed = pack(candidate, detailRows);
            const score = [emptyCells(placed), candidate.length - placed.length, heroes + (widenText ? 1 : 0)];
            if (!best || scoresBelow(score, best.score))
                best = {
                    "tiles": candidate,
                    "score": score
                };
        }
    }
    return best?.tiles ?? [];
}

const packNames = {
    "nightOwl": "Night Owl",
    "musicHead": "Music Head",
    "traveler": "Traveler",
    "coder": "Coder",
    "minimal": "Minimal"
};

// A pack not listed here keeps the avatar's own default (Circle).
const packAvatarShapes = {
    "nightOwl": "SoftBurst",
    "musicHead": "SineCookie",
    "traveler": "Arch",
    "coder": "Diamond"
};

const packs = {
    "row": {
        "nightOwl": [
            tile({
                "type": "scalar",
                "field": "local_time",
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "active_window",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "moon",
                "form": "moon",
                "size": "1x1",
                "color": "primaryContainer",
                "onMissing": "hide"
            })
        ],
        "musicHead": [
            tile({
                "type": "music",
                "form": "vinyl",
                "size": "1x1",
                "color": "primaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "into_lately",
                "form": "big",
                "size": "2x1",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "local_time",
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            })
        ],
        "traveler": [
            tile({
                "type": "photo",
                "size": "2x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "local_time",
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "weather",
                "form": "weather",
                "size": "1x1",
                "shape": "auto",
                "color": "primaryContainer",
                "onMissing": "hide"
            })
        ],
        "coder": [
            tile({
                "type": "scalar",
                "field": "active_window",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "cpu",
                "form": "ring",
                "size": "1x1",
                "shape": "Pill",
                "color": "primaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "workspace",
                "form": "number",
                "size": "1x1",
                "onMissing": "hide"
            })
        ],
        "minimal": [
            tile({
                "type": "scalar",
                "field": "quote",
                "form": "big",
                "size": "4x1",
                "color": "secondaryContainer",
                "onMissing": "dim"
            })
        ]
    },
    "detail": {
        "nightOwl": [
            tile({
                "type": "game",
                "form": "banner",
                "size": "4x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "music",
                "form": "wave",
                "size": "4x1",
                "color": "primary",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "active_app",
                "form": "text",
                "size": "2x1",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "uptime",
                "form": "number",
                "size": "1x1",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "weather",
                "form": "weather",
                "size": "1x1",
                "shape": "auto",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "moon",
                "form": "moon",
                "size": "1x1",
                "color": "primaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "local_time",
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "sun",
                "form": "sun",
                "size": "2x1",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            })
        ],
        "musicHead": [
            tile({
                "type": "music",
                "form": "cover",
                "size": "4x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "into_lately",
                "form": "big",
                "size": "2x2",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "local_time",
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "primaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "weather",
                "form": "weather",
                "size": "1x1",
                "shape": "auto",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "uptime",
                "form": "number",
                "size": "2x1",
                "color": "primaryContainer",
                "onMissing": "dim"
            })
        ],
        "traveler": [
            tile({
                "type": "photo",
                "size": "2x2",
                "color": "secondaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "weather",
                "form": "weather",
                "size": "2x2",
                "shape": "auto",
                "color": "primaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "local_time",
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "sun",
                "form": "sun",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "where_i_am",
                "form": "big",
                "size": "2x1",
                "color": "secondaryContainer",
                "onMissing": "dim"
            })
        ],
        "coder": [
            tile({
                "type": "scalar",
                "field": "active_app",
                "form": "big",
                "size": "2x2",
                "color": "primaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "package_count",
                "form": "number",
                "size": "2x1",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "load",
                "form": "number",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "local_time",
                "form": "clock",
                "size": "1x1",
                "shape": "auto",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "music",
                "form": "wave",
                "size": "4x1",
                "color": "tertiary",
                "onMissing": "hide"
            })
        ],
        "minimal": [
            tile({
                "type": "scalar",
                "field": "mood",
                "form": "big",
                "size": "2x2",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "local_time",
                "form": "clock",
                "size": "2x2",
                "shape": "auto",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "weather",
                "form": "weather",
                "size": "4x1",
                "color": "secondaryContainer",
                "onMissing": "dim"
            })
        ]
    }
};

function rowsFor(surface) {
    return surface === "detail" ? detailRows : rowRows;
}

function packsFor(surface) {
    const tilesById = packs[surface] ?? {};
    return Object.keys(tilesById).map(id => ({
                "id": id,
                "name": packNames[id],
                "tiles": tilesById[id],
                "avatarShape": packAvatarShapes[id] ?? "Circle"
            }));
}

function packFor(surface, id) {
    return packsFor(surface).find(p => p.id === id) ?? null;
}
