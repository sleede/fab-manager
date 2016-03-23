json.extract! plan, :id, :base_name, :name, :interval, :interval_count, :group_id, :training_credit_nb, :is_rolling, :description, :type, :ui_weight
json.amount (plan.amount / 100.00)
json.prices plan.prices, partial: 'api/prices/price', as: :price
json.plan_file_attributes do
  json.id plan.plan_file.id
  json.attachment_identifier plan.plan_file.attachment_identifier
end if plan.plan_file

json.prices plan.prices do |price|
  json.extract! price, :id, :group_id, :plan_id, :priceable_type, :priceable_id
  json.amount price.amount / 100.0
  json.priceable_name price.priceable.name
end

json.partners plan.partners do |partner|
  json.first_name partner.first_name
  json.last_name partner.last_name
  json.email partner.email
end if plan.respond_to?(:partners)

json.training_credits plan.training_credits do |tc|
  json.training_id tc.creditable_id
end if attribute_requested?(@attributes_requested, 'trainings_credits')

json.machine_credits plan.machine_credits do |mc|
  json.machine_id mc.creditable_id
  json.hours mc.hours
end if attribute_requested?(@attributes_requested, 'machines_credits')
