class EventPriceCategory < ActiveRecord::Base
  belongs_to :event
  belongs_to :price_category

  validates :event_id, presence: true
  validates :price_category_id, presence: true
  validates :amount, presence: true
end
