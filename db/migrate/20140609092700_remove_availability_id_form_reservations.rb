# frozen_string_literal:true

class RemoveAvailabilityIdFormReservations < ActiveRecord::Migration[4.2]
  def change
    remove_column :reservations, :availability_id, :integer
  end
end
