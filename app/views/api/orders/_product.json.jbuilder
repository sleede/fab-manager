# frozen_string_literal: true

json.orderable_name item.orderable.name
json.orderable_ref item.orderable.sku
json.orderable_slug item.orderable.slug
json.orderable_main_image_url item.orderable.main_image&.attachment_url
json.orderable_external_stock item.orderable.stock['external']
json.quantity_min item.orderable.quantity_min
