# frozen_string_literal: true

json.extract! payment_schedule, :id, :reference, :created_at, :payment_method
json.total payment_schedule.total / 100.00
json.chained_footprint payment_schedule.check_footprint
json.user do
  json.id payment_schedule.invoicing_profile&.user&.id
  json.name payment_schedule.invoicing_profile.full_name
end
if payment_schedule.operator_profile
  json.operator do
    json.id payment_schedule.operator_profile.user_id
    json.extract! payment_schedule.operator_profile, :first_name, :last_name
  end
end
json.main_object do
  json.type payment_schedule.main_object&.object_type
  json.id payment_schedule.main_object&.object_id
end
if payment_schedule.gateway_subscription
  # this attribute is used to known which gateway should we interact with, in the front-end
  json.gateway payment_schedule.gateway_subscription.gateway
end
json.items payment_schedule.payment_schedule_items do |item|
  json.partial! 'api/payment_schedules/payment_schedule_item', item: item
end
