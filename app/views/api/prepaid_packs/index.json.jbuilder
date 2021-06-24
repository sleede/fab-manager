# frozen_string_literal: true

json.array! @packs do |pack|
  json.extract! pack, :id, :priceable_id, :priceable_type, :group_id, :minutes, :disabled
  json.amount pack.amount / 100.0
end
