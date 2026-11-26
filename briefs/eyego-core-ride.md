# Run: core-ride. One complete ride, both phones, every screen on the way

Goal: prove a rider can book, a driver can take it, and both phones agree at every step,
through payment, rating and history. Check every control on each screen you pass.

**Already covered by the previous run — do NOT re-test or re-report:** sign-up details, the
where-to search tests, the Choose-your-ride layout on the SE, seat/doorstep pricing, the missing
payment picker, the terms gate, the DOB wheel, Create Trip under the tab bar, driver document
status. For scenarios 1-3 do only what is needed to get a ride requested (sign in/up, go online,
pick a destination, Economy), then spend the time on 4-12, which have never been reached.

## Scenarios (in order, update progress.md as you go)
1. **Setup.** Driver: sign in, look at Home before going online (empty states, earnings card,
   quests, notifications tab). Go online; confirm the UI clearly shows online. Rider: sign up.
   Rider Home: every rail, card and tab (Home, Services, Activity/Trips, Notifications, Account).
2. **Where to.** Rider: open where-to. Search by typing (a street, a landmark, a misspelling, a
   nonsense string), pick from results, set pickup by moving the map pin, use a saved-place slot
   (Home/Work) if offered. Swap pickup/destination. Check the pickup address text is a real street,
   not just "Accra".
3. **Choose your ride.** Every tier/option card: price, ETA, seats, what greys out and why. Open
   each detail. Change party size if offered and check the price changes sensibly. Payment picker
   on this screen: cash, wallet, MoMo, card.
4. **Request and dispatch.** Request **Economy** with cash (the seeded HiAce is an Economy vehicle; a Comfort or Premium request is not offered to it, which is correct). Rider: the searching state (cancel button present? **Speed matters here: an offer is live for 2 minutes and each phone command can take 1-2 min on this host, so you cannot catch it by hand. BEFORE tapping Request on the rider, run `bash scripts/eyego/phone.sh driver arm "Swipe to accept" 600`: it swipes the accept slider by itself the moment the offer shows. Then request, then check `cat results/$RUN/driver-arm.txt`. If an offer lapses, the same driver is offered again ~90 s later (3 lapses in a row auto-pauses the driver). Look the offer over on the second ride, without arming.**
   time shown?). Driver: the offer must appear: check pickup, destination, fare, distance, the
   countdown and both buttons. Accept.
5. **En route.** Drive the driver toward the rider at ~12 m/s. Rider: driver name, photo, plate,
   vehicle, rating, ETA counting down, map marker moving and facing the road, call/chat buttons.
   Driver: navigation/next-stop card, rider name, the swipe/advance control.
6. **Chat both ways.** Rider sends 2 messages, driver replies; check order, timestamps, unread
   badges on both, keyboard covering the input on the iPhone SE.
7. **Arrive and board.** Driver arrives (drive to the pickup). Rider: "driver arrived" state and the
   boarding PIN/code. Driver: enter a WRONG PIN first (must be refused clearly), then the right one.
   Start the trip.
8. **In progress.** Drive to the destination. Rider: live trip, ETA to destination, SOS button,
   share/track link (open it if it is a link: what does it show?). Driver: progress, drop-off.
9. **Complete and pay.** Driver completes. Both phones: fare shown must be identical and match the
   quote from step 3 (note every number). Rider: receipt, rate + tip flow (try a tip, try skipping).
   Driver: rate the passenger, earnings card updated by the right amount, commission shown.
10. **History.** Rider Activity/Trips and trip detail; driver Trips tab and trip detail. Same
    pickup, destination, fare, time, driver/rider on both. Notifications tabs on both.
11. **Second ride + wallet.** On-demand rides are cash-only by design today (not a finding). Top the
    rider wallet up through MoMo (mock auto-accepts) and check the balance moves by exactly the
    amount. Book and complete a second cash ride quickly; check the driver earnings and the
    commission move by the right amounts across both rides.
12. **Relaunch persistence.** `relaunch` both apps at Home: still signed in, driver still
    online (or clearly offline with a reason), last trip in history.

When all are done, use leftover budget on anything in the core path that looked fragile.
