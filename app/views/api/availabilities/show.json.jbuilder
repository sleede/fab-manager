json.id @availability.id
json.start_at @availability.start_at.iso8601
json.end_at @availability.end_at.iso8601
json.available_type @availability.available_type
json.machine_ids @availability.machine_ids
json.backgroundColor 'white'
json.borderColor availability_border_color(@availability)
json.title @availability.title
json.tag_ids @availability.tag_ids
json.tags @availability.tags do |t|
  json.id t.id
  json.name t.name
end
