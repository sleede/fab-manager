total = @events.except(:offset, :limit, :order).count

json.cache! [@events, @page] do
  json.array!(@events) do |event|
    json.partial! 'api/events/event', event: event
    json.event_image_small event.event_image.attachment.small.url if event.event_image
    json.url event_url(event, format: :json)
    json.nb_total_events total
  end
end
