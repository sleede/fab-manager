# frozen_string_literal: true

json.array! @movements do |movement|
  json.partial! 'api/products/stock_movement', stock_movement: movement
  json.extract! movement, :product_id
end
