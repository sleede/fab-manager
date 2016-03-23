json.array!(@invoices) do |invoice|
  json.extract! invoice, :id, :created_at, :reference, :invoiced_type, :user_id, :avoir_date
  json.total (invoice.total / 100.00)
  json.url invoice_url(invoice, format: :json)
  json.name invoice.user.profile.full_name
  json.has_avoir invoice.has_avoir
  json.is_avoir invoice.is_a?(Avoir)
  json.is_subscription_invoice invoice.is_subscription_invoice?
  json.stripe invoice.stp_invoice_id?
  json.date invoice.is_a?(Avoir) ? invoice.avoir_date : invoice.created_at
  json.prevent_refund invoice.prevent_refund?
end
