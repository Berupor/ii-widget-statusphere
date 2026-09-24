//@ probe statusphere -g 480x400 -s 1500
/**
 * Pins the card editor's file contract and the interactions the properties
 * panel drives through: "Save my card" writes the row and detail tiles to
 * ~/.config/statusphere/layout.json with a fresh updated_at, and a typed
 * custom-field value to custom.json alongside it, leaving that file's other
 * keys untouched. A drag drop reorders the array (not just the on-screen
 * packing), a colour swatch and the "keep place when empty" switch write
 * through updateSelectedTile the same way a click on either would, and a
 * value typed into a custom-field tile reaches the live preview before
 * Save is ever clicked.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import Quickshell.Io
import QtQuick

Item {
    id: root
    clip: true
    readonly property string layoutPath: `${Directories.config}/statusphere/layout.json`
    readonly property string customFieldsPath: `${Directories.config}/statusphere/custom.json`

    // Captured once, synchronously, so the checks below can pin a moment in time instead
    // of just the settled end state.
    property bool addedCoffee: false
    property bool addedCoffeeAgain: false
    property int detailLenAfterAdd: 0
    property bool previewShowsLatteBeforeSave: false
    property bool wroteCoffeeBeforeSave: true

    // What the editor's "Source" list and live preview read from: a self account with
    // real hardware numbers and a couple of custom.json fields, so both show something
    // other than dashes even where this machine has no statusphere agent registered.
    readonly property var selfRoom: ({
            "members": [
                {
                    "account_id": "acc-owner",
                    "device_id": "dev-owner",
                    "device_name": "desktop",
                    "account_name": "Me",
                    "last_seen": 1780000000,
                    "cpu_percent": 37,
                    "memory_used_mb": 9216,
                    "memory_total_mb": 32768,
                    "disk_used_percent": 61,
                    "disk_free_gb": 180,
                    "custom_fields": ["project", "mood"],
                    "project": "statusphere-editor",
                    "mood": "focused"
                }
            ]
        })

    // Which editor the shot frames, the other one sits just outside it: both stay visible
    // so their checks see what a user would. `-p shownEditor=empty` shoots the empty one.
    property string shownEditor: "selected"

    StatusphereSettings {
        id: editor
        x: root.shownEditor === "selected" ? 0 : root.width
        width: 400
    }

    StatusphereSettings {
        id: emptyEditor
        x: root.shownEditor === "empty" ? 0 : root.width
        width: 400
    }

    FileView {
        id: check
        path: root.layoutPath
        printErrors: false
        watchChanges: true
    }

    FileView {
        id: customCheck
        path: root.customFieldsPath
        printErrors: false
        watchChanges: true
    }

    Timer {
        interval: 300
        running: true
        onTriggered: {
            check.reload();
            customCheck.reload();
            // Re-asserted after the config.json read a real registered machine might
            // have finishes, so the shot stays the same self account on every machine.
            Statusphere.ingest(JSON.stringify(root.selfRoom));
            Statusphere.selfAccountId = "acc-owner";
        }
    }

    function tile(field, color) {
        return {
            "type": "scalar",
            "field": field,
            "form": "ring",
            "size": "1x1",
            "shape": "default",
            "color": color,
            "background": {
                "kind": "color",
                "value": color
            },
            "onMissing": "hide"
        };
    }

    Component.onCompleted: {
        Statusphere.ingest(JSON.stringify(root.selfRoom));
        Statusphere.selfAccountId = "acc-owner";
        editor.editRow = [root.tile("cpu", "primaryContainer"), root.tile("mem", "secondaryContainer"), root.tile("disk", "tertiaryContainer")];
        editor.editDetail = [];
        editor.reorderTile(0, 2); // drops "cpu" onto "disk"'s slot: mem, cpu, disk - selects cpu
        editor.updateSelectedTile({
            "color": "primary"
        }); // what a colour swatch click does
        editor.updateSelectedTile({
            "onMissing": "dim"
        }); // what the "keep place when empty" switch does when turned on

        // A custom-field scenario on the untouched detail surface: a pre-existing
        // unrelated key stands in for whatever else a friend's custom.json already
        // holds, "Coffee Break!" is added by name the way "Add a tile" would, and
        // given a value the way the properties panel's text input would.
        editor.loadedCustomFields = {
            "legacy_field": {
                "cmd": "echo legacy",
                "repeat_seconds": 60
            }
        };
        editor.selectSurface("detail");
        root.addedCoffee = editor.addCustomField("Coffee Break!");
        root.detailLenAfterAdd = editor.editDetail.length;
        root.addedCoffeeAgain = editor.addCustomField("coffee_break");
        editor.setCustomFieldValue("coffee_break", "latte");
        root.previewShowsLatteBeforeSave = root.findAll(root, it => it.text === "latte", []).length > 0;

        // Read before the save below writes anything - saveMyLayout() is the only thing
        // in this file that ever changes custom.json's bytes on disk.
        let before = {};
        try {
            before = JSON.parse(customCheck.text());
        } catch (e) {
        }
        root.wroteCoffeeBeforeSave = before.coffee_break !== undefined;

        // Stays synchronous with everything above: an async layoutFile/customFieldsFile
        // load landing in between would otherwise reset editRow/editCustomValues to
        // whatever is currently on disk before this save gets to write them out.
        editor.saveMyLayout();
    }

    // A generic visual-tree walk, for pinning what a tile actually renders with
    // instead of just the data that went in.
    function findAll(item, pred, out) {
        if (pred(item))
            out.push(item);
        for (const c of item.children ?? [])
            root.findAll(c, pred, out);
        return out;
    }

    function findAllData(item, pred, out) {
        if (!item)
            return out;
        if (pred(item))
            out.push(item);
        const kids = item.data ?? item.children;
        for (let i = 0; i < (kids?.length ?? 0); i++)
            root.findAllData(kids[i], pred, out);
        return out;
    }

    function tooltipsShown(item) {
        return root.findAllData(item, it => it.internalVisibleCondition !== undefined && it.visible, []).length;
    }

    function pickers(item) {
        return root.findAllData(item, it => it.picked !== undefined && it.options !== undefined, []);
    }

    function presetLabels(item) {
        const names = CardLayouts.names().map(n => CardLayouts.get(n).name);
        return root.findAllData(item, it => it.text !== undefined && names.includes(it.text), []);
    }

    function thumbnails(item) {
        return root.findAllData(item, it => it.thumbnail === true && it.placed !== undefined, []);
    }

    function checks() {
        emptyEditor.editRow = [];
        emptyEditor.editDetail = [];
        emptyEditor.selectedIndex = -1;
        let saved = {};
        try {
            saved = JSON.parse(check.text());
        } catch (e) {
        // File not settled yet - every check below fails loudly instead of throwing
        }
        let savedCustom = {};
        try {
            savedCustom = JSON.parse(customCheck.text());
        } catch (e) {
        // Same as above
        }
        editor.selectSurface("row"); // back to the surface the checks below assume
        editor.editRow = editor.editRow.concat([{
                    "type": "scalar",
                    "field": "gone_missing",
                    "form": "text",
                    "size": "2x1",
                    "shape": "default",
                    "color": "secondaryContainer",
                    "background": {
                        "kind": "color",
                        "value": "secondaryContainer"
                    },
                    "onMissing": "dim"
                }]);
        const offersGoneMissing = editor.sourceOptionsFor(null).some(o => o.value === "scalar:gone_missing");
        const labelTexts = root.findAll(root, it => it.text !== undefined, []).map(t => t.text);

        // All the file-based checks above already read their own snapshot of editRow's
        // saved content, so trimming it down here, after the fact, only affects what the
        // settled shot shows: a single custom-field tile selected, so its properties panel
        // - including the value input - fits above the fold instead of a 4-tile grid.
        editor.editRow = [editor.editRow[editor.editRow.length - 1]]; // "gone_missing", alone
        editor.selectedIndex = 0;

        const labels = root.presetLabels(emptyEditor);
        const thumbs = root.thumbnails(emptyEditor);

        return [
            {
                "name": "no tooltip shows without hover, with or without a selected tile",
                "got": [root.tooltipsShown(editor), root.tooltipsShown(emptyEditor)],
                "want": [0, 0]
            },
            {
                "name": "with no tile selected the shape and colour pickers are hidden",
                "got": root.pickers(emptyEditor).map(p => p.visible),
                "want": [false, false, false]
            },
            {
                "name": "a selected tile shows its shape and colour pickers",
                "got": root.pickers(editor).filter(p => p.visible).length >= 2,
                "want": true
            },
            {
                "name": "every preset has its name shown inside the page",
                "got": labels.filter(l => l.visible && l.mapToItem(emptyEditor, 0, 0).x + l.width <= emptyEditor.width).length,
                "want": CardLayouts.names().length
            },
            {
                "name": "every preset thumbnail fills both of its rows",
                "got": thumbs.map(t => t.rowsUsed === t.maxRows && CardLayouts.emptyCells(t.placed) === 0),
                "want": CardLayouts.names().map(() => true)
            },
            {
                "name": "Save my card writes the row tiles to layout.json",
                "got": (saved.row ?? []).length,
                "want": 3
            },
            {
                "name": "Save my card stamps a fresh updated_at",
                "got": (saved.updated_at ?? 0) > 1700000000,
                "want": true
            },
            {
                "name": "dragging a tile onto another's slot reorders the array",
                "got": (saved.row ?? []).map(t => t.field),
                "want": ["mem", "cpu", "disk"]
            },
            {
                "name": "a colour swatch click sets the tile's colour role",
                "got": (saved.row ?? []).find(t => t.field === "cpu")?.color,
                "want": "primary"
            },
            {
                "name": "the keep-place switch maps to onMissing: dim",
                "got": (saved.row ?? []).find(t => t.field === "cpu")?.onMissing,
                "want": "dim"
            },
            {
                "name": "the source list is built from the self device's real fields",
                "got": editor.sourceOptionsFor(null).map(o => o.value).filter(v => ["scalar:cpu", "scalar:mem", "scalar:disk", "scalar:project", "scalar:mood"].includes(v)).sort(),
                "want": ["scalar:cpu", "scalar:disk", "scalar:mem", "scalar:mood", "scalar:project"]
            },
            {
                "name": "the source list still offers a field the layout names even if the device stopped reporting it",
                "got": offersGoneMissing,
                "want": true
            },
            {
                "name": "a tile with no data yet shows a title-cased label, never the raw key",
                "got": labelTexts.includes("gone_missing"),
                "want": false
            },
            {
                "name": "that tile's label is title-cased from the key",
                "got": labelTexts.includes("Gone Missing"),
                "want": true
            },
            {
                "name": "add a tile can create a new custom field by name, normalised to snake_case",
                "got": root.addedCoffee,
                "want": true
            },
            {
                "name": "a duplicate custom field name is refused",
                "got": root.addedCoffeeAgain,
                "want": false
            },
            {
                "name": "a refused add does not create another tile",
                "got": editor.editDetail.length,
                "want": root.detailLenAfterAdd
            },
            {
                "name": "typing a value shows it in the live preview before saving",
                "got": root.previewShowsLatteBeforeSave,
                "want": true
            },
            {
                "name": "nothing is written to custom.json before Save my card",
                "got": root.wroteCoffeeBeforeSave,
                "want": false
            },
            {
                "name": "Save my card writes the typed value into custom.json",
                "got": editor.decodeCustomValueCmd(savedCustom.coffee_break?.cmd),
                "want": "latte"
            },
            {
                "name": "Save my card preserves an unrelated custom.json key untouched",
                "got": savedCustom.legacy_field,
                "want": {
                    "cmd": "echo legacy",
                    "repeat_seconds": 60
                }
            }
        ];
    }
}
