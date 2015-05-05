json.array!(@licences) do |licence|
  json.extract! licence, :id, :name, :description
  json.url licence_url(licence, format: :json)
end
