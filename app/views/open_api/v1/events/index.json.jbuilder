# frozen_string_literal: true

json.events @events do |event|
  json.partial! 'open_api/v1/events/event', event: event
  json.extract! event, :nb_total_places, :nb_free_places
  json.start_at event.availability.start_at
  json.end_at event.availability.end_at
  json.category event.category.name
  json.themes event.event_themes&.map(&:name)
  json.age_range event.age_range&.name
  if event.event_image
    json.event_image do
      json.large_url root_url.chomp('/') + event.event_image.attachment.large.url
      json.medium_url root_url.chomp('/') + event.event_image.attachment.medium.url
      json.small_url root_url.chomp('/') + event.event_image.attachment.small.url
    end
  end
  json.prices do
    json.normal do
      json.name I18n.t('app.public.home.full_price')
      json.amount event.amount
    end
    event.event_price_categories.each do |epc|
      pc = epc.price_category
      json.set! pc.id do
        json.name pc.name
        json.amount epc.amount
      end
    end
  end
  json.url URI.join("#{ENV.fetch('DEFAULT_PROTOCOL')}://#{ENV.fetch('DEFAULT_HOST')}", "/#!/events/#{event.id}")
end
