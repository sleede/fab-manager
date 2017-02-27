json.array!(@slots) do |slot|
  json.id slot.id if slot.id
  json.can_modify slot.can_modify
  json.title slot.title
  json.start slot.start_at.iso8601
  json.end slot.end_at.iso8601
  json.is_reserved slot.is_reserved
  json.is_completed slot.is_complete?
  json.backgroundColor 'white'
  json.borderColor space_slot_border_color(slot)

  json.availability_id slot.availability_id
  json.space do
    json.id slot.space.id
    json.name slot.space.name
  end
  # the user who booked the slot ...
  json.user do
    json.id slot.reservation.user.id
    json.name slot.reservation.user.profile.full_name
  end if @current_user_role == 'admin' and slot.reservation # ... if the slot was reserved
  json.tag_ids slot.availability.tag_ids
  json.tags slot.availability.tags do |t|
    json.id t.id
    json.name t.name
  end
end
