json.id reservation.id
json.user_id reservation.user_id
json.user_full_name reservation.user.profile.full_name
json.message reservation.message
json.slots reservation.slots do |s|
  json.id s.id
  json.start_at s.start_at.iso8601
  json.end_at s.end_at.iso8601
end
json.nb_reserve_places reservation.nb_reserve_places
json.nb_reserve_reduced_places reservation.nb_reserve_reduced_places
json.created_at reservation.created_at.iso8601
json.reservable_id reservation.reservable_id
json.reservable_type reservation.reservable_type
