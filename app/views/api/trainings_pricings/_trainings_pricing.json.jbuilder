json.extract! trainings_pricing, :id, :group_id, :training_id
json.amount trainings_pricing.amount / 100.0
json.training do
  json.name trainings_pricing.training.name
end
