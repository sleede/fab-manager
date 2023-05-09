# frozen_string_literal: true

# BookingUser is a class for save the booking info of reservation
# booked can be a User or a Child (polymorphic)
class BookingUser < ApplicationRecord
  belongs_to :reservation
  belongs_to :booked, polymorphic: true
  belongs_to :event_price_category
end
