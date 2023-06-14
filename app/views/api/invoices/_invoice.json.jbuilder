# frozen_string_literal: true

json.extract! invoice, :id, :created_at, :reference, :avoir_date, :description
json.user_id invoice.invoicing_profile&.user_id
json.total invoice.total / 100.00
json.name invoice.user.profile.full_name
json.has_avoir invoice.refunded?
json.is_avoir invoice.is_a?(Avoir)
json.is_subscription_invoice invoice.subscription_invoice?
json.is_online_card invoice.paid_by_card?
json.date invoice.is_a?(Avoir) ? invoice.avoir_date : invoice.created_at
json.chained_footprint invoice.check_footprint
json.main_object do
  json.type invoice.invoice_items.find(&:main)&.object_type
  json.id invoice.invoice_items.find(&:main)&.object_id
end
json.items invoice.invoice_items do |item|
  json.id item.id
  json.amount item.amount / 100.0
  json.description item.description
  json.avoir_item_id item.invoice_item.id if item.invoice_item
end
