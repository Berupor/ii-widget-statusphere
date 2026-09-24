pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets
import "CardLayouts.js" as CardLayouts

ColumnLayout {
    id: root
    spacing: 8

    readonly property var ownerAccount: Statusphere.selfAccount
    property var editRow: []
    property var editDetail: []
    property string editSurface: "row"
    property int selectedIndex: -1
    property bool galleryOpen: false
    property bool packsOpen: false
    property var customEntries: ({})
    property var testedValues: ({})
    property var chosenKinds: ({})
    property var undoState: null
    readonly property var ownedFields: Statusphere.opt("editorOwnedFields") ?? []

    readonly property var editTiles: root.editSurface === "row" ? root.editRow : root.editDetail
    readonly property var allTiles: root.editRow.concat(root.editDetail)
    readonly property var selectedTile: (root.selectedIndex >= 0 && root.selectedIndex < root.editTiles.length) ? root.editTiles[root.selectedIndex] : null

    readonly property int autosaveDelayMs: 500
    property bool layoutPending: false
    property bool customPending: false
    property bool savedOnce: false
    readonly property bool saving: root.layoutPending || root.customPending

    // Plausible values for every field a pack or gallery tile can name, so a thumbnail
    // reads at a glance instead of showing "-" for data this machine has none of.
    readonly property var demoDevice: ({
            "cpu_percent": 42,
            "memory_used_mb": 6144,
            "memory_total_mb": 16384,
            "disk_used_percent": 58,
            "disk_free_gb": 210,
            "load_avg_1m": 1.8,
            "cpu_count": 8,
            "uptime_hours": 26,
            "active_workspace": 3,
            "active_window": "nvim - CardLayouts.js",
            "active_app": "kitty",
            "package_count": 1284,
            "spotify_status": "playing",
            "spotify_track": "Nightcall",
            "spotify_artist": "Kavinsky",
            "spotify_art_url": String(Qt.resolvedUrl("demo/covers/nightcall.jpg")),
            "game_status": "playing",
            "game_name": "Cyberpunk 2077",
            "game_display": "Cyberpunk 2077",
            "game_header_url": String(Qt.resolvedUrl("demo/covers/cp2077-header.jpg")),
            "game_session_seconds": 5400,
            "custom_fields": ["mood", "top_artist", "streak", "quote", "listening", "playlist", "genre", "local_time", "weather", "flag", "trip_day", "region", "distance", "caption", "since"],
            "mood": "calm",
            "top_artist": "Robyn",
            "streak": "9",
            "quote": "turn it up",
            "listening": "31",
            "playlist": "Neon Drive",
            "genre": "synthwave",
            "local_time": "23:14",
            "weather": "18° · Clear",
            "flag": "🇯🇵",
            "trip_day": "4",
            "region": "kyoto",
            "distance": "1240 km",
            "caption": "temple steps",
            "since": "3d"
        })
    readonly property var demoPhoto: ({
            "path": String(Qt.resolvedUrl("demo/covers/teardrop.jpg")),
            "created_at": "2026-09-20T12:00:00Z",
            "expires_at": "2099-01-01T00:00:00Z"
        })
    readonly property var demoAccount: root.accountWith(root.demoDevice, root.demoPhoto)

    // custom.json fields run their "cmd" through sh -c, so every value the editor puts
    // into one is shell-quoted. printf avoids the cross-shell escaping differences of echo.
    readonly property string textCmdPrefix: "printf '%s' "
    readonly property string clockCmd: "date +%H:%M"
    readonly property string batteryCmd: "printf '%s%%' \"$(cat /sys/class/power_supply/BAT*/capacity | head -n1)\""
    readonly property int defaultCommandRepeat: 60

    function shQuote(value) {
        return `'${String(value).replace(/'/g, "'\\''")}'`;
    }

    function shUnquote(token) {
        const m = /^'((?:[^']|'\\'')*)'$/.exec(token);
        return m ? m[1].replace(/'\\''/g, "'") : null;
    }

    function shPath(path) {
        const trimmed = path.trim();
        if (trimmed === "~")
            return "\"$HOME\"";
        if (trimmed.startsWith("~/"))
            return `"$HOME"/${root.shQuote(trimmed.slice(2))}`;
        return root.shQuote(trimmed);
    }

    function shUnpath(token) {
        if (token === "\"$HOME\"")
            return "~";
        if (token.startsWith("\"$HOME\"/")) {
            const rest = root.shUnquote(token.slice(8));
            return rest === null ? null : `~/${rest}`;
        }
        return root.shUnquote(token);
    }

    function encodeText(value) {
        return root.textCmdPrefix + root.shQuote(value);
    }

    function decodeText(cmd) {
        if (typeof cmd !== "string" || !cmd.startsWith(root.textCmdPrefix))
            return null;
        return root.shUnquote(cmd.slice(root.textCmdPrefix.length));
    }

    // What an owner-made tile can show. A template is a ready shell command asking at most
    // one question; answerOf reads the answer back out of a cmd, null if it is not this one.
    readonly property var ownerKinds: [
        {
            "id": "weather",
            "label": Translation.tr("Weather"),
            "icon": "partly_cloudy_day",
            "ask": Translation.tr("City"),
            "hint": Translation.tr("City, blank for where you are"),
            "sample": "18° · Clear",
            "repeat": 900,
            "tile": {
                "form": "weather",
                "shape": "auto",
                "size": "1x1",
                "color": "primaryContainer"
            },
            "cmdFor": city => `curl -sf ${root.shQuote(`wttr.in/${encodeURIComponent(city.trim())}?format=%t+·+%C`)}`,
            "answerOf": cmd => {
                const m = /^curl -sf 'wttr\.in\/([^?']*)\?format=%t\+·\+%C'$/.exec(cmd);
                return m ? decodeURIComponent(m[1]) : null;
            }
        },
        {
            "id": "clock",
            "label": Translation.tr("Clock"),
            "icon": "schedule",
            "ask": Translation.tr("Timezone"),
            "hint": Translation.tr("Timezone, eg. Asia/Tokyo, blank for local"),
            "sample": "23:14",
            "repeat": 30,
            "tile": {
                "form": "clock",
                "shape": "auto",
                "size": "1x1",
                "color": "tertiaryContainer"
            },
            "cmdFor": zone => zone.trim() ? `TZ=${root.shQuote(zone.trim())} ${root.clockCmd}` : root.clockCmd,
            "answerOf": cmd => {
                if (cmd === root.clockCmd)
                    return "";
                const m = /^TZ=(.+) date \+%H:%M$/.exec(cmd);
                return m ? root.shUnquote(m[1]) : null;
            }
        },
        {
            "id": "commits",
            "label": Translation.tr("Commits today"),
            "icon": "commit",
            "ask": Translation.tr("Folder"),
            "hint": Translation.tr("A git folder, eg. ~/Projects/app"),
            "needsAnswer": true,
            "sample": "7",
            "repeat": 300,
            "tile": {
                "form": "number",
                "size": "1x1"
            },
            "cmdFor": folder => `git -C ${root.shPath(folder)} rev-list --count --since=midnight HEAD`,
            "answerOf": cmd => {
                const m = /^git -C (.+) rev-list --count --since=midnight HEAD$/.exec(cmd);
                return m ? root.shUnpath(m[1]) : null;
            }
        },
        {
            "id": "battery",
            "label": Translation.tr("Battery"),
            "icon": "battery_5_bar",
            "sample": "82%",
            "repeat": 120,
            "tile": {
                "form": "ring",
                "size": "1x1",
                "color": "tertiaryContainer"
            },
            "cmdFor": () => root.batteryCmd,
            "answerOf": cmd => cmd === root.batteryCmd ? "" : null
        },
        {
            "id": "text",
            "label": Translation.tr("Your text"),
            "defaultName": Translation.tr("Note"),
            "icon": "edit_note",
            "ask": Translation.tr("Text"),
            "hint": Translation.tr("What friends see"),
            "sample": Translation.tr("brb, coffee"),
            "tile": {
                "form": "text",
                "size": "2x1"
            }
        },
        {
            "id": "command",
            "label": Translation.tr("Your command"),
            "defaultName": Translation.tr("Output"),
            "icon": "terminal",
            "ask": Translation.tr("Command"),
            "hint": Translation.tr("Shell command, its output is the value"),
            "sample": "42",
            "repeat": root.defaultCommandRepeat,
            "tile": {
                "form": "text",
                "size": "2x1",
                "color": "primaryContainer"
            }
        }
    ]

    function ownerKind(id) {
        return root.ownerKinds.find(k => k.id === id) ?? null;
    }

    function isCommandKind(id) {
        return id !== "text" && root.ownerKind(id) !== null;
    }

    readonly property var galleryGroups: [
        {
            "title": Translation.tr("Live"),
            "entries": ["weather", "clock", "commits", "battery"].map(id => root.galleryEntryFor(root.ownerKind(id)))
        },
        {
            "title": Translation.tr("Your own"),
            "entries": ["text", "command"].map(id => root.galleryEntryFor(root.ownerKind(id)))
        },
        {
            "title": Translation.tr("Activity"),
            "entries": [
                {
                    "id": "music-cover",
                    "label": Translation.tr("Music - cover"),
                    "tile": {
                        "type": "music",
                        "form": "cover",
                        "size": "4x1",
                        "background": {
                            "kind": "live",
                            "value": "music"
                        }
                    }
                },
                {
                    "id": "game",
                    "label": Translation.tr("Game"),
                    "tile": {
                        "type": "game",
                        "form": "banner",
                        "size": "4x1",
                        "background": {
                            "kind": "live",
                            "value": "game"
                        }
                    }
                },
                {
                    "id": "music-wave",
                    "label": Translation.tr("Music - wave"),
                    "tile": {
                        "type": "music",
                        "form": "wave",
                        "size": "2x1",
                        "color": "tertiaryContainer"
                    }
                },
                {
                    "id": "game-timer",
                    "label": Translation.tr("Game - session"),
                    "tile": {
                        "type": "game",
                        "form": "timer",
                        "size": "2x1"
                    }
                },
                {
                    "id": "window",
                    "label": Translation.tr("Active window"),
                    "tile": {
                        "type": "scalar",
                        "field": "active_window",
                        "form": "text",
                        "size": "4x1"
                    }
                },
                {
                    "id": "music-vinyl",
                    "label": Translation.tr("Music - vinyl"),
                    "tile": {
                        "type": "music",
                        "form": "vinyl",
                        "size": "2x2",
                        "color": "primaryContainer"
                    }
                },
                {
                    "id": "photo",
                    "label": Translation.tr("Photo"),
                    "tile": {
                        "type": "photo",
                        "size": "1x1"
                    }
                },
                {
                    "id": "workspace",
                    "label": Translation.tr("Workspace"),
                    "tile": {
                        "type": "scalar",
                        "field": "workspace",
                        "form": "number",
                        "size": "1x1",
                        "color": "tertiaryContainer"
                    }
                }
            ]
        },
        {
            "title": Translation.tr("System"),
            "entries": [
                {
                    "id": "cpu",
                    "label": Translation.tr("CPU ring"),
                    "tile": {
                        "type": "scalar",
                        "field": "cpu",
                        "form": "ring",
                        "size": "1x1",
                        "color": "primaryContainer",
                        "background": {
                            "kind": "color",
                            "value": "primaryContainer"
                        }
                    }
                },
                {
                    "id": "mem",
                    "label": Translation.tr("Memory bar"),
                    "tile": {
                        "type": "scalar",
                        "field": "mem",
                        "form": "bar",
                        "size": "2x1",
                        "color": "primaryContainer"
                    }
                },
                {
                    "id": "disk",
                    "label": Translation.tr("Disk ring"),
                    "tile": {
                        "type": "scalar",
                        "field": "disk",
                        "form": "ring",
                        "size": "1x1",
                        "color": "tertiaryContainer",
                        "background": {
                            "kind": "color",
                            "value": "tertiaryContainer"
                        }
                    }
                },
                {
                    "id": "load",
                    "label": Translation.tr("Load"),
                    "tile": {
                        "type": "scalar",
                        "field": "load",
                        "form": "number",
                        "size": "1x1",
                        "color": "tertiaryContainer"
                    }
                },
                {
                    "id": "uptime",
                    "label": Translation.tr("Uptime"),
                    "tile": {
                        "type": "scalar",
                        "field": "uptime",
                        "form": "number",
                        "size": "1x1",
                        "color": "primaryContainer"
                    }
                },
                {
                    "id": "packages",
                    "label": Translation.tr("Packages"),
                    "tile": {
                        "type": "scalar",
                        "field": "package_count",
                        "form": "number",
                        "size": "1x1"
                    }
                }
            ]
        }
    ]

    function galleryEntryFor(kind) {
        return {
            "id": kind.id,
            "label": kind.label,
            "ownerKind": kind.id,
            "tile": Object.assign({
                "type": "scalar",
                "field": root.normalizeFieldName(kind.defaultName ?? kind.label)
            }, kind.tile)
        };
    }

    function galleryEntry(id) {
        for (const group of root.galleryGroups) {
            const found = group.entries.find(e => e.id === id);
            if (found)
                return found;
        }
        return null;
    }

    readonly property var formNames: ({
            "ring": Translation.tr("Ring"),
            "bar": Translation.tr("Bar"),
            "number": Translation.tr("Number"),
            "text": Translation.tr("Text"),
            "big": Translation.tr("Sticker"),
            "clock": Translation.tr("Clock"),
            "weather": Translation.tr("Weather"),
            "cover": Translation.tr("Cover"),
            "vinyl": Translation.tr("Vinyl"),
            "wave": Translation.tr("Wave"),
            "banner": Translation.tr("Banner"),
            "timer": Translation.tr("Session")
        })

    function formOptionsFor(type) {
        const forms = type === "music" ? Statusphere.validMusicForms : type === "game" ? Statusphere.validGameForms : type === "scalar" ? Statusphere.validScalarForms : [];
        return forms.map(f => ({
                    "displayName": root.formNames[f] ?? f,
                    "value": f
                }));
    }

    function tileTitle(tile) {
        if (!tile)
            return "";
        switch (tile.type) {
        case "music":
            return Translation.tr("Music");
        case "game":
            return Translation.tr("Game");
        case "photo":
            return Translation.tr("Photo");
        default:
            return tile.field === "*" ? Translation.tr("Everything else") : Statusphere.labelForKey(tile.field);
        }
    }

    // Forces every tile to stay on screen and clickable in the editor, even one that would
    // normally hide for missing data - the layout being edited is not necessarily live yet.
    function previewSafe(tiles) {
        return tiles.map(t => t.onMissing === "hide" ? Object.assign({}, t, {
                    "onMissing": "dim"
                }) : t);
    }

    readonly property var previewTiles: {
        const tiles = root.editSurface === "detail" ? CardLayouts.fallbackDetail(root.editTiles, Statusphere.detailFieldsFor(root.previewAccount)) : root.editTiles;
        return root.previewSafe(tiles);
    }

    function accountWith(device, photo) {
        return {
            "id": root.ownerAccount?.id ?? "owner",
            "primary": device,
            "devices": [device],
            "offline": false,
            "_photo": photo
        };
    }

    function withValues(device, values) {
        const fields = new Set(device?.custom_fields ?? []);
        for (const key of Object.keys(values))
            fields.add(key);
        return Object.assign({}, device ?? {}, values, {
            "custom_fields": [...fields]
        });
    }

    // A value the owner typed or tested has nowhere to live in selfAccount until the cli
    // picks custom.json up, so the preview overlays it onto a copy of the owner's device.
    readonly property var knownValues: {
        const values = {};
        for (const key of Object.keys(root.customEntries)) {
            const text = root.decodeText(root.customEntries[key]?.cmd);
            if (text !== null)
                values[key] = text;
        }
        return Object.assign(values, root.testedValues);
    }

    readonly property var previewAccount: {
        const account = root.ownerAccount;
        if (!account)
            return root.accountWith(root.withValues({}, root.knownValues), null);
        return Object.assign({}, account, {
            "primary": root.withValues(account.primary, root.knownValues),
            "devices": (account.devices ?? []).map(d => root.withValues(d, root.knownValues))
        });
    }

    readonly property var galleryAccount: {
        const samples = {};
        for (const kind of root.ownerKinds)
            samples[root.normalizeFieldName(kind.defaultName ?? kind.label)] = kind.sample;
        const device = root.withValues(Object.assign({}, root.demoDevice, root.ownerAccount?.primary ?? {}), samples);
        return root.accountWith(device, Statusphere.currentPhotoFor(root.ownerAccount) ?? root.demoPhoto);
    }

    function normalizeFieldName(name) {
        return String(name).trim().toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
    }

    function uniqueFieldKey(base, except) {
        const taken = new Set(root.allTiles.filter(t => t.type === "scalar").map(t => t.field).concat(Object.keys(root.customEntries)));
        taken.delete(except);
        const stem = base || "field";
        let key = stem;
        for (let n = 2; !Statusphere.isCustomFieldKey(key) || taken.has(key); n++)
            key = `${stem}_${n}`;
        return key;
    }

    function sourceOf(key) {
        const entry = root.customEntries[key];
        if (!entry)
            return null;
        const text = root.decodeText(entry.cmd);
        if (text !== null)
            return {
                "kind": "text",
                "answer": text,
                "repeat": 0
            };
        for (const kind of root.ownerKinds) {
            const answer = kind.answerOf ? kind.answerOf(entry.cmd) : null;
            if (answer !== null)
                return {
                    "kind": kind.id,
                    "answer": answer,
                    "repeat": entry.repeat_seconds ?? kind.repeat
                };
        }
        return {
            "kind": "command",
            "answer": entry.cmd ?? "",
            "repeat": entry.repeat_seconds ?? root.defaultCommandRepeat
        };
    }

    readonly property var kindByForm: ({
            "weather": "weather",
            "clock": "clock"
        })

    // A pack names a field without writing custom.json: a weather or clock form says which
    // template it wants, anything else starts out as the owner's own text.
    function kindFromForm(key) {
        const tile = root.allTiles.find(t => t.type === "scalar" && t.field === key);
        return root.kindByForm[tile?.form] ?? "text";
    }

    function shownKindFor(key) {
        return root.chosenKinds[key] ?? root.sourceOf(key)?.kind ?? root.kindFromForm(key);
    }

    function kindChoicesFor(key) {
        const ids = [root.sourceOf(key)?.kind ?? root.kindFromForm(key), "text", "command"];
        return [...new Set(ids)].map(id => root.ownerKind(id)).map(k => ({
                    "displayName": k.label,
                    "icon": k.icon,
                    "value": k.id
                }));
    }

    function answerFor(key, kindId) {
        const source = root.sourceOf(key);
        if (!source)
            return "";
        if (source.kind === kindId)
            return source.answer;
        return kindId === "command" ? (root.customEntries[key]?.cmd ?? "") : "";
    }

    function repeatFor(key, kindId) {
        const source = root.sourceOf(key);
        return source && source.repeat > 0 ? source.repeat : (root.ownerKind(kindId)?.repeat ?? root.defaultCommandRepeat);
    }

    function commandFor(kindId, answer) {
        if (kindId === "text")
            return root.encodeText(answer);
        if (kindId === "command")
            return answer.trim();
        const kind = root.ownerKind(kindId);
        return kind.needsAnswer && !answer.trim() ? "" : kind.cmdFor(answer);
    }

    function chooseKind(key, kindId) {
        root.chosenKinds = Object.assign({}, root.chosenKinds, {
            [key]: kindId
        });
    }

    function setAnswer(key, kindId, answer) {
        const cmd = root.commandFor(kindId, answer);
        if (!cmd || (kindId === "text" && !answer)) {
            root.dropEntry(key);
            return;
        }
        root.setEntry(key, {
            "cmd": cmd,
            "repeat_seconds": kindId === "text" ? 0 : root.repeatFor(key, kindId)
        });
    }

    function setRepeat(key, seconds) {
        const entry = root.customEntries[key];
        if (!entry || !(seconds > 0) || entry.repeat_seconds === seconds)
            return;
        root.setEntry(key, Object.assign({}, entry, {
            "repeat_seconds": seconds
        }));
    }

    function setTestedValue(key, value) {
        root.testedValues = Object.assign({}, root.testedValues, {
            [key]: value
        });
    }

    function setEntry(key, entry) {
        const current = root.customEntries[key];
        if (current && current.cmd === entry.cmd && current.repeat_seconds === entry.repeat_seconds)
            return;
        root.customEntries = Object.assign({}, root.customEntries, {
            [key]: entry
        });
        if (!root.ownedFields.includes(key))
            root.setOwnedFields(root.ownedFields.concat([key]));
        root.markCustomChanged();
    }

    function isOwned(key) {
        return root.ownedFields.includes(key) || (root.sourceOf(key)?.kind ?? "command") !== "command";
    }

    function dropEntry(key) {
        if (root.customEntries[key] === undefined || !root.isOwned(key))
            return;
        const next = Object.assign({}, root.customEntries);
        delete next[key];
        root.customEntries = next;
        root.setOwnedFields(root.ownedFields.filter(k => k !== key));
        root.markCustomChanged();
    }

    function setOwnedFields(keys) {
        WidgetsStore.setOption("statusphere", "editorOwnedFields", keys);
    }

    // A "*" tile shows every field the layout does not name, so while one is on the card
    // no custom.json key is unused.
    function dropUnusedEntries() {
        if (root.allTiles.some(t => t.field === "*"))
            return;
        const used = new Set(root.allTiles.filter(t => t.type === "scalar").map(t => t.field));
        for (const key of Object.keys(root.customEntries))
            if (!used.has(key))
                root.dropEntry(key);
    }

    function renameField(key, label) {
        const base = root.normalizeFieldName(label);
        if (!base || base === key)
            return;
        const next = root.uniqueFieldKey(base, key);
        const rename = tiles => tiles.map(t => t.type === "scalar" && t.field === key ? Object.assign({}, t, {
                        "field": next
                    }) : t);
        const entry = root.customEntries[key];
        if (entry)
            root.setEntry(next, entry);
        if (root.chosenKinds[key])
            root.chooseKind(next, root.chosenKinds[key]);
        root.setLayout(rename(root.editRow), rename(root.editDetail));
    }

    function setLayout(row, detail) {
        root.editRow = row;
        root.editDetail = detail;
        root.dropUnusedEntries();
        root.markLayoutChanged();
    }

    function setSurfaceTiles(tiles) {
        if (root.editSurface === "row")
            root.setLayout(tiles, root.editDetail);
        else
            root.setLayout(root.editRow, tiles);
    }

    function selectSurface(surface) {
        root.editSurface = surface;
        root.selectedIndex = -1;
    }

    function selectTile(index) {
        root.galleryOpen = false;
        root.selectedIndex = root.selectedIndex === index ? -1 : index;
    }

    function openGallery() {
        root.selectedIndex = -1;
        root.galleryOpen = !root.galleryOpen;
    }

    function rememberUndo() {
        root.undoState = {
            "row": root.editRow,
            "detail": root.editDetail,
            "entries": root.customEntries,
            "owned": root.ownedFields
        };
    }

    function undo() {
        const state = root.undoState;
        if (!state)
            return;
        root.undoState = null;
        root.selectedIndex = -1;
        root.customEntries = state.entries;
        root.setOwnedFields(state.owned);
        root.markCustomChanged();
        root.setLayout(state.row, state.detail);
    }

    function applyPack(id) {
        const pack = CardLayouts.packFor(root.editSurface, id);
        if (!pack)
            return;
        root.rememberUndo();
        root.selectedIndex = -1;
        root.packsOpen = false;
        root.setSurfaceTiles(pack.tiles);
    }

    function addFromGallery(id) {
        const entry = root.galleryEntry(id);
        if (!entry)
            return;
        const kind = root.ownerKind(entry.ownerKind ?? "");
        const tile = CardLayouts.tile(entry.tile);
        if (kind)
            tile.field = root.uniqueFieldKey(tile.field, "");
        root.galleryOpen = false;
        root.setSurfaceTiles(root.editTiles.concat([tile]));
        root.selectedIndex = root.editTiles.length - 1;
        if (kind && kind.answerOf && !kind.needsAnswer)
            root.setAnswer(tile.field, kind.id, "");
        else if (kind)
            root.chooseKind(tile.field, kind.id);
    }

    function updateSelectedTile(patch) {
        if (!root.selectedTile)
            return;
        const tiles = root.editTiles.slice();
        tiles[root.selectedIndex] = Object.assign({}, tiles[root.selectedIndex], patch);
        root.setSurfaceTiles(tiles);
    }

    function removeTileAt(index) {
        root.rememberUndo();
        const tiles = root.editTiles.slice();
        tiles.splice(index, 1);
        if (root.selectedIndex === index)
            root.selectedIndex = -1;
        else if (root.selectedIndex > index)
            root.selectedIndex -= 1;
        root.setSurfaceTiles(tiles);
    }

    // Drop onto another tile's slot inserts before it; everything from there on shifts
    // over by one, same as pulling a card out of a hand and sliding it back in elsewhere.
    function reorderTile(from, to) {
        if (!root.editTiles[from] || from === to)
            return;
        const tiles = root.editTiles.slice();
        const [moved] = tiles.splice(from, 1);
        const insertAt = from < to ? to - 1 : to;
        tiles.splice(insertAt, 0, moved);
        root.setSurfaceTiles(tiles);
        root.selectedIndex = insertAt;
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
                "row": root.editRow,
                "detail": root.editDetail
            }, null, 2));
        }
        if (root.customPending) {
            root.customPending = false;
            customFieldsFile.setText(JSON.stringify(root.customEntries, null, 2));
        }
        root.savedOnce = true;
    }

    function loadMyLayout() {
        if (root.layoutPending)
            return;
        try {
            const saved = JSON.parse(layoutFile.text());
            root.editRow = saved.row ?? [];
            root.editDetail = saved.detail ?? [];
        } catch (e) {
            root.editRow = [];
            root.editDetail = [];
        }
        if (root.selectedIndex >= root.editTiles.length)
            root.selectedIndex = -1;
        root.packsOpen = root.allTiles.length === 0;
    }

    function loadMyCustomFields() {
        if (root.customPending)
            return;
        try {
            const raw = JSON.parse(customFieldsFile.text());
            root.customEntries = raw && typeof raw === "object" && !Array.isArray(raw) ? raw : {};
        } catch (e) {
            root.customEntries = {};
        }
    }

    Component.onDestruction: root.flush()

    Timer {
        id: autosave
        interval: root.autosaveDelayMs
        onTriggered: root.flush()
    }

    FileView {
        id: layoutFile
        path: `${Directories.config}/statusphere/layout.json`
        printErrors: false
        onLoaded: root.loadMyLayout()
        onLoadFailed: root.loadMyLayout()
    }

    FileView {
        id: customFieldsFile
        path: `${Directories.config}/statusphere/custom.json`
        printErrors: false
        onLoaded: root.loadMyCustomFields()
        onLoadFailed: root.loadMyCustomFields()
    }

    SecondaryTabBar {
        id: surfaceTabs
        Layout.fillWidth: true
        currentIndex: root.editSurface === "row" ? 0 : 1
        onCurrentIndexChanged: root.selectSurface(surfaceTabs.currentIndex === 0 ? "row" : "detail")

        SecondaryTabButton {
            buttonText: Translation.tr("Row")
        }
        SecondaryTabButton {
            buttonText: Translation.tr("Detail")
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Math.max(80, preview.implicitHeight + 16 + (emptyHint.visible && preview.rowsUsed > 0 ? emptyHint.implicitHeight + 8 : 0))
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1

        StyledText {
            id: emptyHint
            visible: root.editTiles.length === 0
            x: 16
            y: preview.rowsUsed > 0 ? preview.y + preview.height + 8 : (parent.height - emptyHint.height) / 2
            width: parent.width - 32
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.editSurface === "detail" ? Translation.tr("Friends see the standard detail card until you add a tile") : Translation.tr("No tiles yet - add one or start from a pack")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }

        CardGrid {
            id: preview
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            account: root.previewAccount
            maxRows: CardLayouts.rowsFor(root.editSurface)
            tiles: root.previewTiles
            selectable: true
            reorderable: true
            selectedIndex: root.selectedIndex
            onTileClicked: index => root.selectTile(index)
            onTileMoved: (fromIndex, toIndex) => root.reorderTile(fromIndex, toIndex)
            onTileRemoveRequested: index => root.removeTileAt(index)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        RippleButtonWithIcon {
            materialIcon: root.galleryOpen ? "close" : "add"
            mainText: Translation.tr("Add a tile")
            onClicked: root.openGallery()
        }

        RippleButtonWithIcon {
            materialIcon: "style"
            mainText: Translation.tr("Start from a pack")
            onClicked: root.packsOpen = !root.packsOpen
        }

        Item {
            Layout.fillWidth: true
        }

        RippleButtonWithIcon {
            visible: root.undoState !== null
            materialIcon: "undo"
            mainText: Translation.tr("Undo")
            onClicked: root.undo()
        }

        StyledText {
            visible: root.saving || root.savedOnce
            text: root.saving ? Translation.tr("Saving") : Translation.tr("Saved")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }

    Flow {
        id: packList
        Layout.fillWidth: true
        visible: root.packsOpen
        spacing: 8

        readonly property var packs: CardLayouts.packsFor(root.editSurface)
        readonly property int maxRows: CardLayouts.rowsFor(root.editSurface)
        readonly property int thumbRows: Math.max(1, ...packList.packs.map(p => CardLayouts.rowsUsed(CardLayouts.pack(p.tiles, packList.maxRows))))
        readonly property real thumbWidth: (packList.width - (packList.packs.length - 1) * packList.spacing) / packList.packs.length
        readonly property real thumbPadding: 4

        Repeater {
            model: packList.packs

            delegate: ColumnLayout {
                id: packDelegate
                required property var modelData
                spacing: 4

                Rectangle {
                    implicitWidth: packList.thumbWidth
                    implicitHeight: packThumb.cellSize * packList.thumbRows + packThumb.spacing * (packList.thumbRows - 1) + 2 * packList.thumbPadding
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2
                    border.width: packArea.containsMouse ? 2 : 1
                    border.color: packArea.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    clip: true

                    CardGrid {
                        id: packThumb
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: packList.thumbPadding
                        }
                        account: root.demoAccount
                        maxRows: packList.maxRows
                        thumbnail: true
                        tiles: root.previewSafe(packDelegate.modelData.tiles)
                    }

                    MouseArea {
                        id: packArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyPack(packDelegate.modelData.id)
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: packDelegate.modelData.name
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    ColumnLayout {
        id: gallery
        Layout.fillWidth: true
        visible: root.galleryOpen
        spacing: 6

        readonly property real gap: 8
        readonly property real labelGap: 4
        readonly property real cell: (gallery.width - (CardLayouts.columns - 1) * gallery.gap) / CardLayouts.columns

        Repeater {
            model: root.galleryGroups

            delegate: ColumnLayout {
                id: galleryGroup
                required property var modelData
                Layout.fillWidth: true
                spacing: 4

                ContentSubsectionLabel {
                    text: galleryGroup.modelData.title
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: gallery.gap

                    Repeater {
                        model: galleryGroup.modelData.entries

                        delegate: RippleButton {
                            id: galleryCard
                            required property var modelData
                            readonly property var span: CardLayouts.spanOf(galleryCard.modelData.tile.size)
                            implicitWidth: galleryCard.span.cols * gallery.cell + (galleryCard.span.cols - 1) * gallery.gap
                            implicitHeight: galleryTile.height + cardLabel.implicitHeight + 2 * gallery.labelGap
                            buttonRadius: Appearance.rounding.large
                            onClicked: root.addFromGallery(galleryCard.modelData.id)

                            CardTile {
                                id: galleryTile
                                width: parent.width
                                height: galleryCard.span.rows * gallery.cell + (galleryCard.span.rows - 1) * gallery.gap
                                account: root.galleryAccount
                                tile: CardLayouts.tile(galleryCard.modelData.tile)
                            }

                            StyledText {
                                id: cardLabel
                                width: parent.width
                                y: galleryTile.height + gallery.labelGap
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: galleryCard.modelData.label
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }
    }

    TileSheet {
        Layout.fillWidth: true
        visible: root.selectedTile !== null && !root.galleryOpen
        editor: root
    }
}
