import QtQuick

// The silhouette already reads the condition (CardLayouts.weatherShape), so the caption
// keeps only the city: the full "condition · city" string elides at 1x1 otherwise.
TileNumber {
    id: form
    readonly property var temperature: form.card.valueText.match(/-?\d+°/)
    readonly property string rest: form.card.valueText.replace(form.temperature ? form.temperature[0] : "", "").replace(/^[\s·,-]+|[\s·,-]+$/g, "")

    value: form.temperature ? form.temperature[0] : form.card.valueText
    caption: form.rest.includes("·") ? form.rest.split("·").pop().trim() : form.rest
}
