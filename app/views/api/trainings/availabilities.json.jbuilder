# frozen_string_literal: true

json.extract! @training, :id, :name, :description, :machine_ids, :nb_total_places, :public_page
json.availabilities @availabilities do |a|
  json.id a.id
  json.start_at a.start_at.iso8601
  json.end_at a.end_at.iso8601
  json.reservation_users a.slots.map(&:slots_reservations).flatten.map do |sr|
    json.id sr.reservation.statistic_profile.user_id
    json.full_name sr.reservation.statistic_profile.user&.profile&.full_name
    json.is_valid sr.reservation.statistic_profile.trainings&.include?(@training)
  end
end
