# frozen_string_literal: true

json.array!(@slots) do |slot|
  json.slot_id slot.id if slot.id
  json.can_modify slot.can_modify
  json.title slot.title
  json.start slot.start_at.iso8601
  json.end slot.end_at.iso8601
  json.is_reserved slot.is_reserved
  json.is_completed slot.complete?
  json.backgroundColor 'white'
  json.borderColor space_slot_border_color(slot)

  json.availability_id slot.availability_id
  json.space do
    json.id slot.space.id
    json.name slot.space.name
  end
  # the user who booked the slot, if the slot was reserved
  if (%w[admin manager].include? @current_user_role) && slot.reservation
    json.user do
      json.id slot.reservation.user.id
      json.name slot.reservation.user.profile.full_name
    end
  end
  json.tag_ids slot.availability.tag_ids
  json.tags slot.availability.tags do |t|
    json.id t.id
    json.name t.name
  end
  json.plan_ids slot.availability.plan_ids
end
