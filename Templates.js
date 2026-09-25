.pragma library

// custom.json fields run their "cmd" through sh -c, so every answer that goes into one
// is shell-quoted.
function shQuote(value) {
    return `'${String(value).replace(/'/g, "'\\''")}'`;
}

function shUnquote(token) {
    const m = /^'((?:[^']|'\\'')*)'$/.exec(token);
    return m ? m[1].replace(/'\\''/g, "'") : null;
}

function shPath(path) {
    const trimmed = path.trim();
    if (trimmed === "~")
        return "\"$HOME\"";
    if (trimmed.startsWith("~/"))
        return `"$HOME"/${shQuote(trimmed.slice(2))}`;
    return shQuote(trimmed);
}

const legacyTextCmdPrefix = "printf '%s' ";

function legacyTextOf(entry) {
    const cmd = entry?.cmd;
    if (typeof cmd !== "string" || !cmd.startsWith(legacyTextCmdPrefix))
        return null;
    return shUnquote(cmd.slice(legacyTextCmdPrefix.length));
}

function textOf(entry) {
    return typeof entry?.value === "string" ? entry.value : legacyTextOf(entry);
}

const clockCmd = "date +%H:%M";
const batteryCmd = "printf '%s%%' \"$(cat /sys/class/power_supply/BAT*/capacity | head -n1)\"";
const defaultCommandRepeat = 60;

// weatherLive's cmdFor line out of wttr.in's ?format=j1: temp C, weatherCode, precipMM,
// windspeedKmph, winddirDegree, is-day (local clock against the clock tile's own day
// window), city - CardLayouts.weatherFieldsOf/weatherConditionOf are the other end.
const weatherJqFilter = '.current_condition[0] as $c | (.nearest_area[0].areaName[0].value // "") as $city | [$c.temp_C, $c.weatherCode, $c.precipMM, $c.windspeedKmph, $c.winddirDegree, (if (now|localtime|strftime("%H")|tonumber) >= 6 and (now|localtime|strftime("%H")|tonumber) < 19 then "1" else "0" end), $city] | join(";")';

const weatherLiveSamples = ["22;113;0;6;180;1;Munich", "15;119;0;10;200;1;Munich", "13;302;3;15;220;1;Munich", "24;389;5;20;90;1;Munich", "-2;332;2;12;320;1;Munich", "7;248;0;3;0;1;Munich", "9;113;0;5;180;0;Munich"];

const kinds = [
    {
        "id": "weather",
        "label": "Weather",
        "icon": "partly_cloudy_day",
        "ask": "City",
        "hint": "City, blank for where you are",
        "sample": "18° · Clear",
        "repeat": 900,
        "tile": {
            "form": "weather",
            "shape": "auto",
            "size": "1x1",
            "color": "primaryContainer"
        },
        "cmdFor": city => `curl -sf ${shQuote(`wttr.in/${encodeURIComponent(city.trim())}?format=%t+·+%C`)}`
    },
    {
        "id": "weatherLive",
        "label": "Live weather",
        "beta": true,
        "icon": "partly_cloudy_day",
        "ask": "City",
        "hint": "City, blank for where you are",
        "sample": weatherLiveSamples[0],
        "samples": weatherLiveSamples,
        "repeat": 900,
        "tile": {
            "form": "weatherLive",
            "shape": "auto",
            "size": "1x1",
            "color": "primaryContainer"
        },
        "cmdFor": city => `curl -sf ${shQuote(`wttr.in/${encodeURIComponent(city.trim())}?format=j1`)} | jq -r ${shQuote(weatherJqFilter)}`
    },
    {
        "id": "clock",
        "label": "Clock",
        "icon": "schedule",
        "ask": "Timezone",
        "hint": "Timezone, eg. Asia/Tokyo, blank for local",
        "sample": "23:14",
        "repeat": 30,
        "tile": {
            "form": "clock",
            "shape": "auto",
            "size": "1x1",
            "color": "tertiaryContainer"
        },
        "cmdFor": zone => zone.trim() ? `TZ=${shQuote(zone.trim())} ${clockCmd}` : clockCmd
    },
    {
        "id": "moon",
        "label": "Moon phase",
        "icon": "bedtime",
        "ask": "City",
        "hint": "City, blank for where you are",
        "sample": "🌔",
        "repeat": 3600,
        "tile": {
            "form": "moon",
            "size": "1x1",
            "color": "primaryContainer"
        },
        "cmdFor": city => `curl -sf ${shQuote(`wttr.in/${encodeURIComponent(city.trim())}?format=%m`)}`
    },
    {
        "id": "sun",
        "label": "Sunrise & sunset",
        "icon": "wb_twilight",
        "ask": "City",
        "hint": "City, blank for where you are",
        "sample": "06:12 · 19:40",
        "repeat": 3600,
        "tile": {
            "form": "sun",
            "size": "2x1",
            "color": "tertiaryContainer"
        },
        "cmdFor": city => `curl -sf ${shQuote(`wttr.in/${encodeURIComponent(city.trim())}?format=%S+·+%s`)} | sed -E 's/:([0-9]{2}):[0-9]{2}/:\\1/g'`
    },
    {
        "id": "commits",
        "label": "Commits today",
        "icon": "commit",
        "ask": "Folder",
        "hint": "A git folder, eg. ~/Projects/app",
        "needsAnswer": true,
        "sample": "7",
        "repeat": 300,
        "tile": {
            "form": "number",
            "size": "1x1"
        },
        "cmdFor": folder => `git -C ${shPath(folder)} rev-list --count --since=midnight HEAD`
    },
    {
        "id": "battery",
        "label": "Battery",
        "icon": "battery_5_bar",
        "sample": "82%",
        "repeat": 120,
        "tile": {
            "form": "ring",
            "size": "1x1",
            "color": "tertiaryContainer"
        },
        "cmdFor": () => batteryCmd
    },
    {
        "id": "text",
        "label": "Your text",
        "defaultName": "Note",
        "icon": "edit_note",
        "ask": "Text",
        "hint": "What friends see",
        "needsAnswer": true,
        "sample": "brb, coffee",
        "tile": {
            "form": "text",
            "size": "2x1"
        }
    },
    {
        "id": "command",
        "label": "Your command",
        "defaultName": "Output",
        "icon": "terminal",
        "ask": "Command",
        "hint": "Shell command, its output is the value",
        "sample": "42",
        "repeat": defaultCommandRepeat,
        "tile": {
            "form": "text",
            "size": "2x1",
            "color": "primaryContainer"
        }
    }
];

