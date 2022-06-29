# frozen_string_literal: true

json.array!(@credits) do |credit|
  json.partial! 'api/credits/credit', credit: credit
  json.hours_used credit.users_credits.find_by(user_id: @user.id)&.hours_used
end
