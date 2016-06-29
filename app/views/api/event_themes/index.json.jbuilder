json.array!(@event_themes) do |theme|
  json.extract! theme, :id, :name
end
