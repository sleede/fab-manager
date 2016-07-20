json.array!(@wallet_transactions) do |t|
  json.extract! t, :id, :transaction_type, :created_at, :amount, :transactable_type
  json.user do
    json.id t.user.id
    json.full_name t.user.profile.full_name
  end
  json.invoice do
    json.id t.invoice.id
    json.reference t.invoice.reference
  end if t.invoice
end
