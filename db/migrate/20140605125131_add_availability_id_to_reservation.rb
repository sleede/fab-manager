class AddAvailabilityIdToReservation < ActiveRecord::Migration
  def change
    add_column :reservations, :availability_id, :integer
    add_index :reservations, :availability_id
  end
end
