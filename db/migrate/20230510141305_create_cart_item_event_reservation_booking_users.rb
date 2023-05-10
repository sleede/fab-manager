# frozen_string_literal: true

# A relation table between a pending event reservation and reservation users for this event
class CreateCartItemEventReservationBookingUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :cart_item_event_reservation_booking_users do |t|
      t.string :name
      t.belongs_to :cart_item_event_reservation, foreign_key: true, index: { name: 'index_cart_item_booking_users_on_cart_item_event_reservation' }
      t.references :event_price_category, foreign_key: true, index: { name: 'index_cart_item_booking_users_on_event_price_category' }
      t.references :booked, polymorphic: true

      t.timestamps
    end
  end
end
