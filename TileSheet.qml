pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    required property var editor

    readonly property var tile: root.editor.selectedTile
    readonly property bool ownField: root.tile?.type === "scalar" && Statusphere.isCustomFieldKey(root.tile?.field ?? "")
    readonly property string fieldKey: root.ownField ? root.tile.field : ""
    readonly property string kindId: root.ownField ? root.editor.shownKindFor(root.fieldKey) : ""
    readonly property var kind: root.editor.ownerKind(root.kindId)
    readonly property bool runsCommand: root.editor.isCommandKind(root.kindId)
    readonly property string committedAnswer: root.ownField ? root.editor.answerFor(root.fieldKey, root.kindId) : ""
    readonly property int repeatSeconds: root.ownField ? root.editor.repeatFor(root.fieldKey, root.kindId) : 0
    readonly property bool hasEntry: root.ownField && root.editor.customEntries[root.fieldKey] !== undefined
    property bool moreOpen: false

    readonly property int testTimeoutMs: 10000
    property string testOutput: ""
    property bool testFailed: false
    property string testedKey: ""

    readonly property var colorOptions: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer"]
    readonly property var shapeOptions: ["default", "auto", "Circle", "Pill", "Arch", "SemiCircle", "Diamond", "Pentagon", "Cookie4Sided", "Cookie6Sided", "Cookie9Sided", "Clover4Leaf", "Heart", "Sunny", "SoftBurst"]
    readonly property var sizeOptions: [
        {
            "displayName": "1x1",
            "icon": "crop_square",
            "value": "1x1"
        },
        {
            "displayName": "2x1",
            "icon": "crop_landscape",
            "value": "2x1"
        },
        {
            "displayName": "2x2",
            "icon": "grid_on",
            "value": "2x2"
        },
        {
            "displayName": "4x1",
            "icon": "view_agenda",
            "value": "4x1"
        }
    ]
    readonly property var repeatOptions: [
        {
            "displayName": Translation.tr("30s"),
            "value": 30
        },
        {
            "displayName": Translation.tr("1m"),
            "value": 60
        },
        {
            "displayName": Translation.tr("5m"),
            "value": 300
        },
        {
            "displayName": Translation.tr("15m"),
            "value": 900
        },
        {
            "displayName": Translation.tr("1h"),
            "value": 3600
        }
    ]

    function commitAnswer() {
        root.editor.setAnswer(root.fieldKey, root.kindId, answerField.text);
    }

    function commitRepeat(seconds) {
        root.commitAnswer();
        root.editor.setRepeat(root.fieldKey, seconds);
    }

    function runTest() {
        const cmd = root.editor.commandFor(root.kindId, answerField.text);
        root.commitAnswer();
        root.testOutput = "";
        root.testFailed = false;
        if (!cmd) {
            root.testFailed = true;
            root.testOutput = Translation.tr("Nothing to run yet");
            return;
        }
        root.testedKey = root.fieldKey;
        testRun.exitCode = -1;
        testRun.command = ["sh", "-c", cmd];
        testRun.running = true;
        testTimeout.restart();
    }

    function finishTest() {
        if (testRun.exitCode < 0 || !testStdout.done || !testStderr.done)
            return;
        testTimeout.stop();
        const out = testStdout.text.trim();
        const err = testStderr.text.trim();
        const failed = testRun.exitCode !== 0 || out === "";
        if (!failed)
            root.editor.setTestedValue(root.testedKey, out);
        if (root.testedKey !== root.fieldKey)
            return;
        root.testFailed = failed;
        root.testOutput = failed ? (err || out || Translation.tr("No output, exit code %1").arg(testRun.exitCode)) : out;
    }

    onFieldKeyChanged: {
        root.testOutput = "";
        root.testFailed = false;
    }

    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.normal
    implicitHeight: body.implicitHeight + 24

    Process {
        id: testRun
        property int exitCode: -1
        stdout: StdioCollector {
            id: testStdout
            property bool done: false
            onStreamFinished: {
                testStdout.done = true;
                root.finishTest();
            }
        }
        stderr: StdioCollector {
            id: testStderr
            property bool done: false
            onStreamFinished: {
                testStderr.done = true;
                root.finishTest();
            }
        }
        onStarted: {
            testStdout.done = false;
            testStderr.done = false;
        }
        onExited: code => {
            testRun.exitCode = code;
            root.finishTest();
        }
    }

    Timer {
        id: testTimeout
        interval: root.testTimeoutMs
        onTriggered: {
            testRun.running = false;
            root.testFailed = true;
            root.testOutput = Translation.tr("Still running after %1 s, stopped").arg(root.testTimeoutMs / 1000);
        }
    }

    ColumnLayout {
        id: body
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: root.editor.tileTitle(root.tile)
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }

            RippleButtonWithIcon {
                materialIcon: "delete"
                mainText: Translation.tr("Remove")
                onClicked: root.editor.removeTileAt(root.editor.selectedIndex)
            }

            RippleButtonWithIcon {
                materialIcon: "check"
                mainText: Translation.tr("Done")
                onClicked: root.editor.selectedIndex = -1
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.ownField
            spacing: 6

            MaterialTextField {
                id: labelField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Label")
                onEditingFinished: root.editor.renameField(root.fieldKey, labelField.text)

                Binding {
                    target: labelField
                    property: "text"
                    value: Statusphere.labelForKey(root.fieldKey)
                }
            }

            ConfigSelectionArray {
                Layout.fillWidth: true
                currentValue: root.kindId
                options: root.ownField ? root.editor.kindChoicesFor(root.fieldKey) : []
                onSelected: newValue => root.editor.chooseKind(root.fieldKey, newValue)
            }

            MaterialTextField {
                id: answerField
                Layout.fillWidth: true
                visible: (root.kind?.ask ?? "") !== ""
                placeholderText: root.kind?.hint ?? ""
                onEditingFinished: root.commitAnswer()

                Binding {
                    target: answerField
                    property: "text"
                    value: root.committedAnswer
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.runsCommand
                spacing: 8

                StyledText {
                    text: Translation.tr("Refresh every")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }

                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: root.repeatSeconds
                    options: root.repeatOptions
                    onSelected: newValue => root.commitRepeat(newValue)
                }

                MaterialTextField {
                    id: repeatField
                    Layout.preferredWidth: 72
                    placeholderText: Translation.tr("sec")
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator {
                        bottom: 1
                    }
                    onEditingFinished: root.commitRepeat(parseInt(repeatField.text, 10))

                    Binding {
                        target: repeatField
                        property: "text"
                        value: String(root.repeatSeconds)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.runsCommand
                spacing: 8

                RippleButtonWithIcon {
                    materialIcon: testRun.running ? "hourglass_top" : "play_arrow"
                    mainText: Translation.tr("Test")
                    enabled: !testRun.running
                    onClicked: root.runTest()
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.testOutput
                    color: root.testFailed ? Appearance.colors.colError : Appearance.colors.colOnLayer1
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 4
                    elide: Text.ElideRight
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.kind?.needsAnswer === true && !root.hasEntry
                text: Translation.tr("Friends see this tile once it has a %1").arg((root.kind?.ask ?? "").toLowerCase())
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }
        }

        ContentSubsectionLabel {
            visible: root.tile?.type !== "photo"
            text: Translation.tr("Kind")
        }

        ConfigSelectionArray {
            Layout.fillWidth: true
            visible: root.tile?.type !== "photo"
            currentValue: root.tile?.form ?? ""
            options: root.editor.formOptionsFor(root.tile?.type ?? "")
            onSelected: newValue => root.editor.updateSelectedTile({
                "form": newValue
            })
        }

        ContentSubsectionLabel {
            text: Translation.tr("Size")
        }

        ConfigSelectionArray {
            Layout.fillWidth: true
            currentValue: root.tile?.size ?? ""
            options: root.sizeOptions
            onSelected: newValue => root.editor.updateSelectedTile({
                "size": newValue
            })
        }

        ContentSubsectionLabel {
            text: Translation.tr("Colour")
        }

        ColorSwatches {
            options: root.colorOptions
            current: root.tile?.color ?? ""
            onPicked: role => root.editor.updateSelectedTile({
                "color": role
            })
        }

        RippleButtonWithIcon {
            materialIcon: root.moreOpen ? "expand_less" : "expand_more"
            mainText: Translation.tr("More")
            onClicked: root.moreOpen = !root.moreOpen
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.moreOpen
            spacing: 6

            ContentSubsectionLabel {
                text: Translation.tr("Silhouette")
            }

            ShapeGrid {
                Layout.fillWidth: true
                options: root.shapeOptions
                current: root.tile?.shape ?? ""
                onPicked: name => root.editor.updateSelectedTile({
                    "shape": name
                })
            }

            ContentSubsectionLabel {
                text: Translation.tr("Background")
            }

            ConfigSelectionArray {
                Layout.fillWidth: true
                currentValue: root.tile?.background?.kind ?? "color"
                onSelected: newValue => root.editor.updateSelectedTile({
                    "background": {
                        "kind": newValue,
                        "value": newValue === "live" ? (root.tile?.type === "scalar" ? "" : root.tile?.type) : ""
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
                visible: (root.tile?.background?.kind ?? "color") === "color"
                options: root.colorOptions
                current: root.tile?.background?.value ?? ""
                onPicked: role => root.editor.updateSelectedTile({
                    "background": {
                        "kind": "color",
                        "value": role
                    }
                })
            }

            MaterialTextField {
                id: backgroundUrlField
                Layout.fillWidth: true
                visible: (root.tile?.background?.kind ?? "color") === "url"
                placeholderText: Translation.tr("Image URL")
                onEditingFinished: root.editor.updateSelectedTile({
                    "background": {
                        "kind": "url",
                        "value": backgroundUrlField.text
                    }
                })

                Binding {
                    target: backgroundUrlField
                    property: "text"
                    value: root.tile?.background?.kind === "url" ? (root.tile?.background?.value ?? "") : ""
                }
            }

            ConfigSwitch {
                id: keepPlaceSwitch
                buttonIcon: "visibility"
                text: Translation.tr("Keep place when empty")
                onCheckedChanged: if (root.tile && (root.tile.onMissing === "dim") !== keepPlaceSwitch.checked)
                    root.editor.updateSelectedTile({
                        "onMissing": keepPlaceSwitch.checked ? "dim" : "hide"
                    })

                Binding {
                    target: keepPlaceSwitch
                    property: "checked"
                    value: root.tile?.onMissing === "dim"
                }
            }

            StyledComboBox {
                id: deviceBox
                Layout.fillWidth: true
                visible: (root.editor.ownerAccount?.devices ?? []).length > 1
                textRole: "displayName"
                model: [{
                        "displayName": Translation.tr("Primary device"),
                        "icon": "star",
                        "value": null
                    }, ...(root.editor.ownerAccount?.devices ?? []).map(d => ({
                            "displayName": Statusphere.deviceNameFor(d),
                            "icon": "computer",
                            "value": d.device_id
                        }))]
                onActivated: index => root.editor.updateSelectedTile({
                    "device": deviceBox.model[index].value
                })

                Binding {
                    target: deviceBox
                    property: "currentIndex"
                    value: Math.max(0, deviceBox.model.findIndex(m => m.value === (root.tile?.device ?? null)))
                }
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
                    id: swatchArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: swatchesRoot.picked(swatch.modelData)
                }

                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: swatchArea.containsMouse
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
                    id: shapeSwatchArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: shapeGrid.picked(shapeSwatch.modelData)
                }

                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: shapeSwatchArea.containsMouse
                    text: shapeSwatch.modelData
                }
            }
        }
    }
}
