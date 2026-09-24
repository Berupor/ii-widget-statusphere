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

function pictureUrlOf(t) {
    const url = t?.url;
    return typeof url === "string" && /^https:\/\/\S+$/.test(url) ? url : "";
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
    if (/snow/.test(v))
        return "Cookie9Sided";
    if (/rain|cloud/.test(v))
        return "Cookie6Sided";
    if (/clear|sun/.test(v))
        return "Sunny";
    return "Circle";
}

// Names out of MaterialShape.Shape; "default" is the rounded rect, "auto" defers to the form.
const shapes = ["Circle", "Pill", "Arch", "SemiCircle", "Diamond", "Pentagon", "Cookie4Sided", "Cookie6Sided", "Cookie9Sided", "Clover4Leaf", "Heart", "Sunny", "SoftBurst"];
const shapeChoices = ["default", "auto"].concat(shapes);

function resolvedShape(t, value) {
    if (t.shape !== "auto")
        return shapes.includes(t.shape) || t.shape === "default" ? t.shape : "Circle";
    return formOf(t).autoShape?.(value) ?? "Circle";
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
        background: {
            "kind": "color",
            "value": "secondaryContainer"
        },
        onMissing: "hide"
    }, props);
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

// A friend's pack: self-expression, not a system monitor. Music, game and photo carry
// the personality, active_app/active_window/workspace read what the cli already
// collects about the machine's own use, and a custom.json field (mood, quote, a local
// clock, the weather) reaches for whatever the friend shells out for. System metrics
// (cpu/mem/disk/load/uptime/package_count) stay an accent, at most two a pack. A row
// pack is the one line every friend sees in the room list, so it fills exactly one row;
// a detail pack fills three or four. No field twice in a pack and no holes in its grid,
// while a row pack and a detail pack may name the same field.
const packNames = {
    "nightOwl": "Night Owl",
    "musicHead": "Music Head",
    "traveler": "Traveler",
    "coder": "Coder",
    "minimal": "Minimal"
};

// What a "Your text" field a pack names starts out as, so it has a custom.json entry and
// a value from the moment the pack is applied. Weather and clock forms get their
// template instead.
const packTexts = {
    "mood": "🌙",
    "quote": "back in five",
    "top_artist": "Robyn",
    "streak": "9",
    "playlist": "Neon Drive",
    "flag": "🇯🇵",
    "trip_day": "4",
    "caption": "temple steps"
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
                "field": "mood",
                "form": "big",
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
                "field": "top_artist",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "streak",
                "form": "number",
                "size": "1x1",
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
                "onMissing": "hide"
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
                "field": "playlist",
                "form": "big",
                "size": "2x2",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "top_artist",
                "form": "text",
                "size": "2x1",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "streak",
                "form": "number",
                "size": "1x1",
                "color": "primaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "mood",
                "form": "big",
                "size": "1x1",
                "color": "secondaryContainer",
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
                "field": "flag",
                "form": "big",
                "size": "1x1",
                "color": "tertiary",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "caption",
                "form": "big",
                "size": "1x1",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "trip_day",
                "form": "number",
                "size": "1x1",
                "color": "primaryContainer",
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
                "tiles": tilesById[id]
            }));
}

function packFor(surface, id) {
    return packsFor(surface).find(p => p.id === id) ?? null;
}
