pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "CardLayouts.js" as CardLayouts
import "Templates.js" as Templates

ColumnLayout {
    id: root
    spacing: 8

    readonly property var ownerAccount: Statusphere.selfAccount
    readonly property var editRow: store.row
    readonly property var editDetail: store.detail
    property string editSurface: "row"
    property int selectedIndex: -1
    property bool galleryOpen: false
    property bool packsOpen: false
    readonly property var customEntries: store.entries
    property var testedValues: ({})
    property var chosenKinds: ({})
    readonly property var undoState: store.undoState

    readonly property var editTiles: root.editSurface === "row" ? root.editRow : root.editDetail
    readonly property var allTiles: root.editRow.concat(root.editDetail)
    readonly property var selectedTile: (root.selectedIndex >= 0 && root.selectedIndex < root.editTiles.length) ? root.editTiles[root.selectedIndex] : null

    readonly property CardStore store: CardStore {
        id: store
        onLayoutLoaded: {
            if (root.selectedIndex >= root.editTiles.length)
                root.selectedIndex = -1;
            root.packsOpen = root.allTiles.length === 0;
        }
    }

    // Plausible values for every field a pack or gallery tile can name, so a thumbnail
    // reads at a glance instead of showing "-" for data this machine has none of.
    readonly property var demoDevice: Object.assign({
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
            "custom_fields": Object.keys(CardLayouts.packTexts).concat(["local_time", "weather"]),
            "local_time": "23:14",
            "weather": "18° · Clear"
        }, CardLayouts.packTexts)
    readonly property var demoPhoto: ({
            "path": String(Qt.resolvedUrl("demo/covers/teardrop.jpg")),
            "created_at": "2026-09-20T12:00:00Z",
            "expires_at": "2099-01-01T00:00:00Z"
        })
    readonly property var demoAccount: root.accountWith(root.demoDevice, root.demoPhoto)

    readonly property var galleryGroups: Templates.galleryGroups

    function formOptionsFor(typeName) {
        const forms = CardLayouts.tileTypes[typeName]?.forms ?? {};
        return Object.keys(forms).map(f => ({
                    "displayName": Translation.tr(forms[f].label),
                    "value": f
                }));
    }

    function tileTitle(tile) {
        if (!tile)
            return "";
        const label = CardLayouts.typeOf(tile)?.label ?? "";
        if (label)
            return Translation.tr(label);
        return tile.field === "*" ? Translation.tr("Everything else") : Statusphere.labelForKey(tile.field);
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
            const text = Templates.decodeText(root.customEntries[key]?.cmd);
            if (text !== null)
                values[key] = text;
        }
        return Object.assign(values, root.testedValues);
    }

    // Every snapshot rebuilds selfAccount even when the owner's own device did not change,
    // so the preview and gallery accounts only take a value that differs from the last one.
    property var previewAccount: null
    property var galleryAccount: null
    onFreshPreviewAccountChanged: root.keepIfChanged("previewAccount", root.freshPreviewAccount)
    onFreshGalleryAccountChanged: root.keepIfChanged("galleryAccount", root.freshGalleryAccount)
    Component.onCompleted: {
        root.previewAccount = root.freshPreviewAccount;
        root.galleryAccount = root.freshGalleryAccount;
    }

    function keepIfChanged(name, value) {
        if (JSON.stringify(root[name]) !== JSON.stringify(value))
            root[name] = value;
    }

    readonly property var freshPreviewAccount: {
        const account = root.ownerAccount;
        if (!account)
            return root.accountWith(root.withValues({}, root.knownValues), null);
        return Object.assign({}, account, {
            "primary": root.withValues(account.primary, root.knownValues),
            "devices": (account.devices ?? []).map(d => root.withValues(d, root.knownValues))
        });
    }

    readonly property var freshGalleryAccount: {
        const samples = {};
        for (const kind of Templates.kinds)
            samples[Templates.fieldKeyOfKind(kind)] = Translation.tr(kind.sample);
        const device = root.withValues(Object.assign({}, root.demoDevice, root.ownerAccount?.primary ?? {}), samples);
        return root.accountWith(device, Statusphere.currentPhotoFor(root.ownerAccount) ?? root.demoPhoto);
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
        const text = Templates.decodeText(entry.cmd);
        if (text !== null)
            return {
                "kind": "text",
                "answer": text,
                "repeat": 0
            };
        const stored = store.fieldKinds[key];
        const kind = Templates.kind(stored?.kind);
        const answer = stored?.answer ?? "";
        if (kind?.cmdFor && kind.cmdFor(answer) === entry.cmd)
            return {
                "kind": kind.id,
                "answer": answer,
                "repeat": entry.repeat_seconds ?? kind.repeat
            };
        return {
            "kind": "command",
            "answer": entry.cmd ?? "",
            "repeat": entry.repeat_seconds ?? Templates.defaultCommandRepeat
        };
    }

    // A field with no custom.json entry yet: a weather or clock form says which template it
    // wants, anything else starts out as the owner's own text.
    function kindFromForm(key) {
        const tile = root.allTiles.find(t => t.type === "scalar" && t.field === key);
        return Templates.kindByForm[tile?.form] ?? "text";
    }

    function shownKindFor(key) {
        return root.chosenKinds[key] ?? root.sourceOf(key)?.kind ?? root.kindFromForm(key);
    }

    function kindChoicesFor(key) {
        const ids = [root.sourceOf(key)?.kind ?? root.kindFromForm(key), "text", "command"];
        return [...new Set(ids)].map(id => Templates.kind(id)).map(k => ({
                    "displayName": Translation.tr(k.label),
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
        return source && source.repeat > 0 ? source.repeat : (Templates.kind(kindId)?.repeat ?? Templates.defaultCommandRepeat);
    }

    function commandFor(kindId, answer) {
        if (kindId === "text")
            return Templates.encodeText(answer);
        if (kindId === "command")
            return answer.trim();
        const kind = Templates.kind(kindId);
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
        store.setEntry(key, {
            "cmd": cmd,
            "repeat_seconds": kindId === "text" ? 0 : root.repeatFor(key, kindId)
        }, root.fieldKindOf(kindId, answer));
    }

    function fieldKindOf(kindId, answer) {
        return Templates.kind(kindId)?.cmdFor ? {
            "kind": kindId,
            "answer": answer
        } : {
            "kind": kindId
        };
    }

    function setRepeat(key, seconds) {
        const entry = root.customEntries[key];
        if (!entry || !(seconds > 0) || entry.repeat_seconds === seconds)
            return;
        const source = root.sourceOf(key);
        store.setEntry(key, Object.assign({}, entry, {
            "repeat_seconds": seconds
        }), root.fieldKindOf(source.kind, source.answer));
    }

    function setTestedValue(key, value) {
        root.testedValues = Object.assign({}, root.testedValues, {
            [key]: value
        });
    }

    function dropEntry(key) {
        if (root.customEntries[key] === undefined || !store.isOwned(key))
            return;
        store.removeEntry(key);
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
        const base = Templates.fieldKeyOf(label);
        if (!base || base === key)
            return;
        const next = root.uniqueFieldKey(base, key);
        const rename = tiles => tiles.map(t => t.type === "scalar" && t.field === key ? Object.assign({}, t, {
                        "field": next
                    }) : t);
        const entry = root.customEntries[key];
        if (entry)
            store.setEntry(next, entry, store.fieldKinds[key] ?? {});
        if (root.chosenKinds[key])
            root.chooseKind(next, root.chosenKinds[key]);
        root.setLayout(rename(root.editRow), rename(root.editDetail));
    }

    function setLayout(row, detail) {
        store.setLayout(row, detail);
        root.dropUnusedEntries();
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

    function undo() {
        if (store.undo()) {
            root.selectedIndex = -1;
            root.dropUnusedEntries();
        }
    }

    function applyPack(id) {
        const pack = CardLayouts.packFor(root.editSurface, id);
        if (!pack)
            return;
        store.rememberUndo();
        root.selectedIndex = -1;
        root.packsOpen = false;
        root.setSurfaceTiles(pack.tiles);
        root.seedEntries(pack.tiles);
    }

    function seedEntries(tiles) {
        for (const tile of tiles) {
            if (tile.type !== "scalar" || !Statusphere.isCustomFieldKey(tile.field) || root.customEntries[tile.field])
                continue;
            const kindId = root.kindFromForm(tile.field);
            root.setAnswer(tile.field, kindId, kindId === "text" ? (CardLayouts.packTexts[tile.field] ?? "") : "");
        }
    }

    function addFromGallery(id) {
        const entry = Templates.galleryEntry(id);
        if (!entry)
            return;
        const kind = Templates.kind(entry.ownerKind ?? "");
        const tile = CardLayouts.tile(entry.tile);
        if (kind)
            tile.field = root.uniqueFieldKey(tile.field, "");
        root.galleryOpen = false;
        root.setSurfaceTiles(root.editTiles.concat([tile]));
        root.selectedIndex = root.editTiles.length - 1;
        if (Templates.seedsItself(kind))
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
        store.rememberUndo();
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
            visible: store.saving || store.savedOnce
            text: store.saving ? Translation.tr("Saving") : Translation.tr("Saved")
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
        readonly property real thumbWidth: Math.floor((packList.width - (packList.packs.length - 1) * packList.spacing) / packList.packs.length)
        readonly property real thumbPadding: 4

        Repeater {
            model: root.packsOpen ? packList.packs : []

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
        spacing: 2

        readonly property real gap: CardLayouts.gap
        readonly property real labelGap: 4
        readonly property int miniColumns: 6
        readonly property real cardCell: (gallery.width - (CardLayouts.columns - 1) * gallery.gap) / CardLayouts.columns
        readonly property real entryScale: gallery.width / (gallery.miniColumns * gallery.cardCell + (gallery.miniColumns - 1) * gallery.gap)

        Repeater {
            model: root.galleryGroups

            delegate: ColumnLayout {
                id: galleryGroup
                required property var modelData
                property bool expanded: galleryGroup.modelData.startsOpen === true
                Layout.fillWidth: true
                spacing: 4

                RippleButtonWithIcon {
                    materialIcon: galleryGroup.expanded ? "expand_less" : "expand_more"
                    mainText: Translation.tr(galleryGroup.modelData.title)
                    onClicked: galleryGroup.expanded = !galleryGroup.expanded
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 6
                    visible: galleryGroup.expanded
                    spacing: gallery.gap * gallery.entryScale

                    Repeater {
                        model: root.galleryOpen && galleryGroup.expanded ? galleryGroup.modelData.entries : []

                        delegate: RippleButton {
                            id: galleryCard
                            required property var modelData
                            readonly property var span: CardLayouts.spanOf(galleryCard.modelData.tile.size)
                            implicitWidth: galleryTile.width * gallery.entryScale
                            implicitHeight: galleryTile.height * gallery.entryScale + cardLabel.implicitHeight + 2 * gallery.labelGap
                            buttonRadius: Appearance.rounding.normal
                            onClicked: root.addFromGallery(galleryCard.modelData.id)

                            CardTile {
                                id: galleryTile
                                width: galleryCard.span.cols * gallery.cardCell + (galleryCard.span.cols - 1) * gallery.gap
                                height: galleryCard.span.rows * gallery.cardCell + (galleryCard.span.rows - 1) * gallery.gap
                                scale: gallery.entryScale
                                transformOrigin: Item.TopLeft
                                account: root.galleryAccount
                                tile: CardLayouts.tile(galleryCard.modelData.tile)
                            }

                            StyledText {
                                id: cardLabel
                                objectName: "galleryEntryLabel"
                                width: parent.width
                                y: galleryTile.height * gallery.entryScale + gallery.labelGap
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: Translation.tr(galleryCard.modelData.label)
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
