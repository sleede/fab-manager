# frozen_string_literal: true

# A relation table between a pending event reservation and a special price for this event
class CreateCartItemEventReservationTicket < ActiveRecord::Migration[5.2]
  def change
    create_table :cart_item_event_reservation_tickets do |t|
      t.integer :booked
      t.references :event_price_category, foreign_key: true, index: { name: 'index_cart_item_tickets_on_event_price_category' }
      t.references :cart_item_event_reservation, foreign_key: true, index: { name: 'index_cart_item_tickets_on_cart_item_event_reservation' }

      t.timestamps
    end
  end
end
