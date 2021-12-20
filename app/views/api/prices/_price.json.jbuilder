# frozen_string_literal: true

json.extract! price, :id, :group_id, :plan_id, :priceable_type, :priceable_id, :duration
json.amount price.amount / 100.0
