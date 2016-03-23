json.array!(@plans) do |plan|
  json.id plan.id
  json.ui_weight plan.ui_weight
  json.group_id plan.group_id
  json.base_name plan.base_name
  json.amount plan.amount / 100.0
  json.interval plan.interval
  json.interval_count plan.interval_count
  json.type plan.type
  json.plan_file_url plan.plan_file.attachment_url if plan.plan_file
end
