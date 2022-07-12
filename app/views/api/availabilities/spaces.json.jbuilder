# frozen_string_literal: true

json.array!(@slots) do |slot|
  json.partial! 'api/availabilities/slot', slot: slot, operator_role: @operator_role
  json.is_completed slot.full?
  json.borderColor space_slot_border_color(slot)

  json.space do
    json.id @space.id
    json.name @space.name
  end
end
