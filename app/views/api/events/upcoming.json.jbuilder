json.cache! @events do
  json.array!(@events) do |event|
    json.partial! 'api/events/event', event: event
    json.event_image_medium event.event_image.attachment.medium.url if event.event_image
    json.url event_url(event, format: :json)
  end
end
