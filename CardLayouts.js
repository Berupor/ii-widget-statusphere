.pragma library

// Tile: { type, field, device, form, size, shape, color, background, onMissing }.
// type: scalar | music | game | photo. field/form apply to scalar only, "*" expands
// to every detail field the standard layout does not already cover. size is one of
// 1x1, 2x1, 2x2, 4x1. shape names a MaterialShape.Shape, or "default" for a rounded
// rect. color is a palette role (primary/secondary/tertiary/error, plus their
// Container variants). background is { kind: color | live | url, value }.
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

// Picked in the editor later (not built yet) - kept in one place so it lands
// there unchanged. Each preset carries its own row and detail tiles.
const presets = {
    "music": {
        "name": "Music-focused",
        "row": [
            tile({
                "type": "music",
                "size": "4x1",
                "shape": "default",
                "color": "primary",
                "background": {
                    "kind": "live",
                    "value": "music"
                },
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "cpu",
                "form": "ring",
                "size": "1x1",
                "shape": "Pill",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "mem",
                "form": "ring",
                "size": "1x1",
                "shape": "Pill",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            })
        ],
        "detail": standardDetail
    },
    "hardware": {
        "name": "Hardware",
        "row": [
            tile({
                "type": "scalar",
                "field": "cpu",
                "form": "ring",
                "size": "2x2",
                "shape": "Cookie6Sided",
                "color": "primaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "mem",
                "form": "bar",
                "size": "2x1",
                "color": "secondaryContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "scalar",
                "field": "disk",
                "form": "bar",
                "size": "2x1",
                "color": "tertiaryContainer",
                "onMissing": "dim"
            })
        ],
        "detail": [
            tile({
                "type": "scalar",
                "field": "cpu",
                "form": "graph",
                "size": "4x1",
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
        ]
    },
    "gamer": {
        "name": "Gamer",
        "row": [
            tile({
                "type": "game",
                "size": "4x1",
                "shape": "default",
                "color": "primary",
                "background": {
                    "kind": "live",
                    "value": "game"
                },
                "onMissing": "hide"
            }),
            tile({
                "type": "scalar",
                "field": "cpu",
                "form": "number",
                "size": "1x1",
                "shape": "Cookie4Sided",
                "color": "errorContainer",
                "onMissing": "dim"
            }),
            tile({
                "type": "photo",
                "size": "1x1",
                "shape": "Arch",
                "color": "secondaryContainer",
                "onMissing": "hide"
            })
        ],
        "detail": standardDetail
    }
};

function get(name) {
    return presets[name] ?? null;
}
