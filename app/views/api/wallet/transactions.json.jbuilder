json.array!(@wallet_transactions) do |t|
  json.extract! t, :id, :transaction_type, :created_at, :amount, :transactable_type
  json.user do
    json.id t.user.id
    json.full_name t.user.profile.full_name
  end
  json.transactable do
    if t.transactable_type == 'Reservation'
      json.reservable_type t.transactable.reservable_type
    end
  end if t.transactable
end
