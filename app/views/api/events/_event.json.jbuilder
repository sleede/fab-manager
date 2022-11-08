# frozen_string_literal: true

json.extract! event, :id, :title, :description
if event.event_image
  json.event_image_attributes do
    json.id event.event_image.id
    json.attachment_name event.event_image.attachment_identifier
    json.attachment_url event.event_image.attachment_url
  end
end
json.event_files_attributes event.event_files do |f|
  json.id f.id
  json.attachment_name f.attachment_identifier
  json.attachment_url f.attachment_url
end
json.category_id event.category_id
if event.category
  json.category do
    json.id event.category.id
    json.name event.category.name
    json.slug event.category.slug
  end
end
json.event_theme_ids event.event_theme_ids
json.event_themes event.event_themes do |e|
  json.name e.name
end
json.age_range_id event.age_range_id
if event.age_range
  json.age_range do
    json.name event.age_range.name
  end
end
json.start_date event.availability.start_at.to_date
json.start_time event.availability.start_at.strftime('%R')
json.end_date event.availability.end_at.to_date
json.end_time event.availability.end_at.strftime('%R')
json.month t('date.month_names')[event.availability.start_at.month]
json.month_id event.availability.start_at.month
json.year event.availability.start_at.year
json.all_day event.all_day?
json.availability do
  json.id event.availability.id
  json.start_at event.availability.start_at
  json.end_at event.availability.end_at
  json.slot_id event.availability.slots.first&.id
end
json.availability_id event.availability_id
json.amount event.amount / 100.0 if event.amount
json.event_price_categories_attributes event.event_price_categories do |p_cat|
  json.id p_cat.id
  json.price_category_id p_cat.price_category.id
  json.amount p_cat.amount / 100.0
  json.category do
    json.extract! p_cat.price_category, :id, :name
  end
end
json.nb_total_places event.nb_total_places
json.nb_free_places event.nb_free_places || event.nb_total_places

