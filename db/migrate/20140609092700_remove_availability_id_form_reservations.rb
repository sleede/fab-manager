class RemoveAvailabilityIdFormReservations < ActiveRecord::Migration
  def change
    remove_column :reservations, :availability_id, :integer
  end
end
