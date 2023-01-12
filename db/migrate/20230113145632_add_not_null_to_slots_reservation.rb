# frozen_string_literal: true

# From this migration, the slot_id and reservation_id of the SlotsReservation won't be allowed to be null,
# otherwise this could result in error
class AddNotNullToSlotsReservation < ActiveRecord::Migration[5.2]
  def change
    change_column_null :slots_reservations, :slot_id, false
    change_column_null :slots_reservations, :reservation_id, false
    change_column_null :slots, :availability_id, false
  end
end
