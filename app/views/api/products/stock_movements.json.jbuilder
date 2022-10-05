# frozen_string_literal: true

json.extract! @movements, :page, :total_pages, :page_size, :total_count
json.data @movements[:data] do |movement|
  json.partial! 'api/products/stock_movement', stock_movement: movement
  json.extract! movement, :product_id
end
