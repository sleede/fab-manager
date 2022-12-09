# frozen_string_literal: true

json.lines @lines do |line|
  json.extract! line, :id, :line_type, :journal_code, :date, :account_code, :account_label, :analytical_code, :debit, :credit, :currency, :summary
  if line.association(:invoice).loaded?
    json.invoice do
      json.extract! line.invoice, :reference, :id
      json.label Invoices::LabelService.build(line.invoice)
      json.url download_open_api_v1_invoice_path(line.invoice)
      if @codes.values.include?(line.account_code)
        mean = @codes.select { |_key, value| value == line.account_code }
        json.payment_details line.invoice.payment_details(mean.keys[0])
      end
    end
  end
  if line.association(:invoicing_profile).loaded?
    json.user do
      json.invoicing_profile_id line.invoicing_profile_id
      json.external_id line.invoicing_profile.external_id
    end
  end
end
json.status Accounting::AccountingService.status
