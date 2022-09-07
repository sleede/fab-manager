# frozen_string_literal: true

json.extract! product, :id, :name, :slug, :sku, :is_active, :product_category_id, :quantity_min, :stock, :low_stock_alert,
              :low_stock_threshold, :machine_ids
json.description sanitize(product.description)
json.amount product.amount / 100.0 if product.amount.present?
json.product_files_attributes product.product_files do |f|
  json.id f.id
  json.attachment_name f.attachment_identifier
  json.attachment_url f.attachment_url
end
json.product_images_attributes product.product_images do |f|
  json.id f.id
  json.attachment_name f.attachment_identifier
  json.attachment_url f.attachment_url
  json.is_main f.is_main
end
json.product_stock_movements_attributes product.product_stock_movements do |s|
  json.id s.id
  json.quantity s.quantity
  json.reason s.reason
  json.stock_type s.stock_type
  json.remaining_stock s.remaining_stock
  json.date s.date
end
