# frozen_string_literal: true

json.array!(@slots) do |slot|
  json.partial! 'api/availabilities/slot', slot: slot, operator_role: @operator_role
  json.borderColor trainings_events_border_color(slot.availability)

  json.is_completed slot.full?
  json.nb_total_places slot.availability.nb_total_places

  json.training do
    json.id slot.availability.trainings.first.id
    json.name slot.availability.trainings.first.name
    json.description slot.availability.trainings.first.description
    json.machines slot.availability.trainings.first.machines do |m|
      json.id m.id
      json.name m.name
    end
  end
end
