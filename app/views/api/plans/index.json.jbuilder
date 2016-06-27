json.array!(@plans) do |plan|
  json.extract! plan, :id, :base_name, :name, :interval, :interval_count, :group_id, :training_credit_nb, :description, :type, :ui_weight
  json.amount (plan.amount / 100.00)
  json.plan_file_url plan.plan_file.attachment_url if plan.plan_file
end
