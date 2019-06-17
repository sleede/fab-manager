json.extract! @wallet, :id, :invoicing_profile_id, :amount
json.user_id @wallet.invoicing_profile.user_id
