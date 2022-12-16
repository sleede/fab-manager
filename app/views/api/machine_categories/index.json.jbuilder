json.array!(@machine_categories) do |category|
  json.extract! category, :id, :name, :machine_ids
end
