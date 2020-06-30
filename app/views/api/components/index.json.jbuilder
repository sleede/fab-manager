json.array!(@components) do |component|
  json.extract! component, :id, :name

end
