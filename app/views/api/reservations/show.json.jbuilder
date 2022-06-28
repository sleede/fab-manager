# frozen_string_literal: true

json.partial! 'api/reservations/reservation', reservation: @reservation
json.user do
  json.id @reservation.user.id
  if @reservation.user.subscribed_plan
    json.subscribed_plan do
      json.partial! 'api/shared/plan', plan: @reservation.user.subscribed_plan
    end
  end
  json.training_credits @reservation.user.training_credits do |tc|
    json.training_id tc.creditable_id
  end
  json.machine_credits @reservation.user.machine_credits do |mc|
    json.machine_id mc.creditable_id
    json.hours_used mc.users_credits.find_by(user_id: @reservation.statistic_profile.user_id).hours_used
  end
end
json.reservable do
  json.id @reservation.reservable.id
  json.name @reservation.reservable.name
end
