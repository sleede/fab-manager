json.id plan.id
json.base_name plan.base_name
json.name plan.name
json.amount plan.amount ? (plan.amount / 100.0) : 0
json.interval plan.interval
json.interval_count plan.interval_count
json.training_credit_nb plan.training_credit_nb
json.training_credits plan.training_credits do |tc|
  json.training_id tc.creditable_id
end
json.machine_credits plan.machine_credits do |mc|
  json.machine_id mc.creditable_id
  json.hours mc.hours
end
