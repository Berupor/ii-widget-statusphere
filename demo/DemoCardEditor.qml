//@ probe statusphere -g 480x900 -s 10000
/**
 * The settings page end to end, through the controls an owner touches: two tabs,
 * the Room tab free of editor controls, the tile gallery, the tile sheet and the
 * files autosave writes. Starts from a layout.json and a custom.json already on
 * disk, one field in them written by hand, the way a cli user set it up before
 * the editor existed. `-p shot=room|card|gallery|sheet|picture|packs-row|packs-detail`
 * picks what the frame shows.
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
        root.gallery = root.first(root.settings, it => it.entryScale !== undefined);
        root.pageTabs = root.first(root.settings, it => it.currentIndex !== undefined && it.count === 2 && root.first(it, b => b.buttonText === "Room") !== null);
    }

    function answerField() {
        return root.first(root.sheet, it => it.placeholderText !== undefined && it.placeholderText === (root.sheet.kind?.hint ?? "-"));
    }

    readonly property string pictureUrl: "https://upload.wikimedia.org/wikipedia/commons/3/3f/JPEG_example_flower.jpg"

    function pictureUrlField() {
        return root.first(root.sheet, it => it.visible && it.placeholderText === "Picture URL, https://");
    }

    function commitText(field, text) {
        field.text = text;
        field.editingFinished();
    }

    function tileIndex(field) {
        return root.editor.editRow.findIndex(t => t.field === field);
    }

    function clipAncestor(item, tile) {
        let it = item.parent;
        while (it && it !== tile && !it.clip)
            it = it.parent;
        return it ?? tile;
    }

    function inside(item, box) {
        const at = item.mapToItem(box, 0, 0);
        return at.x >= -0.5 && at.y >= -0.5 && at.x + item.width <= box.width + 0.5 && at.y + item.height <= box.height + 0.5;
    }

    function galleryFitProblems() {
        const problems = [];
        const cards = root.findAllData(root.gallery, it => it.modelData?.tile !== undefined && it.span !== undefined, []);
        for (const card of cards) {
            const name = card.modelData.label;
            const label = root.first(card, it => it.text === name && it.truncated !== undefined);
            if (!label || label.truncated || !root.inside(label, card))
                problems.push(`${name}: label`);
            if (!root.inside(card, root.gallery))
                problems.push(`${name}: entry`);
            const tile = root.first(card, it => it.account !== undefined && it.tile !== undefined);
            const parts = root.findAllData(tile, it => it.visible && it.width > 0 && (it.truncated !== undefined || it.valueBarHeight !== undefined), []);
            for (const part of parts)
                if (part.truncated || !root.inside(part, root.clipAncestor(part, tile)))
                    problems.push(`${name}: ${part.text ?? "bar"}`);
        }
        return cards.length > 0 ? problems : ["no entries"];
    }

    function galleryGroupDelegates() {
        return root.findAllData(root.gallery, it => it.expanded !== undefined && it.modelData?.title !== undefined, []);
    }

    function galleryGroupsOpen() {
        return root.galleryGroupDelegates().map(g => [g.modelData.title, g.expanded]);
    }

    function openGalleryGroup(title) {
        const group = root.galleryGroupDelegates().find(g => g.modelData.title === title);
        root.first(group, it => it.mainText === title && it.clicked !== undefined).clicked();
    }

    function galleryCard(label) {
        return root.first(root.gallery, it => it.modelData?.label === label && it.span !== undefined);
    }

    function unknownLengthMusic() {
        return ["Music - cover", "Music - wave", "Music - vinyl"].map(label => {
            const card = root.galleryCard(label);
            const texts = root.visibleTexts(card);
            const progress = root.findAllData(card, it => it.visible && (it.valueBarHeight !== undefined || (it.lineWidth !== undefined && it.value !== undefined)), []);
            return [label, texts.some(t => /\d:\d\d/.test(t)), progress.length];
        });
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
                root.note("roomEditorItems", root.findAllData(root.settings, it => it.visible && (it.reorderable !== undefined || it.fieldKey !== undefined || it.entryScale !== undefined), []).length);
                root.note("roomTooltips", root.tooltipsShown(root.settings));
                root.pageTabs.currentIndex = 1;

                root.editor.selectTile(root.tileIndex(root.handField));
                root.note("handKind", root.sheet.kindId);
                root.note("handAnswer", root.answerField()?.text ?? null);

                root.editor.openGallery();
            }
        }
        PauseAnimation {
            duration: 400
        }
        ScriptAction {
            script: {
                root.note("groupsOpenAtFirst", root.galleryGroupsOpen());
                root.note("collapsedGalleryHeight", root.gallery.height);
                root.openGalleryGroup("Activity");
            }
        }
        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: {
                root.note("groupsOpenAfterClick", root.galleryGroupsOpen());
                root.note("activityEntriesShown", root.visibleTexts(root.gallery).includes("Music - vinyl"));
                root.openGalleryGroup("Your own");
                root.openGalleryGroup("System");
            }
        }
        PauseAnimation {
            duration: 400
        }
        ScriptAction {
            script: {
                root.note("unknownLengthMusic", root.unknownLengthMusic());
                root.note("galleryTexts", root.visibleTexts(root.gallery));
                root.note("galleryFit", root.galleryFitProblems());
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
                root.editor.selectSurface("detail");
            }
        }
        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: {
                root.note("emptyDetailHint", root.visibleTexts(root.editor).includes("Friends see the standard detail card until you add a tile"));
                const hint = root.first(root.editor, it => it.text === "Friends see the standard detail card until you add a tile");
                const preview = root.first(root.editor, it => it.reorderable === true);
                root.note("emptyDetailHintClear", hint.mapToItem(null, 0, 0).y >= preview.mapToItem(null, 0, preview.height).y && hint.mapToItem(null, 0, hint.height).y <= hint.parent.mapToItem(null, 0, hint.parent.height).y);
                root.note("emptyDetailPreviewTiles", root.first(root.editor, it => it.reorderable === true)?.tiles.length ?? 0);
                root.editor.addFromGallery("picture");
                root.note("pictureAdded", root.editor.editDetail.map(t => t.type));
                root.note("pictureSheetTexts", root.visibleTexts(root.sheet));
                root.commitText(root.pictureUrlField(), root.pictureUrl);
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                root.note("layoutAfterPicture", root.readJson(layoutView));
                root.editor.removeTileAt(0);
                root.sheet.moreOpen = true;
                root.note("photoBackgroundPerShape", root.sheet.shapeOptions.map(shape => {
                    root.editor.addFromGallery("window");
                    root.first(root.sheet, it => it.picked !== undefined && it.options?.[0] === "default").picked(shape);
                    root.first(root.sheet, it => it.selected !== undefined && it.options?.some(o => o.value === "url")).selected("live");
                    const liveChoice = root.first(root.sheet, it => it.selected !== undefined && it.options?.[0]?.value === "photo");
                    const usable = liveChoice !== null && liveChoice.visible && liveChoice.enabled;
                    liveChoice?.selected("photo");
                    return [shape, usable];
                }));
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                root.note("layoutAfterShapes", root.readJson(layoutView));
                root.editor.selectedIndex = -1;
                root.editor.setSurfaceTiles([]);
                root.editor.selectSurface("row");
            }
        }
        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: {
                root.notePackList("row");
                root.note("rowBefore", JSON.stringify(root.editor.editRow));
                root.note("detailBefore", JSON.stringify(root.editor.editDetail));
                root.editor.applyPack("nightOwl");
                root.note("rowPackApplied", [JSON.stringify(root.editor.editRow) === JSON.stringify(CardLayouts.packs.row.nightOwl), JSON.stringify(root.editor.editDetail) === root.seen.detailBefore]);
                root.editor.undo();
                root.note("rowPackUndone", JSON.stringify(root.editor.editRow) === root.seen.rowBefore);
                root.editor.selectSurface("detail");
                root.editor.packsOpen = true;
            }
        }
        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: {
                root.notePackList("detail");
                root.noteUnsourcedPackFields();
                root.editor.applyPack("coder");
                root.note("detailPackApplied", [JSON.stringify(root.editor.editDetail) === JSON.stringify(CardLayouts.packs.detail.coder), JSON.stringify(root.editor.editRow) === root.seen.rowBefore]);
                root.editor.undo();
                root.note("detailPackUndone", JSON.stringify(root.editor.editDetail) === root.seen.detailBefore);
                root.editor.applyPack("traveler");
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                root.note("customAfterTraveler", root.readJson(customView));
                root.editor.undo();
                root.editor.selectSurface("row");
                root.arrangeShot();
            }
        }
    }

    function tileSignature(tiles) {
        return tiles.map(t => `${t.type}:${t.field}:${t.size}`).join(",");
    }

    function packCustomFields(tiles) {
        return tiles.filter(t => t.type === "scalar" && Statusphere.isCustomFieldKey(t.field)).map(t => t.field);
    }

    function noteUnsourcedPackFields() {
        const unsourced = [];
        for (const surface of ["row", "detail"]) {
            root.editor.selectSurface(surface);
            for (const p of CardLayouts.packsFor(surface)) {
                root.editor.applyPack(p.id);
                for (const key of root.packCustomFields(p.tiles))
                    if (!root.editor.customEntries[key]?.cmd)
                        unsourced.push(`${surface}.${p.id}.${key}`);
                root.editor.undo();
            }
        }
        root.editor.selectSurface("detail");
        root.note("unsourcedPackFields", unsourced);
    }

    function packShape(surface) {
        return CardLayouts.packsFor(surface).map(p => {
            const placed = CardLayouts.pack(p.tiles, CardLayouts.rowsFor(surface));
            const fields = p.tiles.map(t => t.type === "scalar" ? t.field : t.type);
            return {
                "id": p.id,
                "rows": CardLayouts.rowsUsed(placed),
                "allPlaced": placed.length === p.tiles.length,
                "holes": CardLayouts.emptyCells(placed),
                "repeats": fields.length - new Set(fields).size,
                "system": fields.filter(f => root.systemFields.includes(f)).length
            };
        });
    }

    readonly property var systemFields: ["cpu", "mem", "disk", "load", "uptime", "package_count"]

    function notePackList(surface) {
        const packs = CardLayouts.packsFor(surface);
        const names = packs.map(p => p.name);
        const thumbs = root.findAllData(root.editor, it => it.thumbnail === true && it.placed !== undefined && it.visible, []);
        root.note(`${surface}PackLabelsInside`, root.findAllData(root.editor, it => names.includes(it.text) && it.visible && it.mapToItem(root.editor, 0, 0).x + it.width <= root.editor.width, []).length);
        root.note(`${surface}PackThumbs`, thumbs.map(t => root.tileSignature(t.tiles)));
        root.note(`${surface}PackThumbsWhole`, thumbs.map(t => t.placed.length === t.tiles.length && CardLayouts.emptyCells(t.placed) === 0));
    }

    function arrangeShot() {
        root.editor.packsOpen = false;
        if (root.shot === "room") {
            root.pageTabs.currentIndex = 0;
            return;
        }
        if (root.shot === "gallery") {
            root.openGalleryGroup("Your own");
            root.openGalleryGroup("Activity");
            root.openGalleryGroup("System");
            root.editor.openGallery();
        }
        else if (root.shot === "packs-row" || root.shot === "packs-detail") {
            root.editor.selectSurface(root.shot === "packs-row" ? "row" : "detail");
            root.editor.packsOpen = true;
        } else if (root.shot === "picture") {
            root.editor.selectSurface("detail");
            root.editor.addFromGallery("picture");
            root.commitText(root.pictureUrlField(), root.pictureUrl);
        } else if (root.shot === "sheet") {
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
                "got": ["Music - vinyl", "CPU ring", "Active window", "Photo", "Picture", "Game"].filter(l => (s.galleryTexts ?? []).includes(l)),
                "want": ["Music - vinyl", "CPU ring", "Active window", "Photo", "Picture", "Game"]
            },
            {
                "name": "the Picture template adds a picture tile whose sheet asks for a URL and offers no kind",
                "got": [s.pictureAdded, (s.pictureSheetTexts ?? []).includes("Kind")],
                "want": [["picture"], false]
            },
            {
                "name": "a URL typed into a picture's sheet is autosaved on the tile",
                "got": (s.layoutAfterPicture?.detail ?? []).map(t => [t.type, t.url]),
                "want": [["picture", root.pictureUrl]]
            },
            {
                "name": "a photo background can be picked in the sheet with every shape",
                "got": s.photoBackgroundPerShape,
                "want": root.sheet?.shapeOptions.map(shape => [shape, true])
            },
            {
                "name": "every shape is saved together with its photo background",
                "got": (s.layoutAfterShapes?.detail ?? []).map(t => [t.shape, t.background?.kind, t.background?.value]),
                "want": root.sheet?.shapeOptions.map(shape => [shape, "live", "photo"])
            },
            {
                "name": "the gallery opens with only Live expanded",
                "got": s.groupsOpenAtFirst,
                "want": [["Live", true], ["Your own", false], ["Activity", false], ["System", false]]
            },
            {
                "name": "the collapsed gallery stays under 700px at 480 wide",
                "got": (s.collapsedGalleryHeight ?? 9999) < 700,
                "want": true
            },
            {
                "name": "clicking a group header expands that group only",
                "got": [s.groupsOpenAfterClick, s.activityEntriesShown],
                "want": [[["Live", true], ["Your own", false], ["Activity", true], ["System", false]], true]
            },
            {
                "name": "a track of unknown length shows no time and no progress, on cover, wave and vinyl",
                "got": s.unknownLengthMusic,
                "want": [["Music - cover", false, 0], ["Music - wave", false, 0], ["Music - vinyl", false, 0]]
            },
            {
                "name": "no gallery entry's tile or label is clipped or elided",
                "got": s.galleryFit,
                "want": []
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
                "name": "the empty-state hint on an empty Detail tab says friends see the standard card",
                "got": s.emptyDetailHint,
                "want": true
            },
            {
                "name": "the empty Detail hint sits under the standard tiles, inside the preview, not over them",
                "got": s.emptyDetailHintClear,
                "want": true
            },
            {
                "name": "the Detail preview falls back to the standard detail tiles when empty",
                "got": s.emptyDetailPreviewTiles > 0,
                "want": true
            },
            {
                "name": "the Row pack list shows only row packs, each named inside the page",
                "got": [s.rowPackThumbs, s.rowPackLabelsInside],
                "want": [CardLayouts.packsFor("row").map(p => root.tileSignature(p.tiles)), CardLayouts.packsFor("row").length]
            },
            {
                "name": "every row pack thumbnail shows all its tiles with no holes",
                "got": s.rowPackThumbsWhole,
                "want": CardLayouts.packsFor("row").map(() => true)
            },
            {
                "name": "every row pack is one row of four cells: all tiles placed, no holes, no 2x2",
                "got": root.packShape("row").map(p => [p.id, p.rows, p.allPlaced, p.holes, CardLayouts.packFor("row", p.id).tiles.some(t => t.size === "2x2")]),
                "want": CardLayouts.packsFor("row").map(p => [p.id, 1, true, 0, false])
            },
            {
                "name": "every detail pack fills three or four rows, all tiles placed, no holes",
                "got": root.packShape("detail").map(p => [p.id, p.rows >= 3 && p.rows <= CardLayouts.detailRows, p.allPlaced, p.holes]),
                "want": CardLayouts.packsFor("detail").map(p => [p.id, true, true, 0])
            },
            {
                "name": "no pack names a field twice or carries more than two system metrics",
                "got": root.packShape("row").concat(root.packShape("detail")).filter(p => p.repeats > 0 || p.system > 2).map(p => p.id),
                "want": []
            },
            {
                "name": "applying any pack gives every custom field it names a custom.json entry",
                "got": s.unsourcedPackFields,
                "want": []
            },
            {
                "name": "the Traveler detail pack writes the weather and clock templates and its text after the debounce",
                "got": [s.customAfterTraveler?.weather, s.customAfterTraveler?.local_time, s.customAfterTraveler?.flag],
                "want": [
                    {
                        "cmd": "curl -sf 'wttr.in/?format=%t+·+%C'",
                        "repeat_seconds": 900
                    },
                    {
                        "cmd": "date +%H:%M",
                        "repeat_seconds": 30
                    },
                    {
                        "cmd": "printf '%s' '🇯🇵'",
                        "repeat_seconds": 0
                    }
                ]
            },
            {
                "name": "applying a pack on Row replaces Row and leaves Detail untouched",
                "got": s.rowPackApplied,
                "want": [true, true]
            },
            {
                "name": "undo takes back a pack applied on Row",
                "got": s.rowPackUndone,
                "want": true
            },
            {
                "name": "the Detail pack list shows only detail packs, each named inside the page",
                "got": [s.detailPackThumbs, s.detailPackLabelsInside],
                "want": [CardLayouts.packsFor("detail").map(p => root.tileSignature(p.tiles)), CardLayouts.packsFor("detail").length]
            },
            {
                "name": "every detail pack thumbnail shows all its tiles with no holes",
                "got": s.detailPackThumbsWhole,
                "want": CardLayouts.packsFor("detail").map(() => true)
            },
            {
                "name": "applying a pack on Detail replaces Detail and leaves Row untouched",
                "got": s.detailPackApplied,
                "want": [true, true]
            },
            {
                "name": "undo takes back a pack applied on Detail",
                "got": s.detailPackUndone,
                "want": true
            },
            {
                "name": "no tooltip shows without hover, on the Room tab, the gallery or a sheet",
                "got": [s.roomTooltips, s.galleryTooltips, s.sheetTooltips, root.tooltipsShown(root.settings)],
                "want": [0, 0, 0, 0]
            }
        ];
    }
}
