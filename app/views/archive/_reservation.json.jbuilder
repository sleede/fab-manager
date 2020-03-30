# frozen_string_literal: true

json.extract! invoiced, :created_at
json.reservable do
  json.type invoiced.reservable_type
  json.id invoiced.reservable_id
  if [Training.name, Machine.name, Space.name].include?(invoiced.reservable_type) && !invoiced.reservable.nil?
    json.extract! invoiced.reservable, :name, :created_at
  elsif invoiced.reservable_type == Event.name && !invoiced.reservable.nil?
    json.extract! invoiced.reservable, :title, :created_at
    json.prices do
      json.standard_price do
        json.partial! 'archive/vat', price: invoiced.reservable.amount, vat_rate: vat_rate
      end
      json.other_prices invoiced.reservable.event_price_categories do |price|
        json.partial! 'archive/vat', price: price.amount, vat_rate: vat_rate
        json.price_category do
          json.extract! price.price_category, :id, :name, :created_at
        end
      end
    end
  end
end
