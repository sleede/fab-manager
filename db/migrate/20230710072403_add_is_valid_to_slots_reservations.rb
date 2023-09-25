# frozen_string_literal: true

# add is_valid to slots_reservations
# remove validated_at from slots_reservations
class AddIsValidToSlotsReservations < ActiveRecord::Migration[7.0]
  def up
    add_column :slots_reservations, :is_valid, :boolean
    SlotsReservation.reset_column_information
    SlotsReservation.all.each do |sr|
      sr.update_column(:is_valid, true) if sr.validated_at.present?
    end
    remove_column :slots_reservations, :validated_at
  end

  def down
    remove_column :slots_reservations, :is_valid
    add_column :slots_reservations, :validated_at, :datetime
  end
end
