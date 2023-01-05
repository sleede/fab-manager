# frozen_string_literal: true

total = @events.except(:offset, :limit, :order).count

json.array!(@events) do |event|
  json.partial! 'api/events/event', event: event
  json.event_image_small event.event_image.attachment.small.url if event.event_image

  json.nb_total_events total
end
