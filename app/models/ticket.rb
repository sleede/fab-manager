# frozen_string_literal: true

# Ticket is an reservation of a member for an Event, with a specific PriceCategory
# For example, Member John Smith smith has book 2 places on Event "Arduino initiation" at price "reduces fare"
class Ticket < ApplicationRecord
  belongs_to :reservation
  belongs_to :event_price_category

  validates :event_price_category_id, presence: true
  validates :booked, presence: true
  validates :booked, numericality: { only_integer: true, greater_than: 0 }
end
