# frozen_string_literal: true

json.lines @lines do |line|
  json.extract! line, :id, :line_type, :journal_code, :date, :account_code, :account_label, :analytical_code, :debit, :credit, :currency, :summary
  json.invoice do
    json.extract! line.invoice, :reference, :id
    json.label Invoices::LabelService.build(line.invoice)
    json.url download_open_api_v1_invoice_path(line.invoice)
  end
  json.user_invoicing_profile_id line.invoicing_profile_id
end
json.status Accounting::AccountingService.status
