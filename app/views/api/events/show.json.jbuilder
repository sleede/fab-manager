json.partial! 'api/events/event', event: @event
json.recurrence_events @event.recurrence_events do |e|
  json.id e.id
  json.start_date e.availability.start_at
  json.start_time e.availability.start_at
  json.end_date e.availability.end_at
  json.end_time e.availability.end_at
  json.nb_free_places e.nb_free_places
  json.availability_id e.availability_id
end
