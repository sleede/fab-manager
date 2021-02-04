# frozen_string_literal: true

max_schedules = @payment_schedules.except(:offset, :limit, :order).count

json.array! @payment_schedules do |ps|
  json.max_length max_schedules
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
    json.client_secret item.payment_intent.client_secret if item.stp_invoice_id && item.state == 'requires_action'
  end
end
