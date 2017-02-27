class MigrateSlotsReservations < ActiveRecord::Migration
  def up
    Slot.all.each do |slot|
      SlotsReservation.create!({slot_id: slot.id, reservation_id: slot.reservation_id})
    end
  end

  def down
    SlotsReservation.all.each do |sr|
      Slot.find(sr.slot_id).update_attributes(:availability_id => sr.availability_id)
    end
  end
end
