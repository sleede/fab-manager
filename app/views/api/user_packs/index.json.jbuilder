# frozen_string_literal: true

json.array!(@user_packs) do |user_pack|
  json.extract! user_pack, :minutes_used, :expires_at
  json.prepaid_pack do
    json.extract! user_pack.prepaid_pack :minutes
  end
end
