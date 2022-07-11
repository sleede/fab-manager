# frozen_string_literal: true

json.array! @product_categories do |product_category|
  json.partial! 'api/product_categories/product_category', product_category: product_category
end
