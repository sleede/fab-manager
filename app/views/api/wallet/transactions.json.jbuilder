json.array!(@wallet_transactions) do |t|
  json.extract! t, :id, :transaction_type, :created_at, :amount
  json.user do
    json.id t.user.id
    json.full_name t.user.profile.full_name
  end
end
