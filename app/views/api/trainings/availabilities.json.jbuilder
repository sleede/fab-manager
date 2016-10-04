json.extract! @training, :id, :name, :description, :machine_ids, :nb_total_places, :public_page
json.availabilities @availabilities do |a|
  json.id a.id
  json.start_at a.start_at.iso8601
  json.end_at a.end_at.iso8601
  json.reservation_users a.slots.map do |slot|
    json.id slot.reservation.user.id
    json.full_name slot.reservation.user.profile.full_name
    json.is_valid slot.reservation.user.trainings.include?(@training)
  end
end
