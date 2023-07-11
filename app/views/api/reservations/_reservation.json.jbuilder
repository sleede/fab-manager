# frozen_string_literal: true

json.id reservation.id
json.user_id reservation.statistic_profile.user_id
json.user_full_name reservation.user&.profile&.full_name
json.message reservation.message
json.slots_reservations_attributes reservation.slots_reservations do |sr|
  json.id sr.id
  json.canceled_at sr.canceled_at&.iso8601
  json.is_valid sr.is_valid
  json.slot_id sr.slot_id
  json.slot_attributes do
    json.id sr.slot_id
    json.start_at sr.slot.start_at.iso8601
    json.end_at sr.slot.end_at.iso8601
    json.availability_id sr.slot.availability_id
  end
end
json.nb_reserve_places reservation.nb_reserve_places
json.tickets_attributes reservation.tickets do |t|
  json.extract! t, :booked, :created_at
  json.event_price_category do
    json.extract! t.event_price_category, :id, :price_category_id
    json.price_category do
      json.extract! t.event_price_category.price_category, :id, :name
    end
  end
end
json.total_booked_seats reservation.total_booked_seats(canceled: true)
json.created_at reservation.created_at.iso8601
json.reservable_id reservation.reservable_id
json.reservable_type reservation.reservable_type
json.reservable do
  json.id reservation.reservable.id
  json.name reservation.reservable.name
end
json.booking_users_attributes reservation.booking_users.order(booked_type: :desc) do |bu|
  json.id bu.id
  json.name bu.name
  json.event_price_category_id bu.event_price_category_id
  json.booked_id bu.booked_id
  json.booked_type bu.booked_type
  json.age ((Time.zone.now - bu.booked.birthday.to_time) / 1.year.seconds).floor if bu.booked_type == 'Child'
end
json.is_valid reservation.slots_reservations[0].is_valid
json.is_paid reservation.invoice_items.count.positive?
