json.array!(@availabilities) do |availability|
  json.id availability.id
  json.title availability.title
  json.start availability.start_at.iso8601
  json.end availability.end_at.iso8601
  json.backgroundColor 'white'
  # availability object
  if availability.try(:available_type)
    if availability.available_type == 'event'
      json.event_id availability.event.id
    end
    if availability.available_type == 'training'
      json.training_id availability.trainings.first.id
    end
    json.available_type availability.available_type
    json.borderColor availability_border_color(availability)
    json.tag_ids availability.tag_ids
    json.tags availability.tags do |t|
      json.id t.id
      json.name t.name
    end
  # machine slot object
  else
    json.borderColor machines_slot_border_color(availability)
    json.tag_ids availability.availability.tag_ids
    json.tags availability.availability.tags do |t|
      json.id t.id
      json.name t.name
    end
  end
end
