#!/usr/bin/env bash
# Two simulators (rider + driver), both apps installed, one Claude agent.
# Needs: RUN, MODEL, EYEGO_TMP, apps unzipped in app/rider and app/driver, API up.
set -uo pipefail
mkdir -p "results/$RUN/rider" "results/$RUN/driver"
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false

boot() {  # boot <who> <model> <lat,lng>
  local who=$1 udid
  udid=$(python3 scripts/ios/create_sim.py "$2" 18 | grep '^UDID=' | cut -d= -f2)
  echo "$udid" > "$EYEGO_TMP/udid_$who"
  xcrun simctl boot "$udid" && xcrun simctl bootstatus "$udid" -b >/dev/null
  d() { xcrun simctl spawn "$udid" defaults write "$@"; }
  d -g AppleLanguages -array en-GH en; d -g AppleLocale -string en_GH
  d -g AppleKeyboards -array "en_US@sw=QWERTY;hw=US"
  for k in KeyboardAutocapitalization KeyboardAutocorrection KeyboardPrediction KeyboardCheckSpelling; do d com.apple.Preferences $k -bool NO; done
  for k in DidShowContinuousPathIntroduction KeyboardDidShowProductivityTutorial DidShowGestureKeyboardIntroduction; do
    d com.apple.Preferences $k -bool YES; d com.apple.keyboard.preferences $k -bool YES
  done
  xcrun simctl shutdown "$udid" && xcrun simctl boot "$udid" && xcrun simctl bootstatus "$udid" -b >/dev/null
  local app; app=$(find "app/$who" -maxdepth 2 -name '*.app' -type d | head -1)
  # The build is unsigned; an unsigned simulator app gets no Keychain (SecureStore
  # fails with -34018, so every relaunch looks signed out). Ad-hoc sign it.
  codesign --force --deep --sign - "$app" >/dev/null 2>&1 || echo "codesign $who failed"
  xcrun simctl install "$udid" "$app" || { echo "install $who failed"; exit 1; }
  # App + RN + worklets logs: the JS error behind any crash lands here.
  xcrun simctl spawn "$udid" log stream --style compact --level debug \
    --predicate 'processImagePath CONTAINS "EyeGo"' > "results/$RUN/$who-syslog.txt" 2>&1 &
  bash scripts/eyego/phone.sh "$who" gps "$3"
  xcrun simctl launch "$udid" "com.eyego.$who"
}
# Accra. Rider at Accra Mall, driver ~1.2 km away on the Spintex road side.
boot rider "iPhone SE (3rd generation)" 5.6220,-0.1735
boot driver "iPhone 16 Pro" 5.6150,-0.1650
sleep 10
for w in rider driver; do bash scripts/eyego/phone.sh $w screen 00 >/dev/null 2>&1 || true; done  # size memos

collect_crashes() {
  mkdir -p "results/$RUN/crashes"
  find ~/Library/Logs/DiagnosticReports -name '*.ips' -newer "$EYEGO_TMP/udid_rider" -exec cp {} "results/$RUN/crashes/" \; 2>/dev/null
  echo "crash reports: $(ls "results/$RUN/crashes" | wc -l)"
}

# smoke: launch both apps, look, collect logs. No agent, no Claude usage.
if [ "$RUN" = smoke ]; then
  sleep 50
  for w in rider driver; do bash scripts/eyego/phone.sh $w screen 01 >/dev/null 2>&1; bash scripts/eyego/phone.sh $w relaunch; sleep 20; bash scripts/eyego/phone.sh $w screen 02 >/dev/null 2>&1; done
  collect_crashes; exit 0
fi

claude -p "Read briefs/eyego-common.md, then briefs/eyego-$RUN.md, and do the whole mission. RUN=$RUN. Both simulators are booted and both apps are open. Use only scripts/eyego/phone.sh." \
  --model "${MODEL:-opus}" --max-turns 1500 --output-format json \
  --allowedTools "Bash(bash scripts/eyego/phone.sh:*),Bash(sleep:*),Bash(ls:*),Bash(cat:*),Read,Write,Edit" \
  > "results/$RUN/agent-output.json" 2> "results/$RUN/agent-errors.txt"
echo "Agent finished (exit $?): $(ls results/$RUN/rider | wc -l) rider + $(ls results/$RUN/driver | wc -l) driver files"
collect_crashes
