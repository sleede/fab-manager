# Availabilities-reservations data models

## Machines

ONE Availability may have:
- MANY MachinesAvailability (=> MANY Machines)
- MANY Slot: the Availability is cut in smaller slots

ONE Slot may have:
- ONE Availability: a Slot is a slice of ONE Availability
- MANY SlotsReservation: ONE SlotsReservation per (User + Machine + Slot)
  - Bob reserved a 3D printer from 8am to 9am in Availability 1 (=> ONE SlotsReservation)
  - John reserved a Laser cutter from 8am to 9am in Availability 1 (=> ONE SlotsReservation)

ONE SlotsReservation have:
- ONE Slot
- ONE Reservation

ONE Reservation may have:
- MANY SlotsReservation (one per reserved slot, for the associated Machine)
- ONE User
- ONE Machine
- NO Ticket

## Spaces

ONE Availability may have:
- ONE SpacesAvailability (=> ONE Space)
- MANY Slot: the Availability is cut in smaller slots

ONE Slot may have:
- ONE Availability: a Slot is a slice of ONE Availability
- MANY SlotsReservation: ONE SlotsReservation per (User + Slot)
    - Bob reserved from 8am to 9am (=> ONE SlotsReservation)
    - John reserved from 8am to 9am (=> ONE SlotsReservation)

ONE SlotsReservation have:
- ONE Slot
- ONE Reservation

ONE Reservation may have:
- MANY SlotsReservation (one per reserved slot, for the associated Space)
- ONE User
- ONE Space
- NO Ticket

## Trainings

ONE Availability may have:
- ONE TrainingsAvailability (=> ONE Training)
- ONE Slot: the Availability isn't cut into smaller slots

ONE Slot may have:
- ONE Availability: a Slot as long as the Availability
- MANY SlotsReservation: ONE SlotsReservation per User
  - Bob reserved (=> ONE SlotsReservation)
  - John reserved (=> ONE SlotsReservation)

ONE SlotsReservation have:
- ONE Slot
- ONE Reservation

ONE Reservation have:
- ONE SlotsReservation
- ONE User
- ONE Training
- NO Tickets

## Events

ONE Availability may have:
- ONE Event (from Event.availability_id)
- ONE Slot: the Availability isn't cut into smaller slots

ONE Slot may have:
- ONE Availability: a Slot as long as the Availability
- MANY SlotsReservation: ONE SlotsReservation per User
  - Bob reserved (=> ONE SlotsReservation)
  - John reserved (=> ONE SlotsReservation)

ONE SlotsReservation have:
- ONE Slot
- ONE Reservation

ONE Reservation may have:
- ONE SlotsReservation
- ONE User
- ONE Training
- MANY Tickets (once per extra booked special price)
