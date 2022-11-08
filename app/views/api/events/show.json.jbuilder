# frozen_string_literal: true

json.partial! 'api/events/event', event: @event
json.recurrence_events @event.recurrence_events do |e|
  json.id e.id
  json.start_date e.availability.start_at.to_date
  json.start_time e.availability.start_at.strftime('%R')
  json.end_date e.availability.end_at.to_date
  json.end_time e.availability.end_at.strftime('%R')
  json.nb_free_places e.nb_free_places
  json.availability_id e.availability_id
end
