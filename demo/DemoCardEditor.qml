//@ probe statusphere -g 480x400 -s 1500
/**
 * Pins the card editor's file contract: "Save my card" writes the row and
 * detail tiles to ~/.config/statusphere/layout.json with a fresh updated_at,
 * the shape the cli will read later.
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

    Component.onCompleted: {
        editor.editRow = [
            {
                "type": "scalar",
                "field": "cpu",
                "form": "ring",
                "size": "1x1",
                "shape": "default",
                "color": "primaryContainer",
                "background": {
                    "kind": "color",
                    "value": "primaryContainer"
                },
                "onMissing": "hide"
            }
        ];
        editor.editDetail = [];
        editor.saveMyLayout();
    }

    function checks() {
        let saved = {};
        try {
            saved = JSON.parse(check.text());
        } catch (e) {
        // File not settled yet - both checks below fail loudly instead of throwing
        }
        return [
            {
                "name": "Save my card writes the row tiles to layout.json",
                "got": (saved.row ?? []).length,
                "want": 1
            },
            {
                "name": "Save my card stamps a fresh updated_at",
                "got": (saved.updated_at ?? 0) > 1700000000,
                "want": true
            }
        ];
    }
}
