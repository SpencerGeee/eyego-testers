# Run: things-wrong. Everything that can go wrong during a ride

Goal: every unhappy path leaves both phones in a correct, consistent, recoverable state. After each
scenario check BOTH phones: no ghost trip card, no stuck spinner, driver back in the dispatch pool,
rider can book again, history shows what really happened, money moved only if it should.
Do one quick normal booking first (sign in, go online, book, accept, complete) so you know the
happy path works on this build, then:

## Scenarios
1. **Rider cancels while searching** (before any driver accepts). Driver phone: the offer must disappear.
2. **Driver passes on the offer.** Rider: what happens (keeps searching? "no drivers"? stuck?).
3. **Driver lets the offer time out** (do nothing until the countdown ends). Then is the same
   rider's next request offered to this driver again? Report what you see.
4. **Rider cancels after accept, driver en route.** Reason picker, any cancellation fee shown and
   whether it is fair, driver phone told immediately, both screens back to home.
5. **Driver cancels after accept.** Reason picker; rider informed clearly; does the rider get
   re-dispatched or sent home? Driver back online?
6. **Rider no-show.** Driver arrives and waits; find the no-show/wait timer and use it. Rider phone:
   what is shown? Any fee?
7. **Wrong PIN, repeatedly.** 3+ wrong boarding PINs: lockout? message? can the right PIN still work?
8. **Rider cancels mid-trip** (after boarding) if the app allows it; otherwise note that it does not.
9. **SOS.** Rider SOS mid-trip: every option on the screen, emergency contacts flow (add a contact
   if asked), what the driver phone sees (should NOT alarm the driver in a way that endangers the
   rider). Driver-side safety/SOS screen too. Cancel the SOS: is it really cleared?
10. **Report and dispute.** After a completed trip: rider dispute (fare wrong), driver report on a
    passenger, lost item flow from both sides. Do they submit, and is there a visible status after?
11. **App killed mid-trip.** `relaunch` the rider app during en route, then the driver app during
    the trip. Each must come back to the live trip, not home, with the right state.
12. **Driver goes offline with an offer showing / mid-trip.** Is going offline blocked mid-trip?
13. **Bad input everywhere.** Destination = pickup, a destination outside Ghana (e.g. type "Lagos"),
    an empty search, a 200-character chat message, emoji in names and chat, double-tapping Request
    and Accept (duplicate trips?), rapid back taps during transitions.
14. **Location jumps.** Teleport the driver far away (5.6037,-0.1870 then 6.6885,-1.6244 Kumasi)
    mid en-route. Teleport the rider while searching. What do ETAs and maps show?

Use leftover budget to retry anything that left a phone in a weird state.
