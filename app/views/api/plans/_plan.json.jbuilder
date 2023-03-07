# frozen_string_literal: true

json.extract! plan, :id, :base_name, :name, :interval, :interval_count, :group_id, :training_credit_nb, :is_rolling, :description, :type,
              :ui_weight, :disabled, :monthly_payment, :plan_category_id
json.amount plan.amount / 100.00
json.prices_attributes plan.prices, partial: 'api/prices/price', as: :price
if plan.plan_file
  json.plan_file_attributes do
    json.id plan.plan_file.id
    json.attachment_name plan.plan_file.attachment_identifier
    json.attachment_url plan.plan_file.attachment.url
  end
end

if plan.respond_to?(:partners)
  json.partners plan.partners do |partner|
    json.first_name partner.first_name
    json.last_name partner.last_name
    json.email partner.email
  end
  json.partner_id plan.partner_id
end

if plan.advanced_accounting
  json.advanced_accounting_attributes do
    json.partial! 'api/advanced_accounting/advanced_accounting', advanced_accounting: plan.advanced_accounting
  end
end

json.plan_limitations_attributes plan.plan_limitations do |limitation|
  json.extract! limitation, :id, :limitable_id, :limitable_type, :limit
end

