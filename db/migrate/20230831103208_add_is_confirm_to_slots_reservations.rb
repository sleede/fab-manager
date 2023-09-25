# frozen_string_literal: true

# add is_confirm to slots_reservations
class AddIsConfirmToSlotsReservations < ActiveRecord::Migration[7.0]
  def up
    add_column :slots_reservations, :is_confirm, :boolean
    SlotsReservation.reset_column_information
    SlotsReservation.all.each do |sr|
      sr.update_column(:is_confirm, true) if sr.is_valid && sr.reservation.invoice_items.count.positive?
    end
  end

  def down
    remove_column :slots_reservations, :is_confirm
  end
end
