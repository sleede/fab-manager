json.array!(@groups) do |group|
  json.id group.id
  json.name group.name
end
