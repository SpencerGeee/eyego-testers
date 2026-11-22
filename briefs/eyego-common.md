# EyeGo: final QA before launch (rules for every run)

You are the last QA pass before EyeGo ships to the App Store and Google Play. EyeGo is a
"premium trotro" ride app in Accra, Ghana: riders book a whole ride or seats on a minibus,
drivers get dispatch offers, pick passengers up (boarding PIN), drive, and get paid. Cash,
wallet and MoMo. Prices are in Ghana cedis (GH₵).

The owner wants every bug, dead end, missing feature and niche edge case found. **Assume nothing
works until you have seen it work on screen.** A feature that "looks fine" but did nothing
(a button with no effect, a toast with no state change, a number that does not match the other
phone) is a bug. Comparing the two phones is your edge: what one phone does, the other must see.

## The two phones (both already booted, both apps open)
- `rider`: iPhone SE (3rd gen), 375x667 pt, the smallest supported screen. App `com.eyego.rider`.
- `driver`: iPhone 16 Pro. App `com.eyego.driver`.

## Tools (only this one, phone name always first)
```
bash scripts/eyego/phone.sh rider screen 07        # screenshot + element list -> results/$RUN/rider/07.png
bash scripts/eyego/phone.sh driver tap 200 640     # positions in points, read off the screenshot
bash scripts/eyego/phone.sh rider type "Osu Oxford Street"   # tap the field first
bash scripts/eyego/phone.sh driver scroll down | back | dismiss-sheet | enter | home | open | relaunch
bash scripts/eyego/phone.sh driver long-press X Y | swipe X1 Y1 X2 Y2
bash scripts/eyego/phone.sh driver drive 5.6220,-0.1735 15   # move the GPS smoothly to a point (m/s)
bash scripts/eyego/phone.sh rider gps 5.6037,-0.1870         # teleport
bash scripts/eyego/phone.sh rider theme dark | textsize accessibility-extra-extra-extra-large
```
Number screenshots per phone in order (01, 02...). Read every screenshot before the next action.
`type` pastes: if iOS asks to paste from "CoreSimulatorBridge", tap Allow Paste (that is the tool).

## Accounts and places
- **Driver** is seeded and approved: sign in with phone `240000001` (country code 233 is fixed in
  the app). The OTP is shown on the OTP screen in this test build. Vehicle: white Toyota HiAce, 14 seats.
- **Rider**: sign up in the app with phone `200000001`, name `Ama Owusu`. Sign-up itself is not
  under test: do it quickly, but still report anything broken you see on the way.
- Rider starts at Accra Mall (5.6220,-0.1735). Driver starts ~1.2 km away (5.6150,-0.1650).
  Useful destinations: Osu Oxford Street (5.5560,-0.1820), Kotoka Airport (5.6052,-0.1668),
  Makola Market (5.5480,-0.2090), East Legon A&C Mall (5.6380,-0.1590).
- Move the driver with `drive`, at road speed, toward the pickup and then the destination, so the
  rider phone shows a moving vehicle and a changing ETA. Teleporting is for setting up, not for trips.

## Known blocker, already filed (do not spend time on it)
The rider app crashes on a fresh install when the onboarding carousel changes slide with full
motion. The rider phone therefore has iOS **Reduce Motion ON**, so the app uses its reduced
onboarding. Swipe through all onboarding slides once by hand: if it still crashes, write that
down (it narrows the cause), `open` the app again and carry on. Everything else is under test.

## This test build (do not report these as bugs)
- Payments run on a mock gateway: MoMo is accepted automatically. A card checkout opens a dead
  `example.invalid` page on purpose. **Do** report what the app does when you close that page
  (stuck spinner, fake "paid", lost trip = bug).
- Photo/file uploads (profile photo, dispute or lost-item photos, chat images) have no storage
  account in this build, so the upload itself fails. Do not report that. **Do** report how the app
  handles it: a clear error and a way to continue = fine; a spinner forever, a silent "saved", a
  crash, or a form that cannot be submitted without the photo = bug.
- No real SMS and no push notifications (simulator). In-app banners and screens still must update.
- Backend is a fresh local server; it is fast. Slowness of more than ~5 s is worth noting.

## How to work
- One scenario at a time, from your run's brief. Each scenario: do it, check BOTH phones, record.
- A blocked step is a finding. Then try what a real user would (go back, retry, relaunch) to get
  past it, so the rest of the run is not lost. After 4 attempts, write it down and move on.
- Check every button, field, toggle, sheet, tab and link on every screen you reach, not just the
  main path. Empty states, error states, long text, back navigation, double taps.
- Layout on the iPhone SE matters: cut text, buttons under the home bar or keyboard, overlapping
  sheets. `screen.py` prints an accessibility check: confirm on the screenshot, report each kind once.
- When `screen` says the app is no longer running or a crash report appeared, that is a blocker:
  write it down with the last 3 actions, `open` the app and carry on.

## Write results AS YOU GO (usage limits can stop you at any moment)
Use the Write tool (the shell cannot write files). After EVERY new finding and after every
scenario, rewrite these two files in `results/$RUN/`:
1. `findings.json`:
   `{"run": "<RUN>", "issues": [{"id": 1, "title": "...", "severity": "blocker|major|minor|cosmetic", "kind": "bug|missing-feature|ux|layout|a11y", "app": "rider|driver|both", "screen": "...", "steps": "...", "actual": "...", "expected": "...", "screens": ["rider/14", "driver/09"]}]}`
2. `progress.md`: every scenario of your brief with `[x]` done, `[~]` partly, `[ ]` not reached.

At the very end also write `results/$RUN/report.md`: 10-line summary, the issues most severe
first, then "missing features" separately, then your honest verdict: could this ship today?
