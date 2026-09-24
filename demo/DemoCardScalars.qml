//@ probe statusphere -g 620x620 -s 1500
/**
 * A close-up of the scalar forms at a size where the bar fill, the ring gap
 * and the headline value are actually legible - the friend packs only ever
 * show them shrunk into a 1x1/2x1 cell. Also the text that has to fit: a
 * window title led by a symbol, a single long word, ring captions.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property int now: 1780000000

    readonly property var scalarTiles: [
        CardLayouts.tile({
            "type": "scalar",
            "field": "cpu",
            "form": "bar",
            "size": "2x1",
            "color": "primaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "mem",
            "form": "ring",
            "size": "1x1",
            "color": "secondaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "load",
            "form": "number",
            "size": "1x1",
            "color": "tertiaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "disk",
            "form": "big",
            "size": "1x1",
            "color": "primaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "active_window",
            "form": "text",
            "size": "2x1",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "active_window",
            "form": "text",
            "size": "1x1",
            "color": "tertiaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "word",
            "form": "text",
            "size": "2x1",
            "color": "primaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "disk",
            "form": "ring",
            "size": "1x1",
            "color": "tertiaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "battery",
            "form": "ring",
            "size": "1x1",
            "color": "primaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "scalar",
            "field": "mem",
            "form": "bar",
            "size": "1x1",
            "color": "tertiaryContainer",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "music",
            "form": "wave",
            "size": "2x1",
            "color": "primary",
            "onMissing": "hide"
        }),
        CardLayouts.tile({
            "type": "music",
            "form": "vinyl",
            "size": "1x1",
            "color": "primaryContainer",
            "onMissing": "hide"
        })
    ]

    readonly property string symbolTitle: "◐ Personalization"

    readonly property var room: ({
            "members": [
                {
                    "account_id": "acc-scalars",
                    "device_id": "dev-scalars",
                    "device_name": "desktop",
                    "account_name": "Scalars",
                    "last_seen": root.now,
                    "_layout": {
                        "updated_at": root.now,
                        "row": root.scalarTiles,
                        "detail": []
                    },
                    "cpu_percent": 63,
                    "memory_used_mb": 12288,
                    "memory_total_mb": 16384,
                    "load_avg_1m": 2.4,
                    "cpu_count": 8,
                    "disk_used_percent": 47,
                    "disk_free_gb": 120,
                    "active_window": root.symbolTitle,
                    "spotify_status": "playing",
                    "spotify_track": "Nightcall",
                    "spotify_artist": "Kavinsky",
                    "spotify_position": 40,
                    "spotify_length": 200,
                    "spotify_art_url": String(Qt.resolvedUrl("covers/nightcall.jpg")),
                    "custom_fields": ["word", "battery"],
                    "word": "Donaudampfschifffahrtsgesellschaft",
                    "battery": "82%"
                }
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

    function tileAt(index) {
        return root.findAll(grid, it => it.account !== undefined && it.modelData?.index === index, [])[0] ?? null;
    }

    function part(index, name) {
        return root.findAll(root.tileAt(index), it => it.objectName === name, [])[0] ?? null;
    }

    function ringCaptionClear(index) {
        const value = root.part(index, "ringValue");
        const caption = root.part(index, "ringCaption");
        if (!value || !caption)
            return null;
        const valueBottom = value.mapToItem(null, 0, value.height).y;
        const captionTop = caption.mapToItem(null, 0, 0).y;
        return caption.visible && !caption.truncated && !value.truncated && valueBottom <= captionTop;
    }

    function waveBandInside(index) {
        const line = root.findAll(root.tileAt(index), it => it.valueBarHeight !== undefined && it.visible, [])[0] ?? null;
        if (!line)
            return null;
        let box = line.parent;
        while (box && !box.clip)
            box = box.parent;
        const reach = line.valueBarHeight / 2 + line.valueBarHeight * line.waveAmplitudeMultiplier;
        const centre = line.mapToItem(box, 0, line.height / 2).y;
        return centre - reach >= -0.5 && centre + reach <= box.height + 0.5;
    }

    function checks() {
        const wideTitle = root.part(4, "textValue");
        const narrowTitle = root.part(5, "textValue");
        const word = root.part(6, "textValue");
        return [
            {
                "name": "every fixture tile places on the grid",
                "got": grid.placed.length,
                "want": root.scalarTiles.length
            },
            {
                "name": "a leading symbol stays on the line of its word in a 2x1 text tile",
                "got": [wideTitle?.lineCount, wideTitle?.truncated],
                "want": [1, false]
            },
            {
                "name": "a leading symbol stays on the line of its word when a 1x1 tile has to squeeze it",
                "got": [narrowTitle?.lineCount, narrowTitle?.truncated],
                "want": [1, false]
            },
            {
                "name": "only a lone symbol or emoji is glued to its word, plain words keep their space",
                "got": ["◐ Personalization", "driving home 🎧", "🇯🇵 Tokyo", "Somewhere new", "up 3 hours"].map(t => root.tileAt(4)?.withSymbolsAttached(t)),
                "want": ["◐\u00A0Personalization", "driving home\u00A0🎧", "🇯🇵\u00A0Tokyo", "Somewhere new", "up 3 hours"]
            },
            {
                "name": "a long single word shrinks instead of eliding",
                "got": [word?.truncated, word?.lineCount, (word?.fontInfo.pixelSize ?? 99) < Appearance.font.pixelSize.huge],
                "want": [false, 1, true]
            },
            {
                "name": "a ring caption is the short label, not the free-space note",
                "got": root.part(7, "ringCaption")?.text,
                "want": "Disk"
            },
            {
                "name": "ring captions sit below the value, whole",
                "got": [root.ringCaptionClear(1), root.ringCaptionClear(7), root.ringCaptionClear(8)],
                "want": [true, true, true]
            },
            {
                "name": "a wave line keeps its troughs: the whole wave sits inside the tile, in a 2x1 bar, a 1x1 bar and the music wave",
                "got": [root.waveBandInside(0), root.waveBandInside(9), root.waveBandInside(10)],
                "want": [true, true, true]
            },
            {
                "name": "with a known track length the vinyl shows its progress ring",
                "got": root.findAll(root.tileAt(11), it => it.lineWidth !== undefined && it.value !== undefined && it.visible, []).length,
                "want": 1
            },
            {
                "name": "the bar tile's fill percent comes from cpu_percent",
                "got": Statusphere.fieldFor(Statusphere.deviceForTile(Statusphere.accountsById["acc-scalars"], root.scalarTiles[0]), "cpu")?.percent,
                "want": 63
            },
            {
                "name": "the ring tile's fill percent comes from the memory used/total ratio, not a fixed value",
                "got": Statusphere.fieldFor(Statusphere.deviceForTile(Statusphere.accountsById["acc-scalars"], root.scalarTiles[1]), "mem")?.percent,
                "want": 75
            }
        ];
    }

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    CardGrid {
        id: grid
        anchors.fill: parent
        anchors.margins: 16
        account: Statusphere.accountsById["acc-scalars"]
        tiles: root.scalarTiles
        maxRows: 4
    }
}
