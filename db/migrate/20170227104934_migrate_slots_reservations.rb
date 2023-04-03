# frozen_string_literal:true

# From this migration, we migrate all reservation-related data from Slot to SlotReservation
class MigrateSlotsReservations < ActiveRecord::Migration[4.2]
  def up
    Slot.all.each do |slot|
      SlotsReservation.create!({ slot_id: slot.id, reservation_id: slot.reservation_id })
    end
  end

  def down
    SlotsReservation.all.each do |sr|
      Slot.find(sr.slot_id).update(reservation_id: sr.reservation_id)
    end
  end
end
