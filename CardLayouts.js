.pragma library

// Tile: { type, field, device, form, size, shape, color, background, onMissing }.
// type: scalar | music | game | photo. music/game read form for a sub-variant: music
// is cover (default, full embed) | vinyl (spinning cover, ring progress) | wave
// (progress line); game is banner (default, full embed) | timer (icon and session
// line). field/form apply to scalar only, "*" expands to every detail field the
// layout does not already name. Scalar forms: ring, bar, number, text, big
// (large centred value, a sticker), clock (big value, meant for a pre-rendered
// "HH:MM" custom field), weather (temperature pulled out of the value, the rest as a
// caption). size is one of 1x1, 2x1, 2x2, 4x1. shape names a MaterialShape.Shape,
// "default" for a rounded rect, or "auto" to let a clock/weather tile pick day/night
// or condition itself. color is a palette role (primary/secondary/tertiary/error,
// plus their Container variants). background is { kind: color | live | url, value }.
function tile(props) {
    return Object.assign({
        field: "",
        device: null,
        form: "text",
        shape: "default",
        color: "secondaryContainer",
        background: {
            "kind": "color",
            "value": "secondaryContainer"
        },
        onMissing: "hide"
    }, props);
}

const columns = 4;
const detailRows = 4;
const shortValueLength = 8;
const wideTextFields = ["active_window"];

const spans = {
    "1x1": {
        "cols": 1,
        "rows": 1
    },
    "2x1": {
        "cols": 2,
        "rows": 1
    },
    "2x2": {
        "cols": 2,
        "rows": 2
    },
    "4x1": {
        "cols": 4,
        "rows": 1
    }
};

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
            "index": index
        }, spot, span));
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
    return ["2x2", "2x1", "1x1", "4x1"].reduce((sorted, size) => sorted.concat(out.filter(t => t.size === size)), []);
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
// the personality, active_app/active_window/package_count read what the cli already
// collects about the machine's own use, and a custom.json field (mood, quote, a hand-
// rolled local clock) reaches for whatever the friend shells out for - onMissing "hide"
// or "dim" lets a pack name a field before it exists. System metrics (cpu/mem/disk/
// load/uptime/workspace) stay a small accent, at most one or two a pack, some none at
// all. Picked in the editor later - kept in one place so it lands there unchanged.
const presets = {
    // Late, not necessarily gaming: what's playing and what's open right now, plus how
    // long the machine's been up as the one hint of the hour.
    "nightOwl": {
        "name": "Night Owl",
        "row": [
            tile({
                "type": "music",
                "form": "wave",
                "size": "4x1",
                "color": "primary",
                "onMissing": "hide"
            })
        ],
        "detail": [
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
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "uptime",
                "form": "number",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            })
        ]
    },
    // Vinyl is the one place the track shows: the row's other tiles and the
    // detail card stay off spotify_* so the same song doesn't repeat three times.
    "musicHead": {
        "name": "Music Head",
        "row": [
            tile({
                "type": "music",
                "form": "vinyl",
                "size": "2x2",
                "shape": "default",
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
            }),
            tile({
                "type": "scalar",
                "field": "quote",
                "form": "big",
                "size": "1x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            })
        ],
        "detail": [
            tile({
                "type": "scalar",
                "field": "listening",
                "form": "number",
                "size": "2x2",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "playlist",
                "form": "big",
                "size": "2x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "genre",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            })
        ]
    },
    "traveler": {
        "name": "Traveler",
        "row": [
            tile({
                "type": "photo",
                "size": "2x2",
                "shape": "default",
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
            }),
            tile({
                "type": "scalar",
                "field": "flag",
                "form": "big",
                "size": "1x1",
                "color": "tertiary",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "trip_day",
                "form": "number",
                "size": "1x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            })
        ],
        "detail": [
            tile({
                "type": "scalar",
                "field": "region",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "distance",
                "form": "number",
                "size": "1x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "caption",
                "form": "big",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            })
        ]
    },
    // What the machine is for: what's open, where, how many packages it carries - cpu
    // and mem stay a one-tile-each accent, not the point.
    "coder": {
        "name": "Coder",
        "row": [
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
        "detail": [
            tile({
                "type": "scalar",
                "field": "active_app",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "package_count",
                "form": "number",
                "size": "1x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "mem",
                "form": "ring",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            })
        ]
    },
    "minimal": {
        "name": "Minimal",
        "row": [
            tile({
                "type": "scalar",
                "field": "quote",
                "form": "big",
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
                "field": "since",
                "form": "number",
                "size": "1x1",
                "color": "primaryContainer",
                "onMissing": "hide"
            })
        ],
        "detail": [
            tile({
                "type": "scalar",
                "field": "mood",
                "form": "text",
                "size": "4x1",
                "onMissing": "hide"
            })
        ]
    }
};

function get(name) {
    return presets[name] ?? null;
}

function names() {
    return Object.keys(presets);
}
