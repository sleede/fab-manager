class AddReservationContextIdToCartItemReservations < ActiveRecord::Migration[7.0]
  def change
    add_reference :cart_item_reservations, :reservation_context, foreign_key: true
  end
end
