json.extract! @invoice, :id, :created_at, :reference, :invoiced_type, :user_id, :avoir_date, :description
json.total (@invoice.total / 100.00)
json.name @invoice.user.profile.full_name
json.has_avoir @invoice.has_avoir
json.is_avoir @invoice.is_a?(Avoir)
json.is_subscription_invoice @invoice.is_subscription_invoice?
json.stripe @invoice.stp_invoice_id?
json.date @invoice.is_a?(Avoir) ? @invoice.avoir_date : @invoice.created_at
json.items @invoice.invoice_items do |item|
  json.id item.id
  json.stp_invoice_item_id item.stp_invoice_item_id
  json.amount (item.amount / 100.0)
  json.description item.description
  json.avoir_item_id item.invoice_item.id if item.invoice_item
end
