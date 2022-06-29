# frozen_string_literal: true

json.array!(@credits) do |credit|
  json.partial! 'api/credits/credit', credit: credit
  json.used_credits credit.users_credits do |uc|
    json.extract! uc, :id, :created_at, :hours_used
  end
end
