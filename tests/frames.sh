#!/bin/sh
# Render every --ppm reference frame twice and check them all against
# tests/frames.sha256:
#   plain/   14 frames with no scores.dat, the state screenshots/*.png show
#   scores/  14 frames with the fixture scores.dat below, so the menu and the
#            title cards draw high scores (draw_number) and the load clamp runs
#
# Usage: sh tests/frames.sh [binary]            check (default build/encom-hits)
#        sh tests/frames.sh [binary] --update   rewrite the manifest after an
#                                               intended render change
#
# The game writes its frames to fixed /tmp/encom_*.ppm paths and reads
# scores.dat from the current directory, so each set renders in its own
# scratch directory and its frames are moved out before the next run.
set -eu

BIN=$(realpath "${1:-build/encom-hits}")
MODE=${2:-check}
MANIFEST=$(realpath tests/frames.sha256 2>/dev/null || echo "$PWD/tests/frames.sha256")
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Fixture high scores: six little-endian i64 slots, one per game.
#   Light Cycles 12345 and Grid Bugs 67890  together draw every digit 0-9
#   Battle Tanks 1000                        zeros inside a number
#   MCP Cone 2^40                            above the cap: clamped to 99999999
#   Interceptors -5                          negative: clamped to 0, not drawn
#   Disc Arena 99999999                      the 8-digit maximum, unclamped
write_fixture() {
    printf '\071\060\000\000\000\000\000\000' >  "$1"
    printf '\062\011\001\000\000\000\000\000' >> "$1"
    printf '\350\003\000\000\000\000\000\000' >> "$1"
    printf '\000\000\000\000\000\001\000\000' >> "$1"
    printf '\373\377\377\377\377\377\377\377' >> "$1"
    printf '\377\340\365\005\000\000\000\000' >> "$1"
}

render() {
    set=$1
    mkdir -p "$WORK/$set/run"
    rm -f /tmp/encom_*.ppm
    if [ "$set" = scores ]; then write_fixture "$WORK/$set/run/scores.dat"; fi
    (cd "$WORK/$set/run" && "$BIN" --ppm)
    mv /tmp/encom_*.ppm "$WORK/$set/"
    n=$(ls "$WORK/$set"/*.ppm | wc -l)
    [ "$n" -eq 14 ] || { echo "frames.sh: $set rendered $n frames, expected 14" >&2; exit 1; }
}

render plain
render scores

cd "$WORK"
if [ "$MODE" = --update ]; then
    sha256sum plain/*.ppm scores/*.ppm > "$MANIFEST"
    echo "frames.sh: wrote $(wc -l < "$MANIFEST") hashes to tests/frames.sha256"
    exit 0
fi
if sha256sum --quiet -c "$MANIFEST"; then
    echo "frames.sh: all $(wc -l < "$MANIFEST") frames match tests/frames.sha256"
else
    echo "frames.sh: rendered frames differ from tests/frames.sha256 (listed above)." >&2
    echo "If the change is intended, regenerate with: sh tests/frames.sh build/encom-hits --update" >&2
    exit 1
fi
