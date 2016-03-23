json.extract! @avoir, :id, :created_at, :reference, :invoiced_type, :user_id, :avoir_date, :avoir_mode, :invoice_id
json.total (@avoir.total / 100.00)
json.name @avoir.user.profile.full_name
json.has_avoir false
json.is_avoir true
json.date @avoir.avoir_date
json.items @avoir.invoice_items do |item|
  json.id item.id
  json.stp_invoice_item_id item.stp_invoice_item_id
  json.amount (item.amount / 100.0)
  json.description item.description
  json.invoice_item_id item.invoice_item_id
end