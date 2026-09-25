pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell.Io
import "DemoCovers.js" as DemoCovers

/** Fills the cover-art cache from demo/covers/, so PresenceArt finds every covers.invalid url cached and never runs curl. */
Item {
    id: root
    // url file name -> the cover that lands in its cache slot, as after a fallback download
    property var extraSeeds: ({})
    signal seeded

    Process {
        id: seeder
        readonly property string script: `
covers="$1"; dest="$2"; prefix="$3"; shift 3
mkdir -p "$dest"
for f in "$covers"/*; do
    name="$(basename "$f")"
    [ "$name" = "NOTICE" ] && continue
    hash="$(printf '%s' "$prefix$name" | md5sum | cut -d' ' -f1)"
    cp -n "$f" "$dest/$hash"
done
while [ "$#" -ge 2 ]; do
    hash="$(printf '%s' "$prefix$1" | md5sum | cut -d' ' -f1)"
    cp -f "$covers/$2" "$dest/$hash"
    shift 2
done
`
        command: ["bash", "-c", seeder.script, "_", FileUtils.trimFileProtocol(Qt.resolvedUrl("../covers")), Directories.coverArt, DemoCovers.urlPrefix, ...[].concat(...Object.entries(root.extraSeeds))]
        running: true
        onRunningChanged: if (!seeder.running)
            root.seeded()
    }
}
