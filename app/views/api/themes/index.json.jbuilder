json.array!(@themes) do |theme|
  json.extract! theme, :id, :name
  
end
