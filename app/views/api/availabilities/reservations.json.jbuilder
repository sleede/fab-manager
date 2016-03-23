json.array!(@reservation_slots) do |slot|
  json.slot_id slot.id
  json.start_at slot.start_at.iso8601
  json.end_at slot.end_at.iso8601
  json.message slot.reservation.message
  json.reservable slot.reservation.reservable
  json.reservable_id slot.reservation.reservable_id
  json.reservable_type slot.reservation.reservable_type
  json.user do
    json.id slot.reservation.user.id
    json.name slot.reservation.user.profile.full_name
  end
  json.canceled_at slot.canceled_at
end
