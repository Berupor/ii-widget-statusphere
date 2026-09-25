import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.modules.widgets
import "CardLayouts.js" as CardLayouts

QtObject {
    id: root

    property var row: []
    property var detail: []
    property string avatarShape: "Circle"
    property var entries: ({})
    readonly property var fieldKinds: root.fieldKindsFrom(Statusphere.opt("editorOwnedFields"))
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

    function setAvatarShape(shape) {
        if (root.avatarShape === shape)
            return;
        root.avatarShape = shape;
        root.markLayoutChanged();
    }

    function fieldKindsFrom(stored) {
        if (Array.isArray(stored))
            return stored.reduce((fieldKinds, key) => Object.assign(fieldKinds, {
                        [key]: {}
                    }), {});
        return stored && typeof stored === "object" ? stored : {};
    }

    function isOwned(key) {
        return root.fieldKinds[key] !== undefined;
    }

    function setEntry(key, entry, fieldKind) {
        if (JSON.stringify(root.entries[key]) === JSON.stringify(entry) && JSON.stringify(root.fieldKinds[key]) === JSON.stringify(fieldKind))
            return;
        root.entries = Object.assign({}, root.entries, {
            [key]: entry
        });
        root.setFieldKinds(Object.assign({}, root.fieldKinds, {
            [key]: fieldKind
        }));
        root.markCustomChanged();
    }

    function removeEntry(key) {
        const entries = Object.assign({}, root.entries);
        delete entries[key];
        root.entries = entries;
        const fieldKinds = Object.assign({}, root.fieldKinds);
        delete fieldKinds[key];
        root.setFieldKinds(fieldKinds);
        root.markCustomChanged();
    }

    function setFieldKinds(fieldKinds) {
        WidgetsStore.setOption("statusphere", "editorOwnedFields", fieldKinds);
    }

    function rememberUndo() {
        root.undoState = {
            "row": root.row,
            "detail": root.detail,
            "avatarShape": root.avatarShape,
            "entries": root.entries,
            "fieldKinds": root.fieldKinds
        };
    }

    function undo() {
        const state = root.undoState;
        if (!state)
            return false;
        root.undoState = null;
        root.entries = state.entries;
        root.setFieldKinds(state.fieldKinds);
        root.markCustomChanged();
        root.avatarShape = state.avatarShape;
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
                "detail": root.detail,
                "avatarShape": root.avatarShape
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
            root.avatarShape = CardLayouts.shapes.includes(saved.avatarShape) ? saved.avatarShape : "Circle";
        } catch (e) {
            root.row = [];
            root.detail = [];
            root.avatarShape = "Circle";
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
