user_is_admin = (current_user and current_user.is_admin?)

json.array!(@event_themes) do |theme|
  json.extract! theme, :id, :name
  json.related_to theme.events.count if user_is_admin
end
