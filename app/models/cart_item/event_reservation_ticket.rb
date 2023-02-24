# frozen_string_literal: true

# A relation table between a pending event reservation and a special price for this event
class CartItem::EventReservationTicket < ApplicationRecord
  self.table_name = 'cart_item_event_reservation_tickets'

  belongs_to :cart_item_event_reservation, class_name: 'CartItem::EventReservation', inverse_of: :cart_item_event_reservation_tickets
  belongs_to :event_price_category, inverse_of: :cart_item_event_reservation_tickets
end
