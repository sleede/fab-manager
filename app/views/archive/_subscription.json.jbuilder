# frozen_string_literal: true

json.extract! invoiced, :stp_subscription_id, :created_at, :expiration_date, :canceled_at
json.plan do
  json.extract! invoiced.plan, :id, :base_name, :interval, :interval_count, :stp_plan_id, :is_rolling
  json.group do
    json.extract! invoiced.plan.group, :id, :name
  end
end
