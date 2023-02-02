json.array!(@notification_types) do |notification_type|
  json.extract! notification_type, :id, :name, :category, :is_configurable
end
