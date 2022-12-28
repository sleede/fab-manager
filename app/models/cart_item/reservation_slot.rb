# frozen_string_literal: true

# A relation table between a pending reservation and a slot
class CartItem::ReservationSlot < ApplicationRecord
  belongs_to :cart_item, polymorphic: true

  belongs_to :slot
  belongs_to :slots_reservation
end
