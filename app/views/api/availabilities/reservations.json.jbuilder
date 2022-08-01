# frozen_string_literal: true

json.array!(@slots_reservations) do |sr|
  json.id sr.id
  json.slot_id sr.slot_id
  json.start_at sr.slot.start_at.iso8601
  json.end_at sr.slot.end_at.iso8601
  json.message sr.reservation.message
  json.reservable sr.reservation.reservable
  json.reservable_id sr.reservation.reservable_id
  json.reservable_type sr.reservation.reservable_type
  json.user do
    json.id sr.reservation.statistic_profile&.user_id
    json.name sr.reservation.statistic_profile&.user&.profile&.full_name
  end
  json.canceled_at sr.canceled_at
end
