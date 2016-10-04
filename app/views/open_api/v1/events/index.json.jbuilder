json.events @events do |event|
  json.partial! 'open_api/v1/events/event', event: event
  json.extract! event, :nb_total_places, :nb_free_places
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
end
