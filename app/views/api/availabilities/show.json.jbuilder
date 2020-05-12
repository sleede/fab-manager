# frozen_string_literal: true

json.extract! @availability, :id, :title, :lock, :is_recurrent, :occurrence_id, :period, :nb_periods, :end_date
json.start_at @availability.start_at.iso8601
json.end_at @availability.end_at.iso8601
json.slot_duration @availability.slot_duration
json.available_type @availability.available_type
json.machine_ids @availability.machine_ids
json.plan_ids @availability.plan_ids
json.backgroundColor 'white'
json.borderColor availability_border_color(@availability)
json.tag_ids @availability.tag_ids
json.tags @availability.tags do |t|
  json.id t.id
  json.name t.name
end
