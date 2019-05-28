# frozen_string_literal: true

max_invoices = @invoices.except(:offset, :limit, :order).count

json.array!(@invoices) do |invoice|
  json.maxInvoices max_invoices
  json.extract! invoice, :id, :created_at, :reference, :invoiced_type, :avoir_date
  json.user_id invoice.invoicing_profile.user_id
  json.total (invoice.total / 100.00)
  json.url invoice_url(invoice, format: :json)
  json.name invoice.invoicing_profile.full_name
  json.has_avoir invoice.refunded?
  json.is_avoir invoice.is_a?(Avoir)
  json.is_subscription_invoice invoice.subscription_invoice?
  json.stripe invoice.stp_invoice_id?
  json.date invoice.is_a?(Avoir) ? invoice.avoir_date : invoice.created_at
  json.prevent_refund invoice.prevent_refund?
  json.chained_footprint invoice.check_footprint
end
