json.array!(@licences) do |licence|
  json.extract! licence, :id, :name, :description
  
end
