json.array!(@wallet_transactions) do |t|
  json.extract! t, :id, :transaction_type, :created_at, :amount
  json.user do
    json.id t.invoicing_profile.user_id
    json.full_name t.invoicing_profile.full_name
  end
  if t.invoice
    json.invoice do
      json.id t.invoice.id
      json.reference t.invoice.reference
    end
  end
  if t.payment_schedule
    json.payment_schedule do
      json.id t.payment_schedule.id
      json.reference t.payment_schedule.reference
    end
  end
end
