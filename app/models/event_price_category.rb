class EventPriceCategory < ActiveRecord::Base
  belongs_to :event
  belongs_to :price_category

  has_many :tickets

  validates :price_category_id, presence: true
  validates :amount, presence: true
end
