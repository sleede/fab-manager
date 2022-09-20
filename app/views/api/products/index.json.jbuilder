# frozen_string_literal: true

json.extract! @products, :page, :total_pages, :page_size, :total_count
json.data @products[:data] do |product|
  json.extract! product, :id, :name, :slug, :sku, :is_active, :product_category_id, :quantity_min, :stock, :machine_ids,
                :low_stock_threshold
  json.amount product.amount / 100.0 if product.amount.present?
  json.product_images_attributes product.product_images do |f|
    json.id f.id
    json.attachment_name f.attachment_identifier
    json.attachment_url f.attachment_url
    json.is_main f.is_main
  end
end
