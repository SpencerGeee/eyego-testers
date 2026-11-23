# Run: core-ride. One complete ride, both phones, every screen on the way

Goal: prove a rider can book, a driver can take it, and both phones agree at every step,
through payment, rating and history. Check every control on each screen you pass.

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
4. **Request and dispatch.** Request **Economy** with cash (the seeded HiAce is an Economy vehicle; a Comfort or Premium request is not offered to it, which is correct). Rider: the searching state (cancel button present? **Speed matters here: an offer is live for 2 minutes and each phone command takes 10-60 s. When the request appears on the driver, tap it, take ONE screen, tap Accept. Look the offer over only after accepting (or on the second ride).**
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
11. **Second ride, different payment.** Book again paying with wallet (and MoMo if wallet is empty:
    top up through MoMo first if the app offers it). Complete it quickly. Check the wallet balance
    moves by exactly the fare on the rider and the driver earnings move accordingly.
12. **Relaunch persistence.** `relaunch` both apps at Home: still signed in, driver still
    online (or clearly offline with a reason), last trip in history.

When all are done, use leftover budget on anything in the core path that looked fragile.
