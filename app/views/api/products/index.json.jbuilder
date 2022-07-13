# frozen_string_literal: true

json.array! @products do |product|
  json.partial! 'api/products/product', product: product
end
