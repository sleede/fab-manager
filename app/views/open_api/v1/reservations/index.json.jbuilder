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
    case reservation.reservable_type
    when 'Training'
      json.partial! 'open_api/v1/trainings/training', training: reservation.reservable
    when 'Machine'
      json.partial! 'open_api/v1/machines/machine', machine: reservation.reservable
    when 'Event'
      json.partial! 'open_api/v1/events/event', event: reservation.reservable
    end
  end

  json.reserved_slots reservation.slots_reservations do |slot_reservation|
    json.extract! slot_reservation, :canceled_at
    json.extract! slot_reservation.slot, :availability_id, :start_at, :end_at
  end
end
