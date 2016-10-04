user_is_admin = (current_user and current_user.is_admin?)

json.array!(@age_ranges) do |ar|
  json.extract! ar, :id, :name
  json.related_to ar.events.count if user_is_admin
end
