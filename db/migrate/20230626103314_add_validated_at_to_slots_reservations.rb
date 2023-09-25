# frozen_string_literal: true

# add validated_at to slots_reservations
class AddValidatedAtToSlotsReservations < ActiveRecord::Migration[7.0]
  def change
    add_column :slots_reservations, :validated_at, :datetime
  end
end
