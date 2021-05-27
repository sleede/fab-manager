# frozen_string_literal: true

json.invoices @invoices do |invoice|
  json.extract! invoice, :id, :user_id, :reference, :total, :type, :description
  if invoice.payment_gateway_object
    json.payment_gateway_object do
      json.id invoice.payment_gateway_object.gateway_object_id
      json.type invoice.payment_gateway_object.gateway_object_type
    end
  end

  json.invoice_url download_open_api_v1_invoice_path(invoice)
  json.main_object do
    json.type invoice.main_item.object_type
    json.id invoice.main_item.object_id
    json.created_at invoice.main_item.object.created_at
  end
end
