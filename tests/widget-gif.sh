#!/usr/bin/env bash
#   tests/widget-gif.sh [-x shell_repo] [-n frames] [-o outfile]
set -u

DIR="$(cd "$(dirname "$0")/.." && pwd)"
SHELL_REPO="${II_SHELL_REPO:-$HOME/Projects/dots-hyprland-extensions}"
[ -d "$SHELL_REPO" ] || SHELL_REPO="$HOME/Projects/dots-hyprland" # Cloned under the old name
FRAMES=40
OUT="$DIR/docs/weather.gif"

while getopts "x:n:o:" flag; do
    case "$flag" in
        x) SHELL_REPO=$OPTARG ;;
        n) FRAMES=$OPTARG ;;
        o) OUT=$OPTARG ;;
    esac
done

[ -x "$SHELL_REPO/tests/widget-shots.sh" ] || { echo "no shell checkout at $SHELL_REPO, set II_SHELL_REPO"; exit 2; }
command -v ffmpeg > /dev/null || { echo "ffmpeg not found"; exit 2; }

FRAMEDIR="$DIR/unsynced/gif-frames"
rm -rf "$FRAMEDIR"
mkdir -p "$FRAMEDIR" "$(dirname "$OUT")"

# Statusphere.ingest coalesces for 250ms before it takes - stay well clear, and hold it
# constant so settling is not one more thing that varies between frames.
SETTLE=700

for ((i = 0; i < FRAMES; i++)); do
    name=$(printf "frame-%02d" "$i")
    "$SHELL_REPO/tests/widget-shots.sh" -x "$DIR" -d "$FRAMEDIR" -- \
        "-f demo/DemoWeatherGif.qml -n $name -p frame=$i -g 800x220 -s $SETTLE" > /dev/null || exit 1
done

ffmpeg -y -framerate 10 -i "$FRAMEDIR/frame-%02d.png" \
    -filter_complex "[0:v] scale=1000:-2 [scaled]; [scaled] split [a][b]; [a] palettegen [p]; [b][p] paletteuse" \
    -loop 0 "$OUT" < /dev/null

echo "gif ok   $OUT ($(du -h "$OUT" | cut -f1))"
