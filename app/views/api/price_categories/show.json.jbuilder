json.extract! @price_category, :id, :name, :conditions, :created_at
json.events @price_category.event_price_category.count