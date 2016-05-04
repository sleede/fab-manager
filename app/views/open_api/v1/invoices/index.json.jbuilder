json.invoices @invoices do |invoice|
  json.extract! invoice, :id, :invoiced_id, :user_id, :invoiced_type, :stp_invoice_id, :reference, :total, :type, :description

  json.invoice_url download_open_api_v1_invoice_path(invoice)
  json.invoiced do
    json.created_at invoice.invoiced.created_at
  end
end
