class EventPriceCategory < ActiveRecord::Base
  belongs_to :event
  belongs_to :price_category
end
