# frozen_string_literal: true

json.reservations @reservations do |reservation|
  json.extract! reservation, :id, :reservable_id, :reservable_type, :updated_at, :created_at

  if reservation.association(:statistic_profile).loaded?
    json.user_id reservation.statistic_profile.user_id
    unless reservation.statistic_profile.user.nil?
      json.user do
        json.partial! 'open_api/v1/users/user', user: reservation.statistic_profile.user
      end
    end
  end

  json.reservable do
    if reservation.reservable_type == 'Training'
      json.partial! 'open_api/v1/trainings/training', training: reservation.reservable
    elsif reservation.reservable_type == 'Machine'
      json.partial! 'open_api/v1/machines/machine', machine: reservation.reservable
    elsif reservation.reservable_type == 'Event'
      json.partial! 'open_api/v1/events/event', event: reservation.reservable
    end
  end
end