function kind(id) {
    return kinds.find(k => k.id === id) ?? null;
}

function isCommandKind(id) {
    return id !== "text" && kind(id) !== null;
}

function seedsItself(k) {
    return typeof k?.cmdFor === "function" && k.needsAnswer !== true;
}

const kindByForm = kinds.filter(k => k.tile?.form === k.id).reduce((byForm, k) => Object.assign(byForm, {
            [k.id]: k.id
        }), {});

const repeatChoices = [...new Set([30, 60, 300, 900, 3600].concat(kinds.map(k => k.repeat).filter(r => r > 0)))].sort((a, b) => a - b);

function fieldKeyOf(name) {
    return String(name).trim().toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
}

function fieldKeyOfKind(k) {
    return fieldKeyOf(k.defaultName ?? k.label);
}

function galleryEntryFor(id) {
    const k = kind(id);
    return {
        "id": k.id,
        "label": k.label,
        "beta": k.beta === true,
        "ownerKind": k.id,
        "tile": Object.assign({
            "type": "scalar",
            "field": fieldKeyOfKind(k)
        }, k.tile)
    };
}

const galleryGroups = [
    {
        "title": "Live",
        "startsOpen": true,
        "entries": ["weather", "weatherLive", "clock", "moon", "sun", "commits", "battery"].map(galleryEntryFor)
    },
    {
        "title": "Your own",
        "entries": ["text", "command"].map(galleryEntryFor).concat([
            {
                "id": "picture",
                "label": "Picture",
                "tile": {
                    "type": "picture",
                    "url": "",
                    "size": "2x2"
                }
            }
        ])
    },
    {
        "title": "Activity",
        "entries": [
            {
                "id": "music-cover",
                "label": "Music - cover",
                "tile": {
                    "type": "music",
                    "form": "cover",
                    "size": "4x1",
                    "background": {
                        "kind": "live",
                        "value": "music"
                    }
                }
            },
            {
                "id": "game",
                "label": "Game",
                "tile": {
                    "type": "game",
                    "form": "banner",
                    "size": "4x1",
                    "background": {
                        "kind": "live",
                        "value": "game"
                    }
                }
            },
            {
                "id": "music-wave",
                "label": "Music - wave",
                "tile": {
                    "type": "music",
                    "form": "wave",
                    "size": "2x1",
                    "color": "tertiaryContainer"
                }
            },
            {
                "id": "game-timer",
                "label": "Game - session",
                "tile": {
                    "type": "game",
                    "form": "timer",
                    "size": "2x1"
                }
            },
            {
                "id": "window",
                "label": "Active window",
                "tile": {
                    "type": "scalar",
                    "field": "active_window",
                    "form": "text",
                    "size": "4x1"
                }
            },
            {
                "id": "music-vinyl",
                "label": "Music - vinyl",
                "tile": {
                    "type": "music",
                    "form": "vinyl",
                    "size": "2x2",
                    "color": "primaryContainer"
                }
            },
            {
                "id": "photo",
                "label": "Photo",
                "tile": {
                    "type": "photo",
                    "size": "1x1"
                }
            },
            {
                "id": "workspace",
                "label": "Workspace",
                "tile": {
                    "type": "scalar",
                    "field": "workspace",
                    "form": "number",
                    "size": "1x1",
                    "color": "tertiaryContainer"
                }
            }
        ]
    },
    {
        "title": "System",
        "entries": [
            {
                "id": "cpu",
                "label": "CPU ring",
                "tile": {
                    "type": "scalar",
                    "field": "cpu",
                    "form": "ring",
                    "size": "1x1",
                    "color": "primaryContainer"
                }
            },
            {
                "id": "mem",
                "label": "Memory bar",
                "tile": {
                    "type": "scalar",
                    "field": "mem",
                    "form": "bar",
                    "size": "2x1",
                    "color": "primaryContainer"
                }
            },
            {
                "id": "disk",
                "label": "Disk ring",
                "tile": {
                    "type": "scalar",
                    "field": "disk",
                    "form": "ring",
                    "size": "1x1",
                    "color": "tertiaryContainer"
                }
            },
            {
                "id": "load",
                "label": "Load",
                "tile": {
                    "type": "scalar",
                    "field": "load",
                    "form": "number",
                    "size": "1x1",
                    "color": "tertiaryContainer"
                }
            },
            {
                "id": "uptime",
                "label": "Uptime",
                "tile": {
                    "type": "scalar",
                    "field": "uptime",
                    "form": "number",
                    "size": "1x1",
                    "color": "primaryContainer"
                }
            },
            {
                "id": "packages",
                "label": "Packages",
                "tile": {
                    "type": "scalar",
                    "field": "package_count",
                    "form": "number",
                    "size": "1x1"
                }
            }
        ]
    }
];

function galleryEntry(id) {
    for (const group of galleryGroups) {
        const found = group.entries.find(e => e.id === id);
        if (found)
            return found;
    }
    return null;
}
