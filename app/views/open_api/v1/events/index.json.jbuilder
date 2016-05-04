json.events @events do |event|
  json.partial! 'open_api/v1/events/event', event: event
  json.extract! event, :amount, :reduced_amount, :nb_total_places, :nb_free_places
end
