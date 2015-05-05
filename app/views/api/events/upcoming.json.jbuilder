json.array!(@events) do |event|
  json.partial! 'api/events/event', event: event
  json.url event_url(event, format: :json)
end

