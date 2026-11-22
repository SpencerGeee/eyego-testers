# Run: group. Seats, group bookings, joining a bus, scheduled and reserved rides

Goal: the minibus side of EyeGo works end to end on both phones: seats are counted correctly
(seats, not bookings), prices make sense per seat and per segment, and shared links work.
Sign in both phones first (see common brief), driver online.

## Scenarios
1. **Driver creates a trip.** Driver: create-trip flow (location picker for start/end/stops,
   departure time, seats, price if asked). Every field and validation (past time, 0 seats, same
   start and end). Publish. Check it in the driver Trips tab.
2. **Rider finds and books seats.** Rider: browse/services to find that trip (browse by group or
   route if offered). Seat map / seat selection: pick 2 seats, check the price is per seat and the
   total is right, guest selection (book for someone else / add a guest's name and phone).
   Pay cash. Driver phone: seat count drops by 2 (not 1), passenger list shows the booking.
3. **Invite and join links.** Rider: invite/share from the booking. Open the shared link with
   `url` on the rider phone (join/[token], track/[shortId]): what does it show? Does joining add a
   seat? Is a used or bad token handled (change a character in the link)?
4. **Driver adds a walk-up passenger** (add-passenger) and boards everyone (party boarding / PINs).
   Seats left must stay correct on both phones.
5. **Join a moving bus / segment pricing.** If the app offers booking a bus already on its way, book
   a seat for only part of the route (board at a middle stop). Price must be lower than the full
   route. Driver: stop timeline shows pick up/drop off per stop.
6. **Run the trip.** Drive through the stops; at each stop the driver marks pick-up/drop-off; rider
   phone follows. Complete. Both phones: fare per passenger and total identical. Rate.
7. **Seat edge cases.** Try to book more seats than are left; cancel 1 of 2 seats if possible (seat
   returns to the pool on the driver phone?); book seats on a trip that is full.
8. **Scheduled ride.** Rider: schedule a ride for tomorrow 07:30 (ride/schedule), check it in
   scheduled-rides and its detail page, edit time if possible, cancel one. Try a time in the past,
   and 2 minutes from now. Driver: does a scheduled request appear, and where (Trips/notifications)?
   Accept it if offered; start it (Start Trip should exist only for scheduled trips).
9. **Reserve.** Rider: ride/reserve flow, every option, confirm, then find it again and cancel.
10. **Hold expiry.** Start a seat booking and stop on the payment step for a few minutes: does the
    seat hold expire visibly, and is the seat back on the driver phone?

Use leftover budget on anything in seats/scheduling that looked inconsistent between the phones.
