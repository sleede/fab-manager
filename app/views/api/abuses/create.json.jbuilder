json.reporting do
  json.extract! @abuse, :id, :signaled_id, :signaled_type
end
