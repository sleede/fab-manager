class Ticket < ActiveRecord::Base
  belongs_to :reservation
  belongs_to :event_price_category

  validates :reservation_id, presence: true
  validates :event_price_category_id, presence: true
  validates :booked, presence: true
  validates :booked, numericality: { only_integer: true, greater_than: 0 }
end
