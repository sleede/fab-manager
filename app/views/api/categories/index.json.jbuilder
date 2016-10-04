user_is_admin = (current_user and current_user.is_admin?)

json.array!(@categories) do |category|
  json.extract! category, :id, :name
  json.related_to category.events.count if user_is_admin
end
