json.extract! event, :id, :title, :description, :age_range_id
json.event_image event.event_image.attachment_url if event.event_image
json.event_files_attributes event.event_files do |f|
  json.id f.id
  json.attachment f.attachment_identifier
  json.attachment_url f.attachment_url
end
json.category_ids event.category_ids
json.categories event.categories do |c|
  json.id c.id
  json.name c.name
end
json.event_theme_ids event.event_theme_ids
json.event_themes event.event_themes do |e|
  json.name e.name
end
json.age_range_id event.age_range_id
json.age_range do
  json.name event.age_range.name
end if event.age_range
json.start_date event.availability.start_at
json.start_time event.availability.start_at
json.end_date event.availability.end_at
json.end_time event.availability.end_at
json.month t('date.month_names')[event.availability.start_at.month]
json.month_id event.availability.start_at.month
json.year event.availability.start_at.year
json.all_day event.availability.start_at.hour == 0 ? 'true' : 'false'
json.availability do
  json.id event.availability.id
  json.start_at event.availability.start_at
  json.end_at event.availability.end_at
end
json.availability_id event.availability_id
json.amount (event.amount / 100.0) if event.amount
json.reduced_amount (event.reduced_amount / 100.0) if event.reduced_amount
json.nb_total_places event.nb_total_places
json.nb_free_places event.nb_free_places || event.nb_total_places

