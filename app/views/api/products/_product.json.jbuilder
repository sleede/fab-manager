# frozen_string_literal: true

json.extract! product, :id, :name, :slug, :sku, :is_active, :product_category_id, :quantity_min, :stock, :low_stock_alert,
              :low_stock_threshold, :machine_ids, :created_at
json.description sanitize(product.description)
json.amount product.amount / 100.0 if product.amount.present?
json.product_files_attributes product.product_files.order(created_at: :asc) do |f|
  json.id f.id
  json.attachment_name f.attachment_identifier
  json.attachment_url f.attachment_url
end
json.product_images_attributes product.product_images.order(created_at: :asc) do |f|
  json.id f.id
  json.attachment_name f.attachment_identifier
  json.attachment_url f.attachment_url
  json.thumb_attachment_url f.attachment.thumb.url
  json.is_main f.is_main
end

if product.advanced_accounting
  json.advanced_accounting_attributes do
    json.partial! 'api/advanced_accounting/advanced_accounting', advanced_accounting: product.advanced_accounting
  end
end
