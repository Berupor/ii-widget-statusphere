import qs.modules.common
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

// The silhouette already reads the condition (CardLayouts.weatherLiveShape), so the
// caption keeps only the city.
TileNumber {
    id: form
    readonly property var fields: CardLayouts.weatherFieldsOf(form.card.valueText)

    // Keep this fraction matching WeatherSky's sceneStart: they split the same tile,
    // text on the left, sky scene on the right.
    readonly property real textFraction: 0.45
    readonly property bool wide: CardLayouts.spanOf(form.card.tile.size).cols > CardLayouts.spanOf(form.card.tile.size).rows
    readonly property string cityText: form.fields?.city ?? ""
    readonly property string tempText: form.fields ? `${form.fields.temp}°` : form.card.valueText
    readonly property string shownTempText: form.card.hasData ? form.tempText : "-"

    // The form fills the whole tile no matter what width is set here - CardTile's
    // Loader re-asserts its own size once loaded - so TileNumber's inherited,
    // full-width centered text can't be narrowed from here. Blank it out when wide
    // and draw the left column ourselves instead.
    value: form.wide ? "" : form.tempText
    caption: form.wide ? "" : form.cityText

    Loader {
        active: form.wide
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * form.textFraction

        sourceComponent: ColumnLayout {
            spacing: 2

            ShrinkThenWrapText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                largestSize: Math.max(Appearance.font.pixelSize.smallest, Math.round(form.height * 0.15))
                wrapBelow: Appearance.font.pixelSize.smallest
                text: form.cityText
                color: form.card.mutedContentColor
            }
            ShrinkThenWrapText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.4))
                maxLines: 1
                animateChange: true
                text: form.shownTempText
                color: form.card.contentColor
            }
        }
    }
}
