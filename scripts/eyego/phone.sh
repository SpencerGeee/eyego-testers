#!/usr/bin/env bash
# One agent, two phones. Every command names the phone first:
#   phone.sh rider|driver screen NN          screenshot + element list -> results/$RUN/<phone>/NN.png
#   phone.sh rider|driver tap X Y | long-press X Y | swipe X1 Y1 X2 Y2 | scroll down|up
#   phone.sh rider|driver back | dismiss-sheet | enter | home | open | relaunch | url URL
#   phone.sh rider|driver type "text"       (tap the field first)
#   phone.sh rider|driver gps LAT,LNG       teleport
#   phone.sh rider|driver drive LAT,LNG [m/s]   move smoothly from the last point (default 12 m/s)
#   phone.sh rider|driver arm "Swipe to accept" [SECS]   background: swipe/tap that control the moment it appears (log: results/$RUN/<phone>-arm.txt)
#   phone.sh rider|driver theme dark|light | textsize <category>   (e.g. accessibility-extra-extra-extra-large)
set -euo pipefail
WHO=${1:?rider or driver}; shift
case "$WHO" in rider) export APP_ID=com.eyego.rider ;; driver) export APP_ID=com.eyego.driver ;; *) echo "first arg: rider or driver"; exit 2 ;; esac
BASE_TMP=${EYEGO_TMP:?}
UDID=$(cat "$BASE_TMP/udid_$WHO"); export UDID
export RUNNER_TEMP="$BASE_TMP/$WHO"   # per-phone screen-size memo
mkdir -p "$RUNNER_TEMP"
LAST="$RUNNER_TEMP/last_gps"
cmd=${1:-}; shift || true
case "$cmd" in
  screen) python3 scripts/ios/screen.py "results/$RUN/$WHO" "${1:?NN}" ;;
  type) python3 scripts/ios/type.py "${1?text}" ;;
  gps) xcrun simctl location "$UDID" set "$1"; echo "$1" > "$LAST"; echo "gps: $1" ;;
  drive) from=$(cat "$LAST" 2>/dev/null || echo "$1")
         xcrun simctl location "$UDID" start --speed="${2:-12}" "$from" "$1"; echo "$1" > "$LAST"; echo "driving $from -> $1" ;;
  arm) WHO="$WHO" nohup python3 scripts/ios/arm.py "${1:?label}" "${2:-300}" "$PWD/results/$RUN/$WHO-arm.txt" >/dev/null 2>&1 &
       echo "armed '$1' on $WHO for ${2:-300} s (log: results/$RUN/$WHO-arm.txt)" ;;
  theme) xcrun simctl ui "$UDID" appearance "$1"; echo "theme: $1" ;;
  textsize) xcrun simctl ui "$UDID" content_size "$1"; echo "text size: $1" ;;
  open|relaunch)
    running() { xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$APP_ID"; }
    if [ "$cmd" = open ] && running; then bash scripts/ios/gesture.sh open; exit; fi
    running && { xcrun simctl terminate "$UDID" "$APP_ID" >/dev/null 2>&1 || true; }
    # Launch with the app's stdout/stderr captured for its whole life: an uncaught
    # JS error in a worklet prints "terminating ... JSError: <message>" + the JS
    # stack there before the abort (the .ips crash report never has it).
    # `simctl launch --stderr` streams until the app exits, so it stays in the background.
    ts=$(date +%H%M%S)
    nohup xcrun simctl launch --stdout="$PWD/results/$RUN/$WHO-stdout-$ts.txt" --stderr="$PWD/results/$RUN/$WHO-stderr-$ts.txt" \
      "$UDID" "$APP_ID" >/dev/null 2>&1 &
    for _ in $(seq 1 60); do running && { sleep 3; echo "done: $cmd"; exit 0; }; sleep 1; done
    echo "WARNING: the app did not start within 60 s"; exit 1 ;;
  *) bash scripts/ios/gesture.sh "$cmd" "$@" ;;
esac
