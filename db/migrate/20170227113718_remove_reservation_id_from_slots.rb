class RemoveReservationIdFromSlots < ActiveRecord::Migration
  def change
    remove_column :slots, :reservation_id, :integer
  end
end
