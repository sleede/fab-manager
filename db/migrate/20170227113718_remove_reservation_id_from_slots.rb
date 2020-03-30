# frozen_string_literal:true

class RemoveReservationIdFromSlots < ActiveRecord::Migration[4.2]
  def change
    remove_column :slots, :reservation_id, :integer
  end
end
