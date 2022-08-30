# frozen_string_literal: true

json.prices @prices do |price|
  json.extract! price, :id, :group_id, :plan_id, :priceable_id, :priceable_type, :amount, :created_at, :updated_at
end
