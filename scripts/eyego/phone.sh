#!/usr/bin/env bash
# One agent, two phones. Every command names the phone first:
#   phone.sh rider|driver screen NN          screenshot + element list -> results/$RUN/<phone>/NN.png
#   phone.sh rider|driver tap X Y | long-press X Y | swipe X1 Y1 X2 Y2 | scroll down|up
#   phone.sh rider|driver back | dismiss-sheet | enter | home | open | relaunch | url URL
#   phone.sh rider|driver type "text"       (tap the field first)
#   phone.sh rider|driver gps LAT,LNG       teleport
#   phone.sh rider|driver drive LAT,LNG [m/s]   move smoothly from the last point (default 12 m/s)
#   phone.sh rider|driver theme dark|light | textsize <category>   (e.g. accessibility-extra-extra-extra-large)
set -euo pipefail
WHO=${1:?rider or driver}; shift
case "$WHO" in rider) export APP_ID=com.eyego.rider ;; driver) export APP_ID=com.eyego.driver ;; *) echo "first arg: rider or driver"; exit 2 ;; esac
BASE_TMP=${EYEGO_TMP:?}
export UDID=$(cat "$BASE_TMP/udid_$WHO")
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
  theme) xcrun simctl ui "$UDID" appearance "$1"; echo "theme: $1" ;;
  textsize) xcrun simctl ui "$UDID" content_size "$1"; echo "text size: $1" ;;
  *) bash scripts/ios/gesture.sh "$cmd" "$@" ;;
esac
