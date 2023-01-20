# frozen_string_literal: true

json.array!(@user_packs) do |user_pack|
  json.extract! user_pack, :id, :minutes_used, :expires_at
  json.prepaid_pack do
    json.extract! user_pack.prepaid_pack, :minutes, :priceable_type
    json.priceable do
      json.extract! user_pack.prepaid_pack.priceable, :name
    end
  end
end
