# frozen_string_literal: true

json.extract! product, :id, :name, :slug, :sku, :description, :is_active, :product_category_id, :quantity_min, :stock, :low_stock_alert, :low_stock_threshold, :machine_ids
json.amount product.amount / 100.0 if product.amount.present?
