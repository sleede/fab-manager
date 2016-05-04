json.reservations @reservations do |reservation|
  json.extract! reservation, :id, :user_id, :reservable_id, :reservable_type, :updated_at, :created_at

  if reservation.association(:user).loaded?
    json.user do
      json.partial! 'open_api/v1/users/user', user: reservation.user
    end
  end

  json.reservable do
    if reservation.reservable_type == "Training"
      json.partial! 'open_api/v1/trainings/training', training: reservation.reservable
    elsif reservation.reservable_type == "Machine"
      json.partial! 'open_api/v1/machines/machine', machine: reservation.reservable
    elsif reservation.reservable_type == "Event"
      json.partial! 'open_api/v1/events/event', event: reservation.reservable
    end
  end
end
