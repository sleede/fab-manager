json.extract! plan, :id, :base_name, :name, :interval, :interval_count, :group_id, :training_credit_nb, :is_rolling, :description, :type, :ui_weight
json.amount (plan.amount / 100.00)
json.prices plan.prices, partial: 'api/prices/price', as: :price
json.plan_file_attributes do
  json.id plan.plan_file.id
  json.attachment_identifier plan.plan_file.attachment_identifier
end if plan.plan_file

json.partners plan.partners do |partner|
  json.first_name partner.first_name
  json.last_name partner.last_name
  json.email partner.email
end if plan.respond_to?(:partners)
