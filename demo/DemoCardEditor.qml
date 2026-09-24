//@ probe statusphere -g 480x400 -s 1500
/**
 * Pins the card editor's file contract and the interactions the properties
 * panel drives through: "Save my card" writes the row and detail tiles to
 * ~/.config/statusphere/layout.json with a fresh updated_at, a drag drop
 * reorders the array (not just the on-screen packing), a colour swatch and
 * the "keep place when empty" switch write through updateSelectedTile the
 * same way a click on either would.
 */
import ".."
import qs.modules.common
import Quickshell.Io
import QtQuick

Item {
    id: root
    readonly property string layoutPath: `${Directories.config}/statusphere/layout.json`

    StatusphereSettings {
        id: editor
        width: 400
    }

    FileView {
        id: check
        path: root.layoutPath
        printErrors: false
        watchChanges: true
    }

    Timer {
        interval: 300
        running: true
        onTriggered: check.reload()
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
        editor.editRow = [root.tile("cpu", "primaryContainer"), root.tile("mem", "secondaryContainer"), root.tile("disk", "tertiaryContainer")];
        editor.editDetail = [];
        editor.reorderTile(0, 2); // drops "cpu" onto "disk"'s slot: mem, cpu, disk - selects cpu
        editor.updateSelectedTile({
            "color": "primary"
        }); // what a colour swatch click does
        editor.updateSelectedTile({
            "onMissing": "dim"
        }); // what the "keep place when empty" switch does when turned on
        editor.saveMyLayout();
    }

    function checks() {
        let saved = {};
        try {
            saved = JSON.parse(check.text());
        } catch (e) {
        // File not settled yet - every check below fails loudly instead of throwing
        }
        return [
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
            }
        ];
    }
}
