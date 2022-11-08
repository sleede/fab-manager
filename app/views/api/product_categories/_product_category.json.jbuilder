# frozen_string_literal: true

json.extract! product_category, :id, :name, :slug, :parent_id, :position
json.products_count product_category.try(:products_count)
