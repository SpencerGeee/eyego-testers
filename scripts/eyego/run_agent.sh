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
  # Optional Reduce Motion on the rider (REDUCE_MOTION_RIDER=1), e.g. to test the
  # reduced-motion paths. Off by default: the real app runs full motion.
  [ "$who" = rider ] && [ "${REDUCE_MOTION_RIDER:-0}" = 1 ] && d com.apple.Accessibility ReduceMotionEnabled -bool YES
  xcrun simctl shutdown "$udid" && xcrun simctl boot "$udid" && xcrun simctl bootstatus "$udid" -b >/dev/null
  # Unsigned build (ad-hoc signing hung simctl launch in 3 of 4 runs): no Keychain
  # on the simulator, so SecureStore cannot persist a session across relaunches.
  xcrun simctl install "$udid" "$(find "app/$who" -maxdepth 2 -name '*.app' -type d | head -1)" || { echo "install $who failed"; exit 1; }
  # App + RN + worklets logs.
  xcrun simctl spawn "$udid" log stream --style compact --level debug \
    --predicate 'processImagePath CONTAINS "EyeGo"' > "results/$RUN/$who-syslog.txt" 2>&1 &
  bash scripts/eyego/phone.sh "$who" gps "$3"
  bash scripts/eyego/phone.sh "$who" relaunch | tee -a "results/$RUN/launch.txt"
}
# Accra. Rider at Accra Mall, driver ~1.2 km away on the Spintex road side.
# Both at once: a fresh simulator takes ~8 min to boot twice on the runner.
boot rider "iPhone SE (3rd generation)" 5.6220,-0.1735 & r=$!
boot driver "iPhone 16 Pro" 5.6150,-0.1650 & d=$!
wait "$r" "$d"   # only the two boots (their log streams keep running)
echo "both phones up at $(date +%T)"
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
  # Rider: page through the onboarding by hand, then check it is still alive.
  for _ in 1 2 3 4 5; do bash scripts/eyego/phone.sh rider swipe 330 330 40 330 >/dev/null 2>&1; sleep 3; done
  for w in rider driver; do
    xcrun simctl spawn "$(cat "$EYEGO_TMP/udid_$w")" launchctl list | grep -q "com.eyego.$w" \
      && echo "$w: alive after ~70 s" | tee -a "results/$RUN/launch.txt" \
      || echo "$w: DEAD after ~70 s" | tee -a "results/$RUN/launch.txt"
    bash scripts/eyego/phone.sh $w screen 01 >/dev/null 2>&1 || echo "screen $w 01 failed"
    bash scripts/eyego/phone.sh $w relaunch | tee -a "results/$RUN/launch.txt"; sleep 15
    bash scripts/eyego/phone.sh $w screen 02 >/dev/null 2>&1 || echo "screen $w 02 failed"
  done
  # Speed bench: core-ride saw 2-20 min per agent screenshot. Time each tool piece.
  t() { local s; s=$(date +%s); "$@" >/dev/null 2>&1; echo "$(( $(date +%s) - s ))s"; }
  bench() {
    for w in rider driver; do
      u=$(cat "$EYEGO_TMP/udid_$w")
      echo "$1 $w: screen $(t bash scripts/eyego/phone.sh $w screen 90) | shot $(t xcrun simctl io "$u" screenshot /tmp/b.png) | describe $(t axe describe-ui --udid "$u") | tap $(t axe tap -x 5 -y 5 --udid "$u") | launchctl $(t xcrun simctl spawn "$u" launchctl list)"
    done
    uptime; top -l 2 -n 6 -o cpu -stats command,cpu,mem | tail -7
  }
  bench "with-logstream" | tee -a "results/$RUN/launch.txt"
  pkill -f "log stream" || true; sleep 20
  bench "no-logstream" | tee -a "results/$RUN/launch.txt"
  collect_crashes; exit 0
fi

claude -p "Read briefs/eyego-common.md, then briefs/eyego-$RUN.md, and do the whole mission. RUN=$RUN. Both simulators are booted and both apps are open. Use only scripts/eyego/phone.sh." \
  --model "${MODEL:-opus}" --max-turns 1500 --output-format json \
  --allowedTools "Bash(bash scripts/eyego/phone.sh:*),Bash(sleep:*),Bash(ls:*),Bash(cat:*),Read,Write,Edit" \
  > "results/$RUN/agent-output.json" 2> "results/$RUN/agent-errors.txt"
echo "Agent finished (exit $?): $(ls results/$RUN/rider | wc -l) rider + $(ls results/$RUN/driver | wc -l) driver files"
collect_crashes
