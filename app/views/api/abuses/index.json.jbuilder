json.abuses do
  json.array!(@abuses) do |abuse|
    json.extract! abuse, :id, :signaled_id, :signaled_type
  end
end
