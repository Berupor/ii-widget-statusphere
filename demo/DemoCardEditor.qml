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
        onTriggered: {
            check.reload();
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
            },
            {
                "name": "the source list is built from the self device's real fields",
                "got": editor.sourceOptionsFor(null).map(o => o.value).filter(v => ["scalar:cpu", "scalar:mem", "scalar:disk", "scalar:project", "scalar:mood"].includes(v)).sort(),
                "want": ["scalar:cpu", "scalar:disk", "scalar:mem", "scalar:mood", "scalar:project"]
            },
            {
                "name": "the source list still offers a field the layout names even if the device stopped reporting it",
                "got": (function() {
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
                    return editor.sourceOptionsFor(null).some(o => o.value === "scalar:gone_missing");
                })(),
                "want": true
            }
        ];
    }
}
