json.array!(@price_categories) do |category|
  json.extract! category, :id, :name
  json.events category.event_price_category.count
end
