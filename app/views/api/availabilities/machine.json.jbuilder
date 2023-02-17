# frozen_string_literal: true

json.array!(@slots) do |slot|
  json.partial! 'api/availabilities/slot', slot: slot, operator_role: @operator_role, reservable: @machine
  json.borderColor machines_slot_border_color(slot, @customer)

  json.machine do
    json.id @machine.id
    json.name @machine.name
  end
  # the user who booked the slot, if the slot was reserved
  if (%w[admin manager].include? @current_user_role) && slot.reservation
    json.user do
      json.id slot.reservation.user&.id
      json.name slot.reservation.user&.profile&.full_name
    end
  end
end
