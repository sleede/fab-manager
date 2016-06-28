json.array!(@availabilities) do |availability|
  json.id availability.id
  json.title availability.title
  json.start availability.start_at.iso8601
  json.end availability.end_at.iso8601
  json.available_type availability.available_type
  json.machine_ids availability.machine_ids
  json.training_ids availability.training_ids
  json.backgroundColor 'white'
  json.borderColor availability_border_color(availability)
  json.tag_ids availability.tag_ids
  json.tags availability.tags do |t|
    json.id t.id
    json.name t.name
  end
end
