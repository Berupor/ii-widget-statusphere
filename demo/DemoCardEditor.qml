//@ probe statusphere -g 480x900 -s 6000
/**
 * The settings page end to end, through the controls an owner touches: two tabs,
 * the Room tab free of editor controls, the tile gallery, the tile sheet and the
 * files autosave writes. Starts from a layout.json and a custom.json already on
 * disk, one field in them written by hand, the way a cli user set it up before
 * the editor existed. `-p shot=room|card|gallery|sheet` picks what the frame shows.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import qs.modules.common
import Quickshell.Io
import QtQuick

Item {
    id: root
    clip: true

    property string shot: "sheet"

    readonly property string layoutPath: `${Directories.config}/statusphere/layout.json`
    readonly property string customFieldsPath: `${Directories.config}/statusphere/custom.json`
    readonly property string handField: "uptime_pretty"
    readonly property var handEntry: ({
            "cmd": "uptime -p",
            "repeat_seconds": 60
        })
    readonly property string tokyoWeatherCmd: "curl -sf 'wttr.in/Tokyo?format=%t+·+%C'"

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
                    "custom_fields": ["uptime_pretty"],
                    "uptime_pretty": "up 3 hours"
                }
            ]
        })

    property var seen: ({})

    function note(key, value) {
        root.seen = Object.assign({}, root.seen, {
            [key]: value
        });
    }

    function readJson(view) {
        const path = view.path;
        view.path = "";
        view.path = path;
        try {
            return JSON.parse(view.text());
        } catch (e) {
            return {};
        }
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

    function first(item, pred) {
        return root.findAllData(item, pred, [])[0] ?? null;
    }

    function visibleTexts(item) {
        return root.findAllData(item, it => typeof it.text === "string" && it.text !== "" && it.visible && it.font !== undefined && it.iconSize === undefined, []).map(t => t.text);
    }

    readonly property var settings: settingsLoader.item
    property var editor: null
    property var sheet: null
    property var gallery: null
    property var pageTabs: null

    function findParts() {
        root.editor = root.first(root.settings, it => it.editRow !== undefined && it.galleryGroups !== undefined);
        root.sheet = root.first(root.settings, it => it.editor !== undefined && it.fieldKey !== undefined);
        root.gallery = root.first(root.settings, it => it.cell !== undefined);
        root.pageTabs = root.first(root.settings, it => it.currentIndex !== undefined && it.count === 2 && root.first(it, b => b.buttonText === "Room") !== null);
    }

    function answerField() {
        return root.first(root.sheet, it => it.placeholderText !== undefined && it.placeholderText === (root.sheet.kind?.hint ?? "-"));
    }

    function commitText(field, text) {
        field.text = text;
        field.editingFinished();
    }

    function tileIndex(field) {
        return root.editor.editRow.findIndex(t => t.field === field);
    }

    function tooltipsShown(item) {
        return root.findAllData(item, it => it.internalVisibleCondition !== undefined && it.visible, []).length;
    }

    FileView {
        id: layoutView
        path: root.layoutPath
        printErrors: false
        blockLoading: true
        blockWrites: true
    }

    FileView {
        id: customView
        path: root.customFieldsPath
        printErrors: false
        blockLoading: true
        blockWrites: true
    }

    Loader {
        id: settingsLoader
        active: false
        width: root.width
        sourceComponent: StatusphereSettings {}
    }

    Component.onCompleted: {
        layoutView.setText(JSON.stringify({
            "updated_at": 1,
            "row": [CardLayouts.tile({
                    "type": "scalar",
                    "field": root.handField,
                    "form": "text",
                    "size": "2x1"
                })],
            "detail": []
        }));
        customView.setText(JSON.stringify({
            [root.handField]: root.handEntry
        }));
        Statusphere.ingest(JSON.stringify(root.selfRoom));
        Statusphere.selfAccountId = "acc-owner";
        timeline.start();
    }

    SequentialAnimation {
        id: timeline

        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: settingsLoader.active = true
        }
        PauseAnimation {
            duration: 600
        }
        ScriptAction {
            script: {
                Statusphere.ingest(JSON.stringify(root.selfRoom));
                Statusphere.selfAccountId = "acc-owner";
                root.findParts();
                root.note("tabs", root.findAllData(root.pageTabs, it => it.buttonText !== undefined, []).map(b => b.buttonText));
                root.note("roomTexts", root.visibleTexts(root.settings));
                root.note("roomEditorItems", root.findAllData(root.settings, it => it.visible && (it.reorderable !== undefined || it.fieldKey !== undefined || it.cell !== undefined), []).length);
                root.note("roomTooltips", root.tooltipsShown(root.settings));
                root.pageTabs.currentIndex = 1;

                root.editor.selectTile(root.tileIndex(root.handField));
                root.note("handKind", root.sheet.kindId);
                root.note("handAnswer", root.answerField()?.text ?? null);

                root.editor.openGallery();
            }
        }
        PauseAnimation {
            duration: 100
        }
        ScriptAction {
            script: {
                root.note("galleryTexts", root.visibleTexts(root.gallery));
                root.note("galleryTooltips", root.tooltipsShown(root.settings));
                root.editor.addFromGallery("cpu");
                root.editor.addFromGallery("mem");
                root.editor.addFromGallery("weather");
                root.commitText(root.answerField(), "Tokyo");
                root.note("customRightAfterCommit", root.readJson(customView));
                root.editor.addFromGallery("command");
                root.answerField().text = "echo hel";
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                root.note("customAfterWeather", root.readJson(customView));
                root.note("layoutAfterWeather", root.readJson(layoutView));
                root.editor.selectTile(root.tileIndex("weather"));
                root.first(root.sheet, it => it.selected !== undefined && it.options !== undefined && it.options[0]?.value === 30).selected(3600);
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                root.note("customAfterRepeat", root.readJson(customView));
                root.editor.selectTile(root.tileIndex("output"));
                root.commitText(root.answerField(), "echo hello");
                root.sheet.runTest();
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                root.note("customAfterCommand", root.readJson(customView));
                root.note("testOutput", root.visibleTexts(root.sheet).includes("hello"));
                root.note("previewShowsTested", root.visibleTexts(root.first(root.editor, it => it.reorderable === true)).includes("hello"));
                root.editor.removeTileAt(root.tileIndex("weather"));
                root.editor.removeTileAt(root.tileIndex(root.handField));
                root.editor.reorderTile(0, 2);
                root.first(root.sheet, it => it.picked !== undefined && it.options?.[0] === "primary").picked("primary");
                root.sheet.moreOpen = true;
                root.first(root.sheet, it => it.text === "Keep place when empty" && it.checked !== undefined).clicked();
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                root.note("customAfterRemove", root.readJson(customView));
                root.note("layoutAfterEdits", root.readJson(layoutView));
                root.note("sheetTooltips", root.tooltipsShown(root.settings));
                root.editor.selectedIndex = -1;
                root.editor.packsOpen = true;
            }
        }
        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: {
                const names = CardLayouts.names().map(n => CardLayouts.get(n).name);
                root.note("packLabelsInside", root.findAllData(root.editor, it => names.includes(it.text) && it.visible && it.mapToItem(root.editor, 0, 0).x + it.width <= root.editor.width, []).length);
                root.note("packThumbsFull", root.findAllData(root.editor, it => it.thumbnail === true && it.placed !== undefined, []).map(t => t.rowsUsed === t.maxRows && CardLayouts.emptyCells(t.placed) === 0));
                root.arrangeShot();
            }
        }
    }

    function arrangeShot() {
        root.editor.packsOpen = false;
        if (root.shot === "room") {
            root.pageTabs.currentIndex = 0;
            return;
        }
        if (root.shot === "gallery")
            root.editor.openGallery();
        else if (root.shot === "sheet") {
            root.editor.selectTile(root.tileIndex("output"));
            root.sheet.moreOpen = false;
            root.sheet.runTest();
        }
    }

    function checks() {
        const s = root.seen;
        const entryKeys = obj => Object.keys(obj ?? {}).sort();
        return [
            {
                "name": "the page has two tabs, Room and My card",
                "got": s.tabs,
                "want": ["Room", "My card"]
            },
            {
                "name": "the Room tab shows the room settings",
                "got": (s.roomTexts ?? []).includes("Hold your own row to hide"),
                "want": true
            },
            {
                "name": "the Room tab has no card editor controls",
                "got": s.roomEditorItems,
                "want": 0
            },
            {
                "name": "a hand-written custom.json command shows as Your command",
                "got": s.handKind,
                "want": "command"
            },
            {
                "name": "a hand-written command shows its cmd, not an empty field",
                "got": s.handAnswer,
                "want": "uptime -p"
            },
            {
                "name": "the gallery lists the live templates and the owner's own kinds",
                "got": ["Weather", "Clock", "Commits today", "Your text", "Your command"].filter(l => (s.galleryTexts ?? []).includes(l)),
                "want": ["Weather", "Clock", "Commits today", "Your text", "Your command"]
            },
            {
                "name": "the gallery names tiles by what they are",
                "got": ["Music - vinyl", "CPU ring", "Active window", "Photo", "Game"].filter(l => (s.galleryTexts ?? []).includes(l)),
                "want": ["Music - vinyl", "CPU ring", "Active window", "Photo", "Game"]
            },
            {
                "name": "the gallery never says custom or shows a raw field name",
                "got": (s.galleryTexts ?? []).filter(t => /custom/i.test(t) || /_/.test(t)),
                "want": []
            },
            {
                "name": "autosave does not write the moment an answer is committed",
                "got": s.customRightAfterCommit?.weather,
                "want": undefined
            },
            {
                "name": "Weather with a city writes the wttr.in command after the debounce",
                "got": s.customAfterWeather?.weather,
                "want": {
                    "cmd": root.tokyoWeatherCmd,
                    "repeat_seconds": 900
                }
            },
            {
                "name": "picking Weather puts a weather tile on the card",
                "got": (s.layoutAfterWeather?.row ?? []).filter(t => t.field === "weather").map(t => t.form),
                "want": ["weather"]
            },
            {
                "name": "a half-typed command is never written",
                "got": JSON.stringify(s.customAfterWeather ?? {}).includes("echo hel"),
                "want": false
            },
            {
                "name": "changing Weather's refresh rewrites only its repeat_seconds",
                "got": s.customAfterRepeat?.weather,
                "want": {
                    "cmd": root.tokyoWeatherCmd,
                    "repeat_seconds": 3600
                }
            },
            {
                "name": "changing Weather's refresh leaves the other entries alone",
                "got": s.customAfterRepeat?.[root.handField],
                "want": root.handEntry
            },
            {
                "name": "Your command writes its cmd with a repeat_seconds",
                "got": s.customAfterCommand?.output,
                "want": {
                    "cmd": "echo hello",
                    "repeat_seconds": 60
                }
            },
            {
                "name": "Test shows the command's output in the sheet",
                "got": s.testOutput,
                "want": true
            },
            {
                "name": "the tested output shows in the preview",
                "got": s.previewShowsTested,
                "want": true
            },
            {
                "name": "removing tiles drops the editor's key and keeps the hand-written one",
                "got": entryKeys(s.customAfterRemove),
                "want": ["output", root.handField].sort()
            },
            {
                "name": "a hand-written entry survives its tile's removal untouched",
                "got": s.customAfterRemove?.[root.handField],
                "want": root.handEntry
            },
            {
                "name": "dragging a tile onto another's slot reorders the saved row",
                "got": (s.layoutAfterEdits?.row ?? []).map(t => t.field),
                "want": ["mem", "cpu", "output"]
            },
            {
                "name": "a colour swatch click saves the tile's colour role",
                "got": (s.layoutAfterEdits?.row ?? []).find(t => t.field === "cpu")?.color,
                "want": "primary"
            },
            {
                "name": "the keep-place switch saves onMissing: dim",
                "got": (s.layoutAfterEdits?.row ?? []).find(t => t.field === "cpu")?.onMissing,
                "want": "dim"
            },
            {
                "name": "autosave stamps a fresh updated_at",
                "got": (s.layoutAfterEdits?.updated_at ?? 0) > 1700000000,
                "want": true
            },
            {
                "name": "every pack has its name shown inside the page",
                "got": s.packLabelsInside,
                "want": CardLayouts.names().length
            },
            {
                "name": "every pack thumbnail fills both of its rows",
                "got": s.packThumbsFull,
                "want": CardLayouts.names().map(() => true)
            },
            {
                "name": "no tooltip shows without hover, on the Room tab, the gallery or a sheet",
                "got": [s.roomTooltips, s.galleryTooltips, s.sheetTooltips, root.tooltipsShown(root.settings)],
                "want": [0, 0, 0, 0]
            }
        ];
    }
}
