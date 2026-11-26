"""Wait in the background for a control to appear, then act on it at once.
Usage: python3 scripts/ios/arm.py "<label prefix>" <seconds> <log>
A slow host made every agent screenshot+tap take 1-3 min, longer than the
120 s dispatch offer, so no ride was ever accepted. This polls the a11y tree
and swipes (accessibilityHint 'Swipe ...') or taps the first match itself."""
import json, os, subprocess, sys, time

UDID = os.environ["UDID"]
want, secs, log = sys.argv[1].lower(), float(sys.argv[2]), sys.argv[3]


def find(n):
    if isinstance(n, list):
        for c in n:
            hit = find(c)
            if hit:
                return hit
    elif isinstance(n, dict):
        label = (n.get("AXLabel") or n.get("title") or "").strip().lower()
        if label.startswith(want) and n.get("frame"):
            return n
        return find(n.get("children") or [])
    return None


def say(msg):
    with open(log, "a") as fh:
        fh.write(f"{time.strftime('%H:%M:%S')} {msg}\n")


end = time.time() + secs
say(f"armed: '{want}' for {int(secs)} s")
while time.time() < end:
    try:
        tree = json.loads(subprocess.run(["axe", "describe-ui", "--udid", UDID],
                                         capture_output=True, text=True, timeout=90).stdout)
    except (json.JSONDecodeError, subprocess.TimeoutExpired):
        continue
    n = find(tree)
    if not n:
        time.sleep(2)
        continue
    f = n["frame"]
    x, y, w, h = f["x"], f["y"], f["width"], f["height"]
    cy = round(y + h / 2)
    if "swipe" in (n.get("AXHint") or n.get("help") or "swipe").lower():
        cmd = ["axe", "swipe", "--start-x", str(round(x + 8)), "--start-y", str(cy),
               "--end-x", str(round(x + w - 4)), "--end-y", str(cy), "--duration", "0.6"]
    else:
        cmd = ["axe", "tap", "-x", str(round(x + w / 2)), "-y", str(cy)]
    subprocess.run(cmd + ["--udid", UDID], capture_output=True, timeout=90)
    say(f"acted on '{n.get('AXLabel')}' at {x:.0f},{cy} ({w:.0f}x{h:.0f}): {' '.join(cmd[:2])}")
    sys.exit(0)
say("timed out: never appeared")
