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
            "label": Translation.tr("Graph"),
            "icon": "show_chart",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "graph",
                    "size": "2x1"
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
            "label": Translation.tr("Heatmap"),
            "icon": "grid_on",
            "tile": CardLayouts.tile({
                    "type": "scalar",
                    "form": "heatmap",
                    "size": "2x1"
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
    readonly property var colorOptions: ["primary", "secondary", "tertiary", "error", "primaryContainer", "secondaryContainer", "tertiaryContainer", "errorContainer"]
    readonly property var shapeOptions: ["default", "auto", "Circle", "Pill", "Arch", "SemiCircle", "Diamond", "Pentagon", "Cookie4Sided", "Cookie6Sided", "Cookie9Sided", "Clover4Leaf", "Heart", "Sunny", "SoftBurst"]
    readonly property var scalarFormOptions: ["ring", "bar", "number", "graph", "text", "big", "clock", "weather", "heatmap"]
    readonly property var musicFormOptions: ["cover", "vinyl", "wave"]
    readonly property var gameFormOptions: ["banner", "timer"]
    readonly property var onMissingOptions: ["hide", "dim"]

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
    }

    function addTile(blueprint) {
        root.setSurfaceTiles(root.editTiles.concat([blueprint]));
        root.selectedIndex = root.editTiles.length - 1; // editTiles already reflects the concat above
    }

    function updateSelectedTile(patch) {
        if (!root.selectedTile)
            return;
        const tiles = root.editTiles.slice();
        tiles[root.selectedIndex] = Object.assign({}, tiles[root.selectedIndex], patch);
        root.setSurfaceTiles(tiles);
    }

    function removeSelectedTile() {
        if (!root.selectedTile)
            return;
        const tiles = root.editTiles.slice();
        tiles.splice(root.selectedIndex, 1);
        root.setSurfaceTiles(tiles);
        root.selectedIndex = -1;
    }

    function moveSelectedTile(delta) {
        if (!root.selectedTile)
            return;
        const tiles = root.editTiles.slice();
        const to = root.selectedIndex + delta;
        if (to < 0 || to >= tiles.length)
            return;
        const tmp = tiles[to];
        tiles[to] = tiles[root.selectedIndex];
        tiles[root.selectedIndex] = tmp;
        root.setSurfaceTiles(tiles);
        root.selectedIndex = to;
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
    }

    function saveMyLayout() {
        layoutFile.setText(JSON.stringify({
            "updated_at": Math.floor(Date.now() / 1000),
            "row": root.editRow,
            "detail": root.editDetail
        }, null, 2));
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
                    spacing: 4

                    Rectangle {
                        implicitWidth: 150
                        implicitHeight: 76
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant
                        clip: true

                        CardGrid {
                            anchors.fill: parent
                            anchors.margins: 6
                            account: root.ownerAccount
                            maxRows: 2
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
                        color: Appearance.colors.colSubtext
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
                selectedIndex: root.selectedIndex
                onTileClicked: index => root.selectedIndex = index
            }
        }

        ContentSubsectionLabel {
            text: Translation.tr("Add a tile")
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.catalog

                delegate: RippleButtonWithIcon {
                    required property var modelData
                    materialIcon: modelData.icon
                    mainText: modelData.label
                    onClicked: root.addTile(Object.assign({}, modelData.tile))
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: root.selectedTile !== null
            spacing: 6

            ContentSubsectionLabel {
                text: Translation.tr("Selected tile")
            }

            ConfigRow {
                Layout.fillWidth: true

                MaterialTextField {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Field, e.g. cpu, weather, a custom.json key")
                    text: root.selectedTile?.field ?? ""
                    enabled: root.selectedTile?.type === "scalar"
                    onEditingFinished: root.updateSelectedTile({
                        "field": text
                    })
                }

                StyledComboBox {
                    id: deviceBox
                    Layout.preferredWidth: 160
                    textRole: "displayName"
                    model: [{
                            "displayName": Translation.tr("Primary device"),
                            "value": null
                        }, ...(root.ownerAccount?.devices ?? []).map(d => ({
                                "displayName": Statusphere.deviceNameFor(d),
                                "value": d.device_id
                            }))]
                    currentIndex: {
                        const i = deviceBox.model.findIndex(m => m.value === (root.selectedTile?.device ?? null));
                        return i !== -1 ? i : 0;
                    }
                    onActivated: index => root.updateSelectedTile({
                        "device": deviceBox.model[index].value
                    })
                }
            }

            ConfigRow {
                Layout.fillWidth: true

                StyledComboBox {
                    id: formBox
                    Layout.preferredWidth: 130
                    property var options: {
                        if (root.selectedTile?.type === "music")
                            return root.musicFormOptions;
                        if (root.selectedTile?.type === "game")
                            return root.gameFormOptions;
                        return root.scalarFormOptions;
                    }
                    model: formBox.options
                    currentIndex: Math.max(0, formBox.options.indexOf(root.selectedTile?.form))
                    onActivated: index => root.updateSelectedTile({
                        "form": formBox.options[index]
                    })
                }

                StyledComboBox {
                    id: sizeBox
                    Layout.preferredWidth: 90
                    model: root.sizeOptions
                    currentIndex: Math.max(0, root.sizeOptions.indexOf(root.selectedTile?.size))
                    onActivated: index => root.updateSelectedTile({
                        "size": root.sizeOptions[index]
                    })
                }

                StyledComboBox {
                    id: shapeBox
                    Layout.preferredWidth: 130
                    model: root.shapeOptions
                    currentIndex: Math.max(0, root.shapeOptions.indexOf(root.selectedTile?.shape))
                    onActivated: index => root.updateSelectedTile({
                        "shape": root.shapeOptions[index]
                    })
                }
            }

            ConfigRow {
                Layout.fillWidth: true

                StyledComboBox {
                    id: colorBox
                    Layout.preferredWidth: 160
                    model: root.colorOptions
                    currentIndex: Math.max(0, root.colorOptions.indexOf(root.selectedTile?.color))
                    onActivated: index => root.updateSelectedTile({
                        "color": root.colorOptions[index]
                    })
                }

                StyledComboBox {
                    id: onMissingBox
                    Layout.preferredWidth: 100
                    model: root.onMissingOptions
                    currentIndex: Math.max(0, root.onMissingOptions.indexOf(root.selectedTile?.onMissing))
                    onActivated: index => root.updateSelectedTile({
                        "onMissing": root.onMissingOptions[index]
                    })
                }
            }

            ConfigRow {
                Layout.fillWidth: true

                StyledComboBox {
                    id: backgroundKindBox
                    Layout.preferredWidth: 100
                    model: ["color", "live", "url"]
                    currentIndex: Math.max(0, ["color", "live", "url"].indexOf(root.selectedTile?.background?.kind))
                    onActivated: index => root.updateSelectedTile({
                        "background": {
                            "kind": ["color", "live", "url"][index],
                            "value": root.selectedTile?.background?.value ?? ""
                        }
                    })
                }

                MaterialTextField {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Background value: a colour role, music/game/photo, or a URL")
                    text: root.selectedTile?.background?.value ?? ""
                    onEditingFinished: root.updateSelectedTile({
                        "background": {
                            "kind": root.selectedTile?.background?.kind ?? "color",
                            "value": text
                        }
                    })
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                RippleButtonWithIcon {
                    materialIcon: "arrow_upward"
                    mainText: Translation.tr("Move up")
                    onClicked: root.moveSelectedTile(-1)
                }
                RippleButtonWithIcon {
                    materialIcon: "arrow_downward"
                    mainText: Translation.tr("Move down")
                    onClicked: root.moveSelectedTile(1)
                }
                RippleButtonWithIcon {
                    materialIcon: "delete"
                    mainText: Translation.tr("Remove")
                    onClicked: root.removeSelectedTile()
                }
                Item {
                    Layout.fillWidth: true
                }
            }
        }

        RippleButtonWithIcon {
            Layout.topMargin: 8
            materialIcon: "save"
            mainText: Translation.tr("Save my card")
            onClicked: root.saveMyLayout()
        }
    }
}
