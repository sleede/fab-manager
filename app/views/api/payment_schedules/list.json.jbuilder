# frozen_string_literal: true

json.array! @payment_schedules do |ps|
  json.extract! ps, :id, :reference, :created_at, :payment_method
  json.total ps.total / 100.00
  json.chained_footprint ps.check_footprint
  json.user do
    json.name ps.invoicing_profile.full_name
  end
  if ps.operator_profile
    json.operator do
      json.id ps.operator_profile.user_id
      json.extract! ps.operator_profile, :first_name, :last_name
    end
  end
  json.items ps.payment_schedule_items do |item|
    json.extract! item, :id, :due_date, :state, :invoice_id, :payment_method
    json.amount item.amount / 100.00
  end
end
