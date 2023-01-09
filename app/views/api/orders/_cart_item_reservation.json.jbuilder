# frozen_string_literal: true

json.orderable_name item.orderable.reservable.name
json.orderable_slug item.orderable.reservable.slug
json.orderable_main_image_url item.orderable.reservable&.try("#{item.orderable.reservable_type.downcase}_image")&.attachment&.medium&.url
json.slots_reservations item.orderable.cart_item_reservation_slots do |sr|
  json.extract! sr, :id, :offered
  json.slot do
    json.extract! sr.slot, :id, :start_at, :end_at
  end
end
