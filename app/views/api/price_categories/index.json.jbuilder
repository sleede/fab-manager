user_is_admin = (current_user and current_user.is_admin?)

json.array!(@price_categories) do |category|
  json.extract! category, :id, :name, :conditions
  json.events category.event_price_category.count if user_is_admin
end
