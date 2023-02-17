json.array!(@notification_preferences) do |notification_preference|
  json.extract! notification_preference, :id, :notification_type, :in_system, :email
end
