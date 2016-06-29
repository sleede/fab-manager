json.array!(@age_ranges) do |ar|
  json.extract! ar, :id, :name
end
