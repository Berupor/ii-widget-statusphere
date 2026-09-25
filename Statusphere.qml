pragma Singleton
pragma ComponentBehavior: Bound

// Room presence, streamed from the `statusphere` cli (github.com/MAX1T1A/statusphere).

import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import "CardLayouts.js" as CardLayouts

Singleton {
    id: root

    property bool binaryFound: false
    property bool registered: false
    property string selfAccountId: ""
    property string selfDeviceId: ""
    property string cliVersion: ""
    property bool cliVersionChecked: false
    property bool cliCompatible: false
    readonly property string minCliVersion: "0.11.0" // tag that first ships --version; bump on release
    readonly property bool available: root.binaryFound && root.registered
    readonly property bool enabled: WidgetCatalog.isEnabled("statusphere")
    readonly property bool shouldRun: root.enabled && root.available

    /// Widget option by manifest key, for every file of this widget
    function opt(key: string): var {
        return WidgetCatalog.option("statusphere", key);
    }

    // Raw member maps from the last parsed line, flat and heterogeneous by design
    property var members: []
    // Each account's current shared photo, if any: { account_id, path, created_at, expires_at }
    property var photos: []
    property bool live: false
    property string lastError: ""

    // One entry per account_id: { id, name, role, offline, devices, primary }
    readonly property var accountsById: {
        const byId = {};
        for (const m of root.members) {
            const id = m.account_id || m.device_id || "";
            if (!id)
                continue;
            if (!byId[id]) {
                byId[id] = {
                    "id": id,
                    "name": "",
                    "role": m._role || "member",
                    "offline": true,
                    "devices": []
                };
            }
            const acc = byId[id];
            if (m._role)
                acc.role = m._role;
            if (m._offline) {
                if (m.account_name)
                    acc.name = m.account_name;
                continue;
            }
            acc.offline = false;
            acc.devices.push(m);
        }
        for (const id in byId) {
            const acc = byId[id];
            const newest = acc.devices.reduce((max, d) => Math.max(max, d.last_seen ?? 0), 0);
            acc.devices.sort((a, b) => root.compareDevices(a, b, newest));
            acc.primary = acc.devices[0] ?? null;
            // Each device publishes its own copy of the account name and they go stale apart,
            // so read it off one fixed device instead of whichever the cli listed last.
            acc.name = root.labelDevice(acc)?.account_name || acc.devices.find(d => d.account_name)?.account_name || acc.name;
        }
        return byId;
    }

    // The cli emits devices in random order, so rank them. Live devices differ by a jittery
    // second of last_seen, so freshness only counts once one falls this far behind the newest.
    readonly property int staleGap: 45

    function deviceRank(device): int {
        // A game outranks music: music wanders onto a phone in a way a game never does
        if (device.game_status === "playing")
            return 0;
        if (device.spotify_status === "playing" && !root.stalled(device))
            return 1;
        if (device.spotify_status)
            return 2;
        return 3;
    }

    // A client that keeps saying "playing" while its position sits still lost the Spotify Connect
    // session to another device and never noticed, so watch the position advance per device.
    readonly property int stallTimeout: 8000
    // Mutated in place on every snapshot, never reassigned, so nothing binds to it:
    // bindings read stalledDeviceIds, which changes only when a device stalls or recovers.
    readonly property var progressByDevice: ({})
    property var stalledDeviceIds: []

    function noteProgress(members): void {
        const now = Date.now();
        const progress = root.progressByDevice;
        const playing = new Set();
        for (const m of members) {
            const id = m.device_id;
            if (!id || m.spotify_status !== "playing")
                continue;
            playing.add(id);
            const key = root.trackKey(m);
            const pos = m.spotify_position ?? 0;
            const prev = progress[id];
            if (!prev || prev.key !== key || pos > prev.pos)
                progress[id] = {
                    "key": key,
                    "pos": pos,
                    "at": now
                };
        }
        for (const id of Object.keys(progress))
            if (!playing.has(id))
                delete progress[id];
        const stalled = Object.keys(progress).filter(id => now - progress[id].at > root.stallTimeout).sort();
        if (stalled.join("\n") !== root.stalledDeviceIds.join("\n"))
            root.stalledDeviceIds = stalled;
    }

    function stalled(device): bool {
        return root.stalledDeviceIds.includes(device?.device_id);
    }

    function compareDevices(a, b, newest): int {
        const behind = d => (newest - (d.last_seen ?? 0) > root.staleGap) ? 1 : 0;
        const own = d => d.device_id === root.selfDeviceId ? 0 : 1;
        return root.deviceRank(a) - root.deviceRank(b) || behind(a) - behind(b) || own(a) - own(b) || (a.device_id ?? "").localeCompare(b.device_id ?? "");
    }

    // One entry per account_id with a live share: { account_id, path, created_at, expires_at }
    readonly property var photosByAccountId: {
        const byId = {};
        for (const p of root.photos) {
            if (p.account_id)
                byId[p.account_id] = p;
        }
        return byId;
    }

    // Ticks so currentPhotoFor's expiry check re-evaluates between stdout lines,
    // not just when the roster/photo list itself changes.
    property real _now: Date.now()

    Timer {
        interval: 30000
        running: root.shouldRun || root.incognitoMode
        repeat: true
        onTriggered: root._now = Date.now()
    }

    // Incognito is the cli's own state, shared with its tui, so read the file instead
    // of keeping a second copy of the truth here.
    property bool incognitoMode: false
    property bool incognitoAnnounce: true
    property string incognitoNote: ""
    property real incognitoUntil: 0
    readonly property bool hiding: root.incognitoMode && (root.incognitoUntil === 0 || root._now < root.incognitoUntil)

    FileView {
        path: `${Directories.config}/statusphere/privacy.json`
        printErrors: false // Missing until the first toggle, which is the normal state
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.readPrivacy(text())
        onLoadFailed: root.readPrivacy("")
    }

    function readPrivacy(text: string): void {
        try {
            const privacy = JSON.parse(text);
            const until = Date.parse(privacy.until ?? "");
            root.incognitoMode = (privacy.mode ?? "normal") !== "normal";
            root.incognitoAnnounce = privacy.announce !== false;
            root.incognitoNote = privacy.note ?? "";
            root.incognitoUntil = isNaN(until) ? 0 : until;
        } catch (e) {
            root.incognitoMode = false;
            root.incognitoAnnounce = true;
            root.incognitoNote = "";
            root.incognitoUntil = 0;
        }
        root._now = Date.now();
    }

    function setIncognito(on: bool, minutes: int): void {
        const arg = !on ? "off" : (minutes > 0 ? `${minutes}m` : "on");
        incognitoProc.command = ["bash", "-c", `"$HOME/.local/bin/statusphere" --incognito ${arg}`];
        incognitoProc.running = true;
    }

    Process {
        id: incognitoProc
    }

    function incognitoLabel(): string {
        if (!root.hiding)
            return Translation.tr("Your room sees what you're up to");
        if (root.incognitoNote)
            return Translation.tr("Hidden · %1").arg(root.incognitoNote);
        if (root.incognitoUntil > 0)
            return Translation.tr("Hidden until %1").arg(Qt.formatTime(new Date(root.incognitoUntil), "HH:mm"));
        return Translation.tr("Hidden from your room");
    }

    // A hidden card should still say something. The line is picked from the account id
    // so it stays with the person instead of changing on every roster update.
    readonly property var hiddenLines: [Translation.tr("off the radar"), Translation.tr("somewhere else"), Translation.tr("heads down"), Translation.tr("out of frame"), Translation.tr("keeping it quiet"), Translation.tr("doing something")]

    function isSelf(account): bool {
        return !!account?.id && account.id === root.selfAccountId;
    }

    // Your own row is the room's view of you, so it hides itself too - including when
    // announce is off and the room is told nothing at all.
    function hiddenFor(account): bool {
        return account?.primary?._incognito === true || (root.hiding && root.isSelf(account));
    }

    function hiddenLineFor(account): string {
        const note = account?.primary?._incognito_note ?? "";
        if (note)
            return note;
        if (root.isSelf(account) && !root.incognitoAnnounce)
            return Translation.tr("Nothing at all");
        const id = account?.id ?? "";
        let sum = 0;
        for (let i = 0; i < id.length; i++) {
            sum += id.charCodeAt(i);
        }
        return root.hiddenLines[sum % root.hiddenLines.length];
    }

    // A demo/preview account can carry its photo straight on the object - there is no
    // account_id it could ingest a real photo line under.
    function currentPhotoFor(account): var {
        if (account?._photo)
            return account._photo;
        const p = root.photosByAccountId[account?.id];
        if (!p)
            return null;
        const expiresAt = Date.parse(p.expires_at);
        if (isNaN(expiresAt) || root._now >= expiresAt)
            return null;
        return p;
    }

    readonly property var selfAccount: root.accountsById[root.selfAccountId] ?? null
    readonly property bool canShare: root.available && root.opt("photoShare")

    // Sharing runs its own cli invocation: --post-photo is a plain http post that touches
    // no local state, so it's safe next to the feed process.
    property bool posting: false
    property string lastPostError: ""

    // The server re-encodes to 1600px anyway, so shrink here too and stay far from the cli's 8MiB cap.
    readonly property string resizeArgs: "-resize '1600x1600>'"
    readonly property string postTempPath: `${Directories.screenshotTemp}/statusphere-post.png`

    function postPhoto(path: string): void {
        if (!path)
            return;
        root.startPost(`magick '${StringUtils.shellSingleQuoteEscape(path)}' ${root.resizeArgs} png:'${root.postTempPath}'`);
    }

    // Source is the region selector's throwaway screenshot, so it goes away with the crop.
    function postRegion(sourcePath: string, x: real, y: real, width: real, height: real): void {
        const source = StringUtils.shellSingleQuoteEscape(sourcePath);
        const crop = `-crop ${Math.round(width)}x${Math.round(height)}+${Math.round(x)}+${Math.round(y)} +repage`;
        root.startPost(`magick '${source}' ${crop} ${root.resizeArgs} png:'${root.postTempPath}' && rm -f '${source}'`);
    }

    function startPost(prepareCommand: string): void {
        if (!root.canShare || root.posting)
            return;
        root.lastPostError = "";
        postProc.command = ["bash", "-c", `mkdir -p '${Directories.screenshotTemp}' && ${prepareCommand} && ` //
            + `"$HOME/.local/bin/statusphere" --post-photo '${root.postTempPath}'; ` //
            + `status=$?; rm -f '${root.postTempPath}'; exit $status`];
        root.posting = true;
        postProc.running = true;
    }

    function notifyPost(body: string): void {
        Quickshell.execDetached(["notify-send", Translation.tr("Statusphere"), body, "-a", "Shell"]);
    }

    Process {
        id: postProc
        property string reply: ""
        stdout: StdioCollector {
            onStreamFinished: postProc.reply = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: root.lastPostError = text.trim()
        }
        onExited: exitCode => {
            root.posting = false;
            if (exitCode === 0) {
                // "Shared. Visible to your room until <time>"
                root.notifyPost(postProc.reply || Translation.tr("Photo shared with your room"));
                return;
            }
            if (!root.lastPostError)
                root.lastPostError = Translation.tr("Could not share the photo");
            root.notifyPost(root.lastPostError);
        }
    }

    // Rows look themselves up in accountsById; reassigning this makes the Repeater rebuild
    // every delegate, so only do it when the roster itself changes.
    property var accountIds: []

    onAccountsByIdChanged: {
        const ids = Object.keys(root.accountsById).sort((a, b) => {
            const x = root.accountsById[a];
            const y = root.accountsById[b];
            if (x.offline !== y.offline)
                return x.offline ? 1 : -1;
            return root.nameFor(x).toLowerCase().localeCompare(root.nameFor(y).toLowerCase());
        });
        if (ids.length !== root.accountIds.length || ids.some((id, i) => id !== root.accountIds[i]))
            root.accountIds = ids;
    }

    readonly property int memberCount: root.accountIds.length
    readonly property int onlineCount: Object.values(root.accountsById).filter(a => !a.offline).length

    // Machines, not people: a server card is read for its metrics. The kind sticks
    // per account so an offline server stays a server instead of turning into a face.
    property var kindById: ({})

    function noteKinds(members): void {
        const kinds = Object.assign({}, root.kindById);
        let changed = false;
        for (const m of members) {
            const id = m.account_id ?? "";
            if (id && m._kind && kinds[id] !== m._kind) {
                kinds[id] = m._kind;
                changed = true;
            }
        }
        if (changed)
            root.kindById = kinds;
    }

    function isServer(account): bool {
        return (account?.primary?._kind ?? root.kindById[account?.id ?? ""] ?? "") === "server";
    }

    // Reconnecting reorders accountIds (offline sinks to the bottom), which rebuilds the
    // Repeater's delegates, and a shell reload drops the singleton too - so the collapsed
    // state for a server's forced detail card is a widget option, keyed by account id,
    // rather than state on the row or an in-memory property here.
    function detailsCollapsedFor(accountId): bool {
        return (root.opt("collapsedDetailIds") ?? []).includes(accountId);
    }

    function toggleDetailsCollapsed(accountId): void {
        const ids = root.opt("collapsedDetailIds") ?? [];
        const next = ids.includes(accountId) ? ids.filter(id => id !== accountId) : ids.concat([accountId]);
        WidgetsStore.setOption("statusphere", "collapsedDetailIds", next);
    }

    // The verdict is the machine's own, from ~/.config/statusphere/health.json there.
    function healthFor(account): string {
        return account?.primary?._health ?? "";
    }

    function healthNoteFor(account): string {
        return account?.primary?._health_note ?? "";
    }

    // The agent reports how long the primary device has sat untouched; a game or a
    // call still counts as present, so this never overrides what's already on the line.
    function awayFor(account): bool {
        if (!root.opt("away") || !account || account.offline || root.isServer(account))
            return false;
        return (account.primary?.idle_seconds ?? 0) >= root.opt("awayMinutes") * 60;
    }

    readonly property var serverIds: root.accountIds.filter(id => root.isServer(root.accountsById[id]))

    // A silent agent and a dead machine look the same from here, so say which one it is.
    function offlineLineFor(account): string {
        if (!root.isServer(account))
            return Translation.tr("Offline");
        return root.serverReachable ? Translation.tr("Not reporting") : Translation.tr("Host unreachable");
    }

    // The agent runs on the box it reports on, so it cannot report its own death.
    // Asking the server directly is what tells a dead host from a dead feed.
    property string selfServerUrl: ""
    property bool serverReachable: true

    Process {
        id: healthProc
        command: ["curl", "-sfm", "5", `${root.selfServerUrl}/health`]
        onExited: exitCode => root.serverReachable = (exitCode === 0)
    }

    Timer {
        interval: root.opt("serverPingSeconds") * 1000
        running: root.shouldRun && root.selfServerUrl !== "" && root.serverIds.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: healthProc.running = true
    }

    // A device name is the last resort for the account label, so pick one that stays put when
    // playback hops between devices - primary follows the music, this must not.
    function labelDevice(account): var {
        const devices = account?.devices ?? [];
        return devices.find(d => d.device_id === root.selfDeviceId) ?? devices.slice().sort((a, b) => (a.device_id ?? "").localeCompare(b.device_id ?? ""))[0] ?? null;
    }

    function nameFor(account): string {
        if (!account)
            return "";
        if (account.name)
            return account.name;
        return root.labelDevice(account)?.device_name || account.id.slice(0, 8);
    }

    function initialFor(account): string {
        const name = root.nameFor(account);
        return name ? name.charAt(0).toUpperCase() : "?";
    }

    function trackKey(device): string {
        return device?.spotify_uri || device?.spotify_display || `${device?.spotify_track ?? ""}/${device?.spotify_artist ?? ""}`;
    }

    // Spotify Connect syncs one session across an account's devices, so they report the same
    // track - keep one device per distinct track, playing ones first (devices come sorted).
    function musicDevices(account): var {
        const playing = (account?.devices ?? []).filter(d => d.spotify_status);
        const live = playing.filter(d => !root.stalled(d));
        const seen = new Set();
        return (live.length > 0 ? live : playing).filter(d => {
            const key = root.trackKey(d);
            if (seen.has(key))
                return false;
            seen.add(key);
            return true;
        });
    }

    // No Connect-style dedup to do here, only the guard against two machines in one title
    function gameDevices(account): var {
        const seen = new Set();
        return (account?.devices ?? []).filter(d => {
            if (!d.game_status || !d.game_name)
                return false;
            const key = d.game_appid || d.game_name;
            if (seen.has(key))
                return false;
            seen.add(key);
            return true;
        });
    }

    // The photo badge's vocabulary - Now, 5m, 2h, and a day count once a full day has
    // elapsed. Elapsed, not calendar-day: a session started 13 minutes ago at 23:58
    // reads "13m", not "Yesterday", so it never depends on when the clock is read.
    function sessionFor(startedMs: real): string {
        if (!(startedMs > 0))
            return "";
        const elapsedMs = root._now - startedMs;
        const days = Math.floor(elapsedMs / 86400000);
        if (days >= 1)
            return Translation.tr("%1d").arg(days);
        if (elapsedMs < 60000)
            return Translation.tr("Now");
        const hours = Math.floor(elapsedMs / 3600000);
        if (hours >= 1)
            return Translation.tr("%1h").arg(hours);
        return Translation.tr("%1m").arg(Math.floor(elapsedMs / 60000));
    }

    function gameFor(device): string {
        if (!device?.game_status)
            return "";
        return device.game_display || device.game_name || "";
    }

    // Steam gives a start time where it has one and a running total where it doesn't
    function gameStartedMsFor(device): real {
        const at = Date.parse(device?.game_started_at ?? "");
        if (!isNaN(at))
            return at;
        const secs = device?.game_session_seconds ?? 0;
        return secs > 0 ? root._now - secs * 1000 : 0;
    }

    // The title belongs next to the person, not under their art: a stylised logo is
    // already on the picture, and the status line is where every other activity is
    // read. game_started_at does not move, so the label cannot drift; _now is what
    // re-reads the clock between roster lines.
    function gameLineFor(account): string {
        const device = root.gameDevices(account)[0];
        const name = root.gameFor(device);
        if (!name)
            return "";
        const session = root._now > 0 ? root.sessionFor(root.gameStartedMsFor(device)) : "";
        return session ? Translation.tr("Playing %1 · %2").arg(name).arg(session) : Translation.tr("Playing %1").arg(name);
    }

    // Fields a currently visible tile already renders for this account, so the header
    // above it does not say the same thing twice on the same surface.
    function coveredFields(visibleSurfaces): var {
        const fields = new Set();
        for (const tiles of Object.values(visibleSurfaces ?? {}))
            for (const t of tiles)
                if (t.field)
                    fields.add(t.field);
        return fields;
    }

    function statusFor(account, visibleSurfaces): string {
        if (!account || account.offline)
            return "";
        if (root.hiddenFor(account))
            return root.hiddenLineFor(account);
        if (root.isServer(account))
            return root.healthNoteFor(account) || Translation.tr("All good");
        // The game is said here and only here; the card below is the picture of it.
        if (root.gameDevices(account).length > 0)
            return root.gameLineFor(account);
        const playing = root.musicDevices(account);
        if (playing.length > 1)
            return Translation.tr("Listening on %1 devices").arg(playing.length);
        const covered = root.coveredFields(visibleSurfaces);
        const p = account.primary;
        if (p?.active_window && !covered.has("active_window"))
            return p.active_window;
        if (p?.active_app && !covered.has("active_app"))
            return p.active_app;
        if (p?.spotify_status)
            return "";
        if (root.awayFor(account))
            return Translation.tr("Away · %1").arg(root.sessionFor(root._now - (p?.idle_seconds ?? 0) * 1000));
        return Translation.tr("Online");
    }

    function deviceNameFor(device): string {
        return device?.device_name || (device?.device_id ?? "").slice(0, 8);
    }

    function deviceStatusFor(device): string {
        const what = device?.active_window || device?.active_app || Translation.tr("Online");
        const name = root.deviceNameFor(device);
        return name ? `${name} · ${what}` : what;
    }

    function trackFor(device): string {
        if (!device?.spotify_status)
            return "";
        return device.spotify_display || `${device.spotify_track ?? ""} — ${device.spotify_artist ?? ""}`;
    }

    function canSync(device): bool {
        return !!device?.spotify_uri && device.device_id !== root.selfDeviceId;
    }

    // Same mechanism as the TUI's sync action (client/internal/media/media.go): MPRIS OpenUri.
    function syncSpotify(device): void {
        const uri = device?.spotify_uri;
        if (!uri)
            return;
        Quickshell.execDetached(["dbus-send", "--session", "--type=method_call", "--dest=org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player.OpenUri", `string:${uri}`]);
    }

    // "mem" ships as "used/total" text (eg. "21155M/31663M"), not a percentage, so
    // derive its bar fill from the raw MB totals the device sends alongside it.
    function percentForField(key, raw, device): var {
        const direct = raw.match(/^(\d+(?:\.\d+)?)\s*%$/);
        if (direct)
            return parseFloat(direct[1]);
        if ((key === "mem" || key === "ram" || key === "memory") && device.memory_total_mb > 0)
            return device.memory_used_mb / device.memory_total_mb * 100;
        return null;
    }

    // A key without an entry here falls through to no icon rather than a generic one -
    // a wrong icon reads worse than a bare label.
    function iconForField(key): string {
        switch (key) {
        case "cpu":
            return "planner_review";
        case "mem":
        case "ram":
        case "memory":
            return "memory";
        case "disk":
            return "storage";
        case "gpu":
            return "deployed_code";
        case "project":
            return "terminal";
        case "workspace":
            return "desktop_windows";
        case "language":
            return "code";
        case "mood":
            return "mood";
        case "region":
            return "location_on";
        case "top_artist":
            return "album";
        case "genre":
            return "library_music";
        default:
            return "";
        }
    }

    function formatUptime(hours): string {
        if (hours < 1)
            return Translation.tr("%1m").arg(Math.round(hours * 60));
        if (hours < 48)
            return Translation.tr("%1h").arg(Math.round(hours));
        return Translation.tr("%1d").arg(Math.round(hours / 24));
    }

    // Metrics the cli collects itself, so custom.json does not have to shell out
    // for them. A custom field of the same name loses to these.
    readonly property var nativeFieldKeys: ["cpu", "mem", "ram", "memory", "disk", "load", "uptime", "workspace", "active_app", "active_window", "package_count"]

    function systemFieldsFor(device): var {
        const fields = [];
        if (device?.cpu_percent !== undefined)
            fields.push({
                "key": "cpu",
                "icon": "planner_review",
                "label": Translation.tr("CPU"),
                "value": `${Math.round(device.cpu_percent)}%`,
                "percent": device.cpu_percent
            });
        if (device?.memory_total_mb > 0) {
            const percent = device.memory_used_mb / device.memory_total_mb * 100;
            fields.push({
                "key": "mem",
                "icon": "memory",
                "label": Translation.tr("Memory"),
                "value": `${(device.memory_used_mb / 1024).toFixed(1)}/${(device.memory_total_mb / 1024).toFixed(1)}G`,
                "percent": percent
            });
        }
        if (device?.disk_used_percent !== undefined)
            fields.push({
                "key": "disk",
                "icon": "storage",
                "label": Translation.tr("Disk"),
                "note": device.disk_free_gb !== undefined ? Translation.tr("%1G free").arg(Math.round(device.disk_free_gb)) : "",
                "value": `${Math.round(device.disk_used_percent)}%`,
                "percent": device.disk_used_percent
            });
        if (device?.load_avg_1m !== undefined)
            fields.push({
                "key": "load",
                "icon": "speed",
                "label": Translation.tr("Load"),
                "value": device.cpu_count > 0 ? `${device.load_avg_1m.toFixed(2)} / ${device.cpu_count}` : device.load_avg_1m.toFixed(2),
                "percent": null
            });
        if (device?.uptime_hours !== undefined)
            fields.push({
                "key": "uptime",
                "icon": "schedule",
                "label": Translation.tr("Uptime"),
                "value": root.formatUptime(device.uptime_hours),
                "percent": null
            });
        return fields;
    }

    // Structured for the right-click detail card and for a scalar tile's field lookup:
    // percentage fields become { percent }, everything else (workspace, uptime, any
    // custom field) stays text-only.
    function fieldsFor(device): var {
        if (!device)
            return [];
        const fields = root.systemFieldsFor(device);
        if (device.active_workspace)
            fields.push({
                "key": "workspace",
                "icon": "desktop_windows",
                "label": Translation.tr("Workspace"),
                "value": String(device.active_workspace),
                "percent": null
            });
        if (device.active_window)
            fields.push({
                "key": "active_window",
                "icon": "web_asset",
                "label": Translation.tr("Window"),
                "value": device.active_window,
                "percent": null
            });
        if (device.active_app)
            fields.push({
                "key": "active_app",
                "icon": "apps",
                "label": Translation.tr("App"),
                "value": device.active_app,
                "percent": null
            });
        if (device.package_count !== undefined)
            fields.push({
                "key": "package_count",
                "icon": "inventory_2",
                "label": Translation.tr("Packages"),
                "value": String(device.package_count),
                "percent": null
            });
        for (const key of (device.custom_fields ?? [])) {
            if (!device[key] || root.nativeFieldKeys.includes(key))
                continue;
            const raw = String(device[key]);
            fields.push({
                "key": key,
                "icon": device[`${key}_icon`] || root.iconForField(key),
                "label": root.labelForKey(key),
                "value": raw,
                "percent": root.percentForField(key, raw, device)
            });
        }
        return fields;
    }

    // custom.json keys are snake_case by convention (matches nativeFieldKeys), a tile's
    // label is read, so title-case it instead of printing the key verbatim.
    function labelForKey(key: string): string {
        return key.split("_").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
    }

    // A scalar field the card editor can write a literal value for: not the wildcard,
    // not a metric the cli collects on its own.
    function isCustomFieldKey(key: string): bool {
        return key.length > 0 && key !== "*" && !root.nativeFieldKeys.includes(key);
    }

    function detailFieldsFor(account): var {
        if (!account || account.offline)
            return [];
        return root.fieldsFor(account.primary);
    }

    function fieldFor(device, key): var {
        return root.fieldsFor(device).find(f => f.key === key) ?? null;
    }

    // A device's own layout is a snapshot field like any other, prefixed the way
    // _kind/_health are: it never leaves this machine unless the owner published it.
    // updated_at is a unix-seconds number, stamped by the editor on every save.
    function layoutFor(account): var {
        let best = null;
        const devices = Array.isArray(account?.devices) ? account.devices : [];
        for (const d of devices) {
            const l = d?.[CardLayouts.layoutKey];
            if (l && typeof l === "object" && (best === null || (l.updated_at ?? 0) > (best.updated_at ?? 0)))
                best = l;
        }
        return best;
    }

    // row: [] is a deliberate "header only" choice, distinct from no row key at all,
    // which falls back to the default row stack - detail has no such distinction, an
    // empty or invalid detail always falls back to the standard card.
    function ownsSurface(account, surface): bool {
        return Array.isArray(root.layoutFor(account)?.[surface]);
    }

    // A layout.json can be hand-edited or come from a stale client: an unrecognised
    // type/size/form gets the tile dropped rather than mis-rendered.
    function sanitizeTile(t): var {
        const type = (t && typeof t === "object" && !Array.isArray(t)) ? CardLayouts.typeOf(t) : null;
        if (!type)
            return null;
        if (t.size !== undefined && !CardLayouts.sizes.includes(t.size))
            return null;
        if (type.needsField && (typeof t.field !== "string" || t.field.length === 0))
            return null;
        const forms = Object.keys(type.forms);
        if (forms.length > 0 && t.form !== undefined && !forms.includes(t.form))
            return null;
        const known = CardLayouts.withKnownBackground(t);
        return type.sanitize ? type.sanitize(known) : known;
    }

    // A "*" field expands to every detail field the layout does not already name,
    // so an owner's layout does not have to list every custom.json key by hand.
    function expandWildcardTiles(tiles, account): var {
        const clean = (Array.isArray(tiles) ? tiles : []).map(t => root.sanitizeTile(t)).filter(t => t !== null);
        const named = new Set(clean.filter(t => t.field !== "*").map(t => t.field));
        const out = [];
        for (const t of clean) {
            if (t.field !== "*") {
                out.push(t);
                continue;
            }
            for (const f of root.detailFieldsFor(account)) {
                if (named.has(f.key))
                    continue;
                out.push(Object.assign({}, t, {
                    "field": f.key
                }));
            }
        }
        return out;
    }

    function surfaceTiles(account, surface): var {
        const custom = root.layoutFor(account);
        const tiles = custom ? root.expandWildcardTiles(custom[surface], account) : [];
        return surface === "detail" ? CardLayouts.fallbackDetail(tiles, root.detailFieldsFor(account)) : tiles;
    }

    function deviceForTile(account, tile): var {
        if (!tile.device)
            return account?.primary ?? null;
        return (account?.devices ?? []).find(d => d.device_id === tile.device) ?? null;
    }

    function tileHasData(account, tile): bool {
        return CardLayouts.typeOf(tile)?.hasData(root, account, tile) ?? false;
    }

    // The cli's stderr is a raw Go error (eg. "failed to connect: WebSocket dial: expected
    // handshake response status code 101 but got 200") - no contract on length or language.
    // Off the home network / behind a captive portal / waking from sleep is the normal path
    // for a laptop, not a rare one, so this fires often enough to be worth a readable message
    // instead of a wall of text that blows out the placeholder's width.
    readonly property int errorMaxLength: 60

    function friendlyError(raw: string): string {
        if (!raw)
            return "";
        const low = raw.toLowerCase();
        if (low.includes("no such host") || low.includes("network is unreachable") || low.includes("connection refused") || low.includes("dial tcp"))
            return Translation.tr("Can't reach the room server");
        if (low.includes("timeout") || low.includes("timed out") || low.includes("deadline exceeded"))
            return Translation.tr("Room server timed out");
        if (low.includes("handshake") || low.includes("tls") || low.includes("certificate"))
            return Translation.tr("Room server rejected the connection");
        if (low.includes("401") || low.includes("403") || low.includes("unauthorized") || low.includes("forbidden"))
            return Translation.tr("Not registered with the room server");
        const oneLine = raw.replace(/\s+/g, " ").trim();
        return oneLine.length > root.errorMaxLength ? oneLine.slice(0, root.errorMaxLength - 1) + "…" : oneLine;
    }

    function versionAtLeast(current: string, minimum: string): bool {
        const parse = v => v.replace(/^v/, "").split(/[-+]/)[0].split(".").map(n => parseInt(n, 10) || 0);
        const c = parse(current);
        const m = parse(minimum);
        for (let i = 0; i < 3; i++) {
            if (c[i] !== m[i])
                return c[i] > m[i];
        }
        return true;
    }

    function placeholderText(): string {
        if (!root.binaryFound)
            return Translation.tr("statusphere cli not found in ~/.local/bin");
        if (!root.registered)
            return Translation.tr("No statusphere account registered");
        if (root.cliVersionChecked && !root.cliCompatible)
            return Translation.tr("statusphere cli needs updating");
        if (!root.live)
            return root.friendlyError(root.lastError) || Translation.tr("Connecting…");
        return Translation.tr("Nobody else around yet");
    }

    // Pending snapshot from lines not yet applied to members/photos
    property var _pendingMembers: null
    property var _pendingPhotos: null

    function ingest(line: string): void {
        const text = line.trim();
        if (!text)
            return;
        try {
            const data = JSON.parse(text);
            root._pendingMembers = data.members ?? [];
            root._pendingPhotos = data.photos ?? [];
            root.live = true;
            root.retryDelay = root.retryMin;
            root.scheduleFlush();
        } catch (e) {
            // Ignore malformed lines, keep the last good roster
        }
    }

    // Devices publish independently every couple seconds, so a busy room can burst several
    // lines back to back; coalesce them into one accountsById rebuild instead of one each.
    readonly property int flushIntervalMs: 250

    function scheduleFlush(): void {
        if (!flushTimer.running)
            flushTimer.start();
    }

    Timer {
        id: flushTimer
        interval: root.flushIntervalMs
        onTriggered: root.flush()
    }

    function flush(): void {
        if (root._pendingMembers === null)
            return;
        const members = root._pendingMembers;
        const photos = root._pendingPhotos;
        root._pendingMembers = null;
        root._pendingPhotos = null;
        root.noteProgress(members);
        root.noteKinds(members);
        root.members = members;
        if (JSON.stringify(photos) !== JSON.stringify(root.photos))
            root.photos = photos;
    }

    Process {
        running: true
        command: ["bash", "-c", "command -v \"$HOME/.local/bin/statusphere\" >/dev/null 2>&1"]
        onExited: exitCode => root.binaryFound = (exitCode === 0)
    }

    Process {
        running: true
        command: ["bash", "-c", "test -s \"${XDG_CONFIG_HOME:-$HOME/.config}/statusphere/config.json\""]
        onExited: exitCode => root.registered = (exitCode === 0)
    }

    Process {
        running: true
        command: ["bash", "-c", "\"$HOME/.local/bin/statusphere\" --version 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim();
                root.cliVersion = v;
                root.cliCompatible = v !== "" && root.versionAtLeast(v, root.minCliVersion);
                root.cliVersionChecked = true;
            }
        }
    }

    Process {
        running: true
        command: ["bash", "-c", "cat \"${XDG_CONFIG_HOME:-$HOME/.config}/statusphere/config.json\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const config = JSON.parse(text);
                    root.selfAccountId = config.account_id ?? "";
                    root.selfDeviceId = config.device_id ?? "";
                    root.selfServerUrl = (config.server_url ?? "").replace(/\/+$/, "");
                } catch (e) {
                    root.selfAccountId = "";
                    root.selfDeviceId = "";
                    root.selfServerUrl = "";
                }
            }
        }
    }

    readonly property int retryMin: 2000
    readonly property int retryMax: 120000
    property int retryDelay: root.retryMin
    property bool wantRunning: false

    onShouldRunChanged: {
        restartTimer.stop();
        root.retryDelay = root.retryMin;
        root.wantRunning = root.shouldRun;
    }

    Timer {
        id: restartTimer
        interval: root.retryDelay
        onTriggered: root.wantRunning = true
    }

    // A heartbeat gap much bigger than its interval means the system was asleep - the feed's
    // connection is likely stale even if it hasn't noticed, so force a reconnect.
    readonly property int heartbeatInterval: 20000
    readonly property int suspendGap: 60000
    property real _lastHeartbeat: 0

    Timer {
        interval: root.heartbeatInterval
        running: root.shouldRun
        repeat: true
        onTriggered: {
            const now = Date.now();
            if (root._lastHeartbeat && now - root._lastHeartbeat > root.suspendGap)
                root.wantRunning = false;
            root._lastHeartbeat = now;
        }
    }

    Process {
        id: feed
        running: root.shouldRun && root.wantRunning
        command: ["bash", "-c", "exec \"$HOME/.local/bin/statusphere\" --ui json"]
        stdout: SplitParser {
            onRead: line => root.ingest(line)
        }
        stderr: SplitParser {
            onRead: line => root.lastError = line
        }
        onExited: (exitCode, exitStatus) => {
            root.live = false;
            root.members = [];
            root.photos = [];
            root.wantRunning = false;
            if (root.shouldRun) {
                root.retryDelay = Math.min(root.retryMax, root.retryDelay * 2);
                restartTimer.restart();
            }
        }
    }
}
