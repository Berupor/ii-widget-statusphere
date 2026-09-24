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

    // A spin box clamps to its minimum before the value binding lands and reports
    // that as a change, so on a fresh store every number would save as its minimum
    property bool ready: false
    Component.onCompleted: root.ready = true

    function setOption(key, value) {
        if (!root.ready || Statusphere.opt(key) === value) // Controls write back their own value on load
            return;
        WidgetsStore.setOption("statusphere", key, value);
    }

    // The card editor: a local, unsaved copy of the two surfaces until "Save" writes them
    // to layout.json. The owner's own account feeds the preview so fields read real values
    // where there is data, "-" where there isn't.
    readonly property var ownerAccount: Statusphere.selfAccount
    property var editRow: []
    property var editDetail: []
    property string editSurface: "row"
    property int selectedIndex: -1
    property string selectedPresetName: ""
    property string savedSnapshot: "{}"
    readonly property bool dirty: JSON.stringify({
        "row": root.editRow,
        "detail": root.editDetail
    }) !== root.savedSnapshot

    // Plausible values for every field a catalog entry or preset can name, so a preset
    // thumbnail reads at a glance instead of showing "-" for data this machine has none of.
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
            "weather": "18°C, clear",
            "flag": "🇯🇵",
            "trip_day": "4",
            "region": "kyoto",
            "distance": "1240 km",
            "caption": "temple steps",
            "since": "3d"
        })
    readonly property var demoAccount: ({
            "id": "demo-owner",
            "primary": root.demoDevice,
            "devices": [root.demoDevice],
            "offline": false,
            "_photo": {
                "path": String(Qt.resolvedUrl("demo/covers/teardrop.jpg")),
                "created_at": "2026-09-20T12:00:00Z",
                "expires_at": "2099-01-01T00:00:00Z"
            }
        })
    readonly property var editTiles: root.editSurface === "row" ? root.editRow : root.editDetail
    readonly property var selectedTile: (root.selectedIndex >= 0 && root.selectedIndex < root.editTiles.length) ? root.editTiles[root.selectedIndex] : null
    // Forces every tile to stay on screen and clickable in the editor, even one that would
    // normally hide for missing data - the layout being edited is not necessarily live yet.
    function previewSafe(tiles) {
        return tiles.map(t => t.onMissing === "hide" ? Object.assign({}, t, {
                    "onMissing": "dim"
                }) : t);
    }

    readonly property var previewTiles: root.previewSafe(root.editTiles)

    readonly property var catalog: [
        {
            "label": Translation.tr("Ring"),
            "icon": "donut_large",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "ring",
                    "size": "1x1"
                })
        },
        {
            "label": Translation.tr("Bar"),
            "icon": "bar_chart",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "bar",
                    "size": "2x1"
                })
        },
        {
            "label": Translation.tr("Number"),
            "icon": "123",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "number",
                    "size": "1x1"
                })
        },
        {
            "label": Translation.tr("Text"),
            "icon": "text_fields",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "text",
                    "size": "2x1"
                })
        },
        {
            "label": Translation.tr("Sticker"),
            "icon": "sticky_note_2",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "big",
                    "size": "1x1"
                })
        },
        {
            "label": Translation.tr("Clock"),
            "icon": "schedule",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "clock",
                    "shape": "auto",
                    "size": "1x1"
                })
        },
        {
            "label": Translation.tr("Weather"),
            "icon": "sunny",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "weather",
                    "shape": "auto",
                    "size": "1x1"
                })
        },
        {
            "label": Translation.tr("Music"),
            "icon": "music_note",
            "tile": CardLayouts.tile({
                    "type": "music",
                    "form": "cover",
                    "size": "4x1",
                    "background": {
                        "kind": "live",
                        "value": "music"
                    }
                })
        },
        {
            "label": Translation.tr("Vinyl"),
            "icon": "album",
            "tile": CardLayouts.tile({
                    "type": "music",
                    "form": "vinyl",
                    "size": "2x2"
                })
        },
        {
            "label": Translation.tr("Wave"),
            "icon": "graphic_eq",
            "tile": CardLayouts.tile({
                    "type": "music",
                    "form": "wave",
                    "size": "2x1"
                })
        },
        {
            "label": Translation.tr("Game"),
            "icon": "sports_esports",
            "tile": CardLayouts.tile({
                    "type": "game",
                    "form": "banner",
                    "size": "4x1",
                    "background": {
                        "kind": "live",
                        "value": "game"
                    }
                })
        },
        {
            "label": Translation.tr("Session timer"),
            "icon": "timer",
            "tile": CardLayouts.tile({
                    "type": "game",
                    "form": "timer",
                    "size": "2x1"
                })
        },
        {
            "label": Translation.tr("Photo"),
            "icon": "photo_camera",
            "tile": CardLayouts.tile({
                    "type": "photo",
                    "size": "1x1"
                })
        }
    ]

    readonly property var sizeOptions: ["1x1", "2x1", "2x2", "4x1"]
    // No error role here: it reads as a warning on someone's own card, not a colour choice.
    readonly property var colorOptions: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer"]
    readonly property var shapeOptions: ["default", "auto", "Circle", "Pill", "Arch", "SemiCircle", "Diamond", "Pentagon", "Cookie4Sided", "Cookie6Sided", "Cookie9Sided", "Clover4Leaf", "Heart", "Sunny", "SoftBurst"]
    readonly property var scalarFormOptions: ["ring", "bar", "number", "text", "big", "clock", "weather"]
    readonly property var musicFormOptions: ["cover", "vinyl", "wave"]
    readonly property var gameFormOptions: ["banner", "timer"]
    readonly property var onMissingOptions: ["hide", "dim"]
    readonly property var sizeIcons: ({
            "1x1": "crop_square",
            "2x1": "crop_landscape",
            "2x2": "grid_on",
            "4x1": "view_agenda"
        })
    readonly property var sizeChipOptions: root.sizeOptions.map(s => ({
                "displayName": s,
                "icon": root.sizeIcons[s] ?? "",
                "value": s
            }))

    // Same templates as "Add a tile" below, filtered to one data type - the catalog is
    // already the human-readable name for every form a tile can take.
    function formOptionsFor(type) {
        return root.catalog.filter(c => c.tile.type === type).map(c => ({
                    "displayName": c.label,
                    "icon": c.icon,
                    "value": c.tile.form
                }));
    }

    // What actually exists for this device right now, plus the three composite sources -
    // rebinding a tile to one of these sets both its type and its field together.
    function sourceOptionsFor(deviceId) {
        const device = deviceId ? (root.ownerAccount?.devices ?? []).find(d => d.device_id === deviceId) : root.ownerAccount?.primary;
        const options = Statusphere.fieldsFor(device).map(f => ({
                    "displayName": f.label,
                    "icon": f.icon,
                    "value": `scalar:${f.key}`
                }));
        // A field the layout already names stays a chip even where the device isn't
        // reporting it this second - live data lags, and this is edited offline too.
        const known = new Set(options.map(o => o.value));
        for (const t of root.editTiles) {
            if (t.type !== "scalar" || !t.field || t.field === "*")
                continue;
            const value = `scalar:${t.field}`;
            if (known.has(value))
                continue;
            known.add(value);
            options.push({
                "displayName": Statusphere.labelForKey(t.field),
                "icon": Statusphere.iconForField(t.field),
                "value": value
            });
        }
        options.push({
            "displayName": Translation.tr("Music"),
            "icon": "music_note",
            "value": "music:"
        });
        options.push({
            "displayName": Translation.tr("Game"),
            "icon": "sports_esports",
            "value": "game:"
        });
        options.push({
            "displayName": Translation.tr("Photo"),
            "icon": "photo_camera",
            "value": "photo:"
        });
        return options;
    }

    function selectSource(sourceKey) {
        const sep = sourceKey.indexOf(":");
        const type = sourceKey.slice(0, sep);
        const field = sourceKey.slice(sep + 1);
        const forms = root.formOptionsFor(type);
        root.updateSelectedTile({
            "type": type,
            "field": field,
            "form": forms.length > 0 ? forms[0].value : ""
        });
    }

    function setSurfaceTiles(tiles) {
        if (root.editSurface === "row")
            root.editRow = tiles;
        else
            root.editDetail = tiles;
    }

    function selectSurface(surface) {
        root.editSurface = surface;
        root.selectedIndex = -1;
    }

    function applyPreset(name) {
        const preset = CardLayouts.get(name);
        if (!preset)
            return;
        root.editRow = preset.row;
        root.editDetail = preset.detail;
        root.selectedIndex = -1;
        root.selectedPresetName = name;
    }

    function addTile(blueprint) {
        root.setSurfaceTiles(root.editTiles.concat([blueprint]));
        root.selectedIndex = root.editTiles.length - 1; // editTiles already reflects the concat above
        root.selectedPresetName = "";
    }

    function updateSelectedTile(patch) {
        if (!root.selectedTile)
            return;
        const tiles = root.editTiles.slice();
        tiles[root.selectedIndex] = Object.assign({}, tiles[root.selectedIndex], patch);
        root.setSurfaceTiles(tiles);
        root.selectedPresetName = "";
    }

    function removeSelectedTile() {
        if (!root.selectedTile)
            return;
        const tiles = root.editTiles.slice();
        tiles.splice(root.selectedIndex, 1);
        root.setSurfaceTiles(tiles);
        root.selectedIndex = -1;
        root.selectedPresetName = "";
    }

    function removeTileAt(index) {
        const tiles = root.editTiles.slice();
        tiles.splice(index, 1);
        root.setSurfaceTiles(tiles);
        if (root.selectedIndex === index)
            root.selectedIndex = -1;
        else if (root.selectedIndex > index)
            root.selectedIndex -= 1;
        root.selectedPresetName = "";
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
        root.selectedPresetName = "";
    }

    function loadMyLayout() {
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
        root.savedSnapshot = JSON.stringify({
            "row": root.editRow,
            "detail": root.editDetail
        });
    }

    function saveMyLayout() {
        layoutFile.setText(JSON.stringify({
            "updated_at": Math.floor(Date.now() / 1000),
            "row": root.editRow,
            "detail": root.editDetail
        }, null, 2));
        root.savedSnapshot = JSON.stringify({
            "row": root.editRow,
            "detail": root.editDetail
        });
    }

    FileView {
        id: layoutFile
        path: `${Directories.config}/statusphere/layout.json`
        printErrors: false
        onLoaded: root.loadMyLayout()
        onLoadFailed: root.loadMyLayout()
    }

    ContentSubsection {
        title: Translation.tr("Incognito")

        ConfigSwitch {
            buttonIcon: "touch_app"
            text: Translation.tr('Hold your own row to hide')
            checked: Statusphere.opt("incognito")
            onCheckedChanged: setOption("incognito", checked)
            StyledToolTip {
                text: Translation.tr("Hold your avatar in the presence tab, slide onto how long, let go.\nHides what you have open; music keeps playing.\nWhat's hidden never leaves this machine, so it stays out of the server's history too")
            }
        }

        ConfigSwitch {
            buttonIcon: "toast"
            text: Translation.tr('Remind me in the bar')
            checked: Statusphere.opt("incognitoIndicator")
            onCheckedChanged: setOption("incognitoIndicator", checked)
            StyledToolTip {
                text: Translation.tr("An icon while you're hiding, so you don't stay dark for a week by accident.\nClick it to be visible again")
            }
        }
    }

    ContentSubsection {
        title: Translation.tr("Servers")

        ConfigSwitch {
            buttonIcon: "monitoring"
            text: Translation.tr('Metrics on the card')
            checked: Statusphere.opt("serverMetrics")
            onCheckedChanged: setOption("serverMetrics", checked)
            StyledToolTip {
                text: Translation.tr("A machine has no window title, so its card shows cpu, memory, disk and load instead.\nThe verdict next to the name comes from that machine's own ~/.config/statusphere/health.json")
            }
        }

        ConfigSpinBox {
            icon: "network_ping"
            text: Translation.tr("Reachability check (seconds)")
            value: Statusphere.opt("serverPingSeconds")
            from: 15
            to: 600
            stepSize: 15
            onValueChanged: {
                setOption("serverPingSeconds", value);
            }
            StyledToolTip {
                text: Translation.tr("The agent can't report its own death, so the server is asked directly this often.\nThat is what tells \"Host unreachable\" from \"Not reporting\"")
            }
        }
    }

    ContentSubsection {
        title: Translation.tr("Away")

        ConfigSwitch {
            buttonIcon: "bedtime"
            text: Translation.tr('Mark idle friends away')
            checked: Statusphere.opt("away")
            onCheckedChanged: setOption("away", checked)
            StyledToolTip {
                text: Translation.tr("A dimmer dot once a device has sat untouched past the minutes below.\nA game or a call still counts as present, so the status line keeps saying what it was saying")
            }
        }

        ConfigSpinBox {
            enabled: Statusphere.opt("away")
            icon: "hourglass_empty"
            text: Translation.tr("Idle minutes before away")
            value: Statusphere.opt("awayMinutes")
            from: 1
            to: 60
            stepSize: 1
            onValueChanged: {
                setOption("awayMinutes", value);
            }
        }
    }

    ContentSubsection {
        title: Translation.tr("Photos")

        ConfigSwitch {
            buttonIcon: "add_a_photo"
            text: Translation.tr('Share photos yourself')
            checked: Statusphere.opt("photoShare")
            onCheckedChanged: setOption("photoShare", checked)
            StyledToolTip {
                text: Translation.tr("Middle-click your own card for share actions.\nMiddle-drag in the region selector shares that region right away")
            }
        }
    }

    ContentSubsection {
        title: Translation.tr("Wallpaper card")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Statusphere.opt("wallpaperCard")
            onCheckedChanged: setOption("wallpaperCard", checked)
            StyledToolTip {
                text: Translation.tr("Same rows as the left sidebar's presence tab, as a card on the wallpaper.\nNeeds the statusphere cli and a registered account")
            }
        }

        ConfigSelectionArray { // Its own row, so Enable keeps the axis every other switch is on
            Layout.fillWidth: true
            currentValue: Statusphere.opt("wallpaperPlacement")
            onSelected: newValue => {
                setOption("wallpaperPlacement", newValue);
            }
            options: [
                {
                    displayName: Translation.tr("Draggable"),
                    icon: "drag_pan",
                    value: "free"
                },
                {
                    displayName: Translation.tr("Least busy"),
                    icon: "category",
                    value: "leastBusy"
                },
                {
                    displayName: Translation.tr("Most busy"),
                    icon: "shapes",
                    value: "mostBusy"
                },
            ]
        }

        ConfigSwitch {
            buttonIcon: "person_off"
            text: Translation.tr("Hide offline members")
            checked: Statusphere.opt("wallpaperHideOffline")
            onCheckedChanged: setOption("wallpaperHideOffline", checked)
        }

        ConfigSpinBox {
            icon: "fit_width"
            text: Translation.tr("Width")
            value: Statusphere.opt("wallpaperWidth")
            from: 200
            to: 800
            stepSize: 20
            onValueChanged: {
                setOption("wallpaperWidth", value);
            }
        }

        ConfigSpinBox {
            icon: "format_list_numbered"
            text: Translation.tr("Max rows (0 for everyone)")
            value: Statusphere.opt("wallpaperMaxRows")
            from: 0
            to: 20
            stepSize: 1
            onValueChanged: {
                setOption("wallpaperMaxRows", value);
            }
        }
    }

    component ColorSwatches: Row {
        id: swatchesRoot
        spacing: 4
        required property var options
        property string current: ""
        signal picked(string role)

        function roleColor(role: string): color {
            switch (role) {
            case "primary":
                return Appearance.colors.colPrimary;
            case "secondary":
                return Appearance.colors.colSecondary;
            case "tertiary":
                return Appearance.colors.colTertiary;
            case "primaryContainer":
                return Appearance.colors.colPrimaryContainer;
            case "secondaryContainer":
                return Appearance.colors.colSecondaryContainer;
            case "tertiaryContainer":
                return Appearance.colors.colTertiaryContainer;
            default:
                return Appearance.colors.colLayer2;
            }
        }

        Repeater {
            model: swatchesRoot.options
            delegate: Rectangle {
                id: swatch
                required property string modelData
                width: 20
                height: 20
                radius: height / 2
                color: swatchesRoot.roleColor(swatch.modelData)
                border.width: swatchesRoot.current === swatch.modelData ? 3 : 1
                border.color: swatchesRoot.current === swatch.modelData ? Appearance.colors.colOnLayer1 : Appearance.colors.colOutlineVariant

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: swatchesRoot.picked(swatch.modelData)
                }

                StyledToolTip {
                    text: swatch.modelData
                }
            }
        }
    }

    // Silhouette names mirror CardTile.qml's silhouetteShape() - a name added there needs
    // the same case added here to get a preview instead of falling back to a circle.
    component ShapeGrid: Flow {
        id: shapeGrid
        spacing: 4
        required property var options
        property string current: ""
        signal picked(string name)

        function shapeEnum(name: string): int {
            switch (name) {
            case "Pill":
                return MaterialShape.Shape.Pill;
            case "Arch":
                return MaterialShape.Shape.Arch;
            case "SemiCircle":
                return MaterialShape.Shape.SemiCircle;
            case "Diamond":
                return MaterialShape.Shape.Diamond;
            case "Pentagon":
                return MaterialShape.Shape.Pentagon;
            case "Cookie4Sided":
                return MaterialShape.Shape.Cookie4Sided;
            case "Cookie6Sided":
                return MaterialShape.Shape.Cookie6Sided;
            case "Cookie9Sided":
                return MaterialShape.Shape.Cookie9Sided;
            case "Clover4Leaf":
                return MaterialShape.Shape.Clover4Leaf;
            case "Heart":
                return MaterialShape.Shape.Heart;
            case "Sunny":
                return MaterialShape.Shape.Sunny;
            case "SoftBurst":
                return MaterialShape.Shape.SoftBurst;
            default:
                return MaterialShape.Shape.Circle;
            }
        }

        Repeater {
            model: shapeGrid.options
            delegate: Rectangle {
                id: shapeSwatch
                required property string modelData
                width: 30
                height: 30
                radius: Appearance.rounding.small
                color: shapeGrid.current === shapeSwatch.modelData ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2
                border.width: shapeGrid.current === shapeSwatch.modelData ? 2 : 0
                border.color: Appearance.colors.colPrimary

                MaterialSymbol {
                    visible: shapeSwatch.modelData === "auto"
                    anchors.centerIn: parent
                    text: "auto_awesome"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                }

                Rectangle {
                    visible: shapeSwatch.modelData === "default"
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    radius: Appearance.rounding.small
                    color: "transparent"
                    border.width: 2
                    border.color: Appearance.colors.colOnLayer2
                }

                MaterialShape {
                    visible: shapeSwatch.modelData !== "default" && shapeSwatch.modelData !== "auto"
                    anchors.centerIn: parent
                    implicitSize: 15
                    shape: shapeGrid.shapeEnum(shapeSwatch.modelData)
                    color: Appearance.colors.colOnLayer2
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: shapeGrid.picked(shapeSwatch.modelData)
                }

                StyledToolTip {
                    text: shapeSwatch.modelData
                }
            }
        }
    }

    ContentSubsection {
        title: Translation.tr("My card")
        tooltip: Translation.tr("Pick a pack to start from, then add, remove, move or resize tiles.\nSaves to ~/.config/statusphere/layout.json")

        ContentSubsectionLabel {
            text: Translation.tr("Presets")
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: CardLayouts.names()

                delegate: ColumnLayout {
                    id: presetDelegate
                    required property string modelData
                    readonly property bool isSelected: root.selectedPresetName === presetDelegate.modelData
                    spacing: 4

                    Rectangle {
                        implicitWidth: 112
                        implicitHeight: 58
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2
                        border.width: presetDelegate.isSelected ? 2 : 1
                        border.color: presetDelegate.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                        clip: true

                        CardGrid {
                            anchors.fill: parent
                            anchors.margins: 4
                            account: root.demoAccount
                            maxRows: 2
                            thumbnail: true
                            tiles: root.previewSafe(CardLayouts.get(presetDelegate.modelData)?.row ?? [])
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyPreset(presetDelegate.modelData)
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: CardLayouts.get(presetDelegate.modelData)?.name ?? presetDelegate.modelData
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: presetDelegate.isSelected ? Font.Medium : Font.Normal
                        color: presetDelegate.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }
                }
            }
        }

        ContentSubsectionLabel {
            text: Translation.tr("Live preview")
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
            implicitHeight: Math.max(80, preview.implicitHeight + 16)
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            StyledText {
                visible: root.editTiles.length === 0
                anchors.centerIn: parent
                text: Translation.tr("No tiles yet - pick a preset above or add one from the catalog below")
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
                account: root.ownerAccount
                maxRows: root.editSurface === "row" ? 2 : 4
                tiles: root.previewTiles
                selectable: true
                reorderable: true
                selectedIndex: root.selectedIndex
                onTileClicked: index => root.selectedIndex = index
                onTileMoved: (fromIndex, toIndex) => root.reorderTile(fromIndex, toIndex)
                onTileRemoveRequested: index => root.removeTileAt(index)
            }
        }

        StyledComboBox {
            id: addTileBox
            Layout.fillWidth: true
            buttonIcon: "add"
            displayText: Translation.tr("Add a tile")
            textRole: "displayName"
            currentIndex: -1
            model: root.catalog.map(c => ({
                        "displayName": c.label,
                        "icon": c.icon
                    }))
            onActivated: index => {
                root.addTile(Object.assign({}, root.catalog[index].tile));
                addTileBox.currentIndex = -1;
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.selectedTile !== null
            spacing: 6

            ContentSubsectionLabel {
                text: Translation.tr("Selected tile - source")
            }

            ConfigSelectionArray {
                Layout.fillWidth: true
                currentValue: `${root.selectedTile?.type ?? ""}:${root.selectedTile?.type === "scalar" ? (root.selectedTile?.field ?? "") : ""}`
                onSelected: newValue => root.selectSource(newValue)
                options: root.sourceOptionsFor(root.selectedTile?.device ?? null)
            }

            ConfigRow {
                Layout.fillWidth: true

                StyledComboBox {
                    id: deviceBox
                    Layout.preferredWidth: 200
                    textRole: "displayName"
                    model: [{
                            "displayName": Translation.tr("Primary device"),
                            "value": null
                        }, ...(root.ownerAccount?.devices ?? []).map(d => ({
                                "displayName": Statusphere.deviceNameFor(d),
                                "value": d.device_id
                            }))]
                    onActivated: index => root.updateSelectedTile({
                        "device": deviceBox.model[index].value
                    })

                    Binding {
                        target: deviceBox
                        property: "currentIndex"
                        value: Math.max(0, deviceBox.model.findIndex(m => m.value === (root.selectedTile?.device ?? null)))
                    }
                }
            }

            ConfigRow {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.selectedTile?.type !== "photo"
                    spacing: 4

                    ContentSubsectionLabel {
                        text: Translation.tr("Form")
                    }

                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: root.selectedTile?.form ?? ""
                        onSelected: newValue => root.updateSelectedTile({
                            "form": newValue
                        })
                        options: root.formOptionsFor(root.selectedTile?.type ?? "scalar")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    ContentSubsectionLabel {
                        text: Translation.tr("Size")
                    }

                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: root.selectedTile?.size ?? ""
                        onSelected: newValue => root.updateSelectedTile({
                            "size": newValue
                        })
                        options: root.sizeChipOptions
                    }
                }
            }

            ContentSubsectionLabel {
                text: Translation.tr("Silhouette")
            }

            ShapeGrid {
                Layout.fillWidth: true
                options: root.shapeOptions
                current: root.selectedTile?.shape ?? ""
                onPicked: name => root.updateSelectedTile({
                    "shape": name
                })
            }

            ContentSubsectionLabel {
                text: Translation.tr("Colour")
            }

            ColorSwatches {
                options: root.colorOptions
                current: root.selectedTile?.color ?? ""
                onPicked: role => root.updateSelectedTile({
                    "color": role
                })
            }

            ContentSubsectionLabel {
                text: Translation.tr("Background")
            }

            ConfigSelectionArray {
                Layout.fillWidth: true
                currentValue: root.selectedTile?.background?.kind ?? "color"
                onSelected: newValue => root.updateSelectedTile({
                    "background": {
                        "kind": newValue,
                        "value": newValue === "live" ? (root.selectedTile?.type === "scalar" ? "" : root.selectedTile?.type) : ""
                    }
                })
                options: [
                    {
                        "displayName": Translation.tr("Colour"),
                        "icon": "palette",
                        "value": "color"
                    },
                    {
                        "displayName": Translation.tr("Live"),
                        "icon": "bolt",
                        "value": "live"
                    },
                    {
                        "displayName": Translation.tr("Image URL"),
                        "icon": "link",
                        "value": "url"
                    }
                ]
            }

            ColorSwatches {
                visible: (root.selectedTile?.background?.kind ?? "color") === "color"
                options: root.colorOptions
                current: root.selectedTile?.background?.value ?? ""
                onPicked: role => root.updateSelectedTile({
                    "background": {
                        "kind": "color",
                        "value": role
                    }
                })
            }

            MaterialTextField {
                id: backgroundUrlField
                Layout.fillWidth: true
                visible: (root.selectedTile?.background?.kind ?? "color") === "url"
                placeholderText: Translation.tr("Image URL")
                onEditingFinished: root.updateSelectedTile({
                    "background": {
                        "kind": "url",
                        "value": backgroundUrlField.text
                    }
                })

                Binding {
                    target: backgroundUrlField
                    property: "text"
                    value: root.selectedTile?.background?.kind === "url" ? (root.selectedTile?.background?.value ?? "") : ""
                }
            }

            ConfigSwitch {
                id: keepPlaceSwitch
                buttonIcon: "visibility"
                text: Translation.tr("Keep place when empty")
                onCheckedChanged: root.updateSelectedTile({
                    "onMissing": keepPlaceSwitch.checked ? "dim" : "hide"
                })

                Binding {
                    target: keepPlaceSwitch
                    property: "checked"
                    value: root.selectedTile?.onMissing === "dim"
                }
            }
        }

        RowLayout {
            Layout.topMargin: 8
            spacing: 8

            RippleButtonWithIcon {
                materialIcon: "save"
                mainText: Translation.tr("Save my card")
                onClicked: root.saveMyLayout()
            }

            StyledText {
                visible: root.dirty
                text: Translation.tr("Unsaved changes")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
        }
    }
}
