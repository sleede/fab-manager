# frozen_string_literal: true

json.slot_id slot.id
json.can_modify slot.modifiable?(operator_role, user&.id, reservable)
json.title Slots::TitleService.new(operator_role, user).call(slot, [reservable])
json.start slot.start_at.iso8601
json.end slot.end_at.iso8601
json.is_reserved slot.reserved?(reservable)
json.is_completed slot.full?(reservable)
json.backgroundColor 'white'

json.availability_id slot.availability_id
json.slots_reservations_ids Slots::ReservationsService.user_reservations(slot, user, reservable)[:reservations].map(&:id)

json.tag_ids slot.availability.tag_ids
json.tags slot.availability.tags do |t|
  json.id t.id
  json.name t.name
end
json.plan_ids slot.availability.plan_ids

# the users who booked on this slot, if any
if (%w[admin manager].include? operator_role) && !slot.slots_reservations.empty?
  json.users slot.slots_reservations do |sr|
    json.id sr.reservation.user&.id
    json.name sr.reservation.user&.profile&.full_name
  end
end
