import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.modules.widgets
import "CardLayouts.js" as CardLayouts

QtObject {
    id: root

    property var row: []
    property var detail: []
    property var entries: ({})
    readonly property var ownedFields: Statusphere.opt("editorOwnedFields") ?? []
    property var undoState: null

    readonly property int autosaveDelayMs: 500
    property bool layoutPending: false
    property bool customPending: false
    property bool savedOnce: false
    readonly property bool saving: root.layoutPending || root.customPending

    signal layoutLoaded

    function setLayout(row, detail) {
        root.row = row;
        root.detail = detail;
        root.markLayoutChanged();
    }

    function setEntry(key, entry) {
        root.entries = Object.assign({}, root.entries, {
            [key]: entry
        });
        if (!root.ownedFields.includes(key))
            root.setOwnedFields(root.ownedFields.concat([key]));
        root.markCustomChanged();
    }

    function removeEntry(key) {
        const next = Object.assign({}, root.entries);
        delete next[key];
        root.entries = next;
        root.setOwnedFields(root.ownedFields.filter(k => k !== key));
        root.markCustomChanged();
    }

    function setOwnedFields(keys) {
        WidgetsStore.setOption("statusphere", "editorOwnedFields", keys);
    }

    function rememberUndo() {
        root.undoState = {
            "row": root.row,
            "detail": root.detail,
            "entries": root.entries,
            "owned": root.ownedFields
        };
    }

    function undo() {
        const state = root.undoState;
        if (!state)
            return false;
        root.undoState = null;
        root.entries = state.entries;
        root.setOwnedFields(state.owned);
        root.markCustomChanged();
        root.setLayout(state.row, state.detail);
        return true;
    }

    function markLayoutChanged() {
        root.layoutPending = true;
        autosave.restart();
    }

    function markCustomChanged() {
        root.customPending = true;
        autosave.restart();
    }

    function flush() {
        autosave.stop();
        if (root.layoutPending) {
            root.layoutPending = false;
            layoutFile.setText(JSON.stringify({
                "updated_at": Math.floor(Date.now() / 1000),
                "row": root.row,
                "detail": root.detail
            }, null, 2));
        }
        if (root.customPending) {
            root.customPending = false;
            customFile.setText(JSON.stringify(root.entries, null, 2));
        }
        root.savedOnce = true;
    }

    function loadLayout() {
        if (root.layoutPending)
            return;
        try {
            const saved = JSON.parse(layoutFile.text());
            root.row = (saved.row ?? []).map(CardLayouts.withKnownBackground);
            root.detail = (saved.detail ?? []).map(CardLayouts.withKnownBackground);
        } catch (e) {
            root.row = [];
            root.detail = [];
        }
        root.layoutLoaded();
    }

    function loadEntries() {
        if (root.customPending)
            return;
        try {
            const raw = JSON.parse(customFile.text());
            root.entries = raw && typeof raw === "object" && !Array.isArray(raw) ? raw : {};
        } catch (e) {
            root.entries = {};
        }
    }

    Component.onDestruction: root.flush()

    readonly property Timer autosave: Timer {
        id: autosave
        interval: root.autosaveDelayMs
        onTriggered: root.flush()
    }

    readonly property FileView layoutFile: FileView {
        id: layoutFile
        path: `${Directories.config}/statusphere/${CardLayouts.layoutFileName}`
        printErrors: false
        onLoaded: root.loadLayout()
        onLoadFailed: root.loadLayout()
    }

    readonly property FileView customFile: FileView {
        id: customFile
        path: `${Directories.config}/statusphere/${CardLayouts.customFileName}`
        printErrors: false
        onLoaded: root.loadEntries()
        onLoadFailed: root.loadEntries()
    }
}
