.pragma library

// Tile: { type, field, device, form, size, shape, color, background, onMissing }.
// type: scalar | music | game | photo. music/game read form for a sub-variant: music
// is cover (default, full embed) | vinyl (spinning cover, ring progress) | wave
// (visualizer strip); game is banner (default, full embed) | timer (icon and session
// line). field/form apply to scalar only, "*" expands to every detail field the
// standard layout does not already cover. Scalar forms: ring, bar, number, text, big
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

const standardDetail = [
    tile({
        "type": "scalar",
        "field": "cpu",
        "form": "bar",
        "size": "2x1",
        "color": "primary"
    }),
    tile({
        "type": "scalar",
        "field": "mem",
        "form": "bar",
        "size": "2x1",
        "color": "secondary"
    }),
    tile({
        "type": "scalar",
        "field": "disk",
        "form": "bar",
        "size": "2x1",
        "color": "tertiary"
    }),
    tile({
        "type": "scalar",
        "field": "*",
        "form": "text",
        "size": "4x1"
    })
];

// A friend's pack: self-expression, not a system monitor. Music, game and photo carry
// the personality; the six fields the cli always sends (cpu, mem, disk, load, uptime,
// workspace) are the only scalars a pack can lean on, since nothing else is guaranteed
// to arrive without the friend hand-writing a custom.json. Picked in the editor later -
// kept in one place so it lands there unchanged.
const presets = {
    "nightOwl": {
        "name": "Night Owl",
        "row": [
            tile({
                "type": "game",
                "form": "banner",
                "size": "4x1",
                "shape": "default",
                "color": "primary",
                "background": {
                    "kind": "live",
                    "value": "game"
                },
                "onMissing": "hide"
            })
        ],
        "detail": [
            tile({
                "type": "game",
                "form": "timer",
                "size": "2x1",
                "color": "primaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "uptime",
                "form": "ring",
                "size": "2x2",
                "color": "secondaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "load",
                "form": "number",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "workspace",
                "form": "big",
                "size": "1x1",
                "color": "primary",
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
                "field": "mem",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "cpu",
                "form": "number",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "disk",
                "form": "big",
                "size": "1x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            })
        ],
        "detail": [
            tile({
                "type": "scalar",
                "field": "load",
                "form": "ring",
                "size": "2x2",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "uptime",
                "form": "big",
                "size": "2x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "workspace",
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
                "field": "cpu",
                "form": "ring",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "load",
                "form": "number",
                "size": "1x1",
                "color": "primaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "mem",
                "form": "big",
                "size": "1x1",
                "color": "tertiary",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "uptime",
                "form": "number",
                "size": "1x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            })
        ],
        "detail": [
            tile({
                "type": "scalar",
                "field": "disk",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "workspace",
                "form": "big",
                "size": "2x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            })
        ]
    },
    "coder": {
        "name": "Coder",
        "row": [
            tile({
                "type": "scalar",
                "field": "disk",
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
                "field": "mem",
                "form": "ring",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "uptime",
                "form": "text",
                "size": "2x1",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "load",
                "form": "big",
                "size": "1x1",
                "color": "primaryContainer",
                "onMissing": "hide"
            })
        ]
    },
    "minimal": {
        "name": "Minimal",
        "row": [
            tile({
                "type": "scalar",
                "field": "uptime",
                "form": "big",
                "size": "2x1",
                "color": "secondaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "cpu",
                "form": "number",
                "size": "1x1",
                "color": "tertiaryContainer",
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "load",
                "form": "number",
                "size": "1x1",
                "color": "primaryContainer",
                "onMissing": "hide"
            })
        ],
        "detail": [
            tile({
                "type": "scalar",
                "field": "mem",
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
