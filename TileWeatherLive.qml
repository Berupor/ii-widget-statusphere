import QtQuick
import "CardLayouts.js" as CardLayouts

// The silhouette already reads the condition (CardLayouts.weatherLiveShape), so the
// caption keeps only the city.
TileNumber {
    id: form
    readonly property var fields: CardLayouts.weatherFieldsOf(form.card.valueText)

    value: form.fields ? `${form.fields.temp}°` : form.card.valueText
    caption: form.fields?.city ?? ""
}
