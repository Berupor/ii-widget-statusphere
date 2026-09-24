//@ probe statusphere -g 420x260 -s 3000
/**
 * A server's forced detail card (serverMetrics), right-click collapsed, then
 * read back the way a fresh process would: through the persisted widget
 * option on disk, not an in-memory singleton property that a shell reload
 * would drop. Each step polls for the write it triggered to land on disk
 * instead of assuming a fixed delay, since FileView.setText is not synchronous.
 */
import ".."
import qs.modules.common
import qs.modules.widgets
import Quickshell.Io
import QtQuick

Item {
    id: root
    readonly property int now: 1780000000
    readonly property string serverId: "acc-collapse-server"

    readonly property var room: ({
            "members": [
                {
                    "account_id": root.serverId,
                    "device_id": "dev-collapse-server",
                    "device_name": "vps",
                    "account_name": "Collapse Server",
                    "_kind": "server",
                    "last_seen": root.now,
                    "cpu_percent": 10
                }
            ],
            "photos": []
        })

    Component.onCompleted: Statusphere.ingest(JSON.stringify(root.room))

    property int step: 0
    property bool beforeCollapsed
    property bool beforeVisible
    property var afterCollapseStoredIds: []
    property bool afterCollapseVisible
    property bool wipedCollapsed
    property bool reloadedCollapsed
    property bool reloadedVisible
    property var afterExpandStoredIds: []
    property bool afterExpandVisible

    function storedCollapsedIds() {
        storeView.reload();
        try {
            return JSON.parse(storeView.text())?.options?.statusphere?.collapsedDetailIds ?? [];
        } catch (e) {
            return [];
        }
    }

    function rowVisible() {
        return serverRow.serverDetailsForced && !serverRow.serverDetailsCollapsed;
    }

    PresenceRow {
        id: serverRow
        width: root.width
        modelData: root.serverId
    }

    FileView {
        id: storeView
        path: `${Directories.shellConfig}/widgets.json`
        printErrors: false
        blockLoading: true
    }

    // A small state machine, not fixed delays: each step waits for the write
    // it triggered to actually reach the file before moving on.
    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: root.advance()
    }

    function advance() {
        switch (root.step) {
        case 0:
            if (!Statusphere.accountsById[root.serverId])
                return;
            root.beforeCollapsed = Statusphere.detailsCollapsedFor(root.serverId);
            root.beforeVisible = root.rowVisible();
            Statusphere.toggleDetailsCollapsed(root.serverId);
            root.step = 1;
            break;
        case 1:
            if (!root.storedCollapsedIds().includes(root.serverId))
                return;
            root.afterCollapseStoredIds = root.storedCollapsedIds();
            root.afterCollapseVisible = root.rowVisible();

            // A freshly booted WidgetsStore starts blank until its own FileView
            // loads - wipe it the same way, then rebuild it from the file on
            // disk, the way its onLoaded does, to prove the collapse survives
            // that and isn't cached anywhere else.
            WidgetsStore.data = {
                "enabled": [],
                "options": {}
            };
            root.wipedCollapsed = Statusphere.detailsCollapsedFor(root.serverId);
            WidgetsStore.data = JSON.parse(storeView.text());
            root.reloadedCollapsed = Statusphere.detailsCollapsedFor(root.serverId);
            root.reloadedVisible = root.rowVisible();

            Statusphere.toggleDetailsCollapsed(root.serverId);
            root.step = 2;
            break;
        case 2:
            if (root.storedCollapsedIds().includes(root.serverId))
                return;
            root.afterExpandStoredIds = root.storedCollapsedIds();
            root.afterExpandVisible = root.rowVisible();
            root.step = 3;
            break;
        }
    }

    function checks() {
        return [
            {
                "name": "a server's forced detail card starts expanded",
                "got": [root.beforeCollapsed, root.beforeVisible],
                "want": [false, true]
            },
            {
                "name": "collapsing it writes the account id into the persisted widget option and hides the card",
                "got": [root.afterCollapseStoredIds.includes(root.serverId), root.afterCollapseVisible],
                "want": [true, false]
            },
            {
                "name": "a blanked-out store reports it expanded again, so nothing else is caching the flag",
                "got": root.wipedCollapsed,
                "want": false
            },
            {
                "name": "rebuilding the store from the file on disk - what a shell reload does - keeps it collapsed",
                "got": [root.reloadedCollapsed, root.reloadedVisible],
                "want": [true, false]
            },
            {
                "name": "expanding it again removes the id from the persisted option and reopens the card",
                "got": [root.afterExpandStoredIds.includes(root.serverId), root.afterExpandVisible],
                "want": [false, true]
            }
        ];
    }
}
