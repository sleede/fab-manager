# frozen_string_literal:true

class AddAvailabilityIdToReservation < ActiveRecord::Migration[4.2]
  def change
    add_column :reservations, :availability_id, :integer
    add_index :reservations, :availability_id
  end
end
