class AddReservationContextIdToReservation < ActiveRecord::Migration[7.0]
  def change
    add_reference :reservations, :reservation_context, index: true, foreign_key: true
  end
end
