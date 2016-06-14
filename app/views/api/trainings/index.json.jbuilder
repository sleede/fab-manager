json.array!(@trainings) do |training|
  json.id training.id
  json.name training.name
  json.description training.description
  json.machine_ids training.machine_ids
  json.availabilities training.availabilities do |a|
    json.id a.id
    json.start_at a.start_at.iso8601
    json.end_at a.end_at.iso8601
    json.reservation_users a.slots.map do |slot|
      json.id slot.reservation.user.id
      json.full_name slot.reservation.user.profile.full_name
      json.is_valid slot.reservation.user.trainings.include?(training)
    end
  end if attribute_requested?(@requested_attributes, 'availabilities')
  json.nb_total_places training.nb_total_places

  json.plan_ids training.plan_ids if current_user and current_user.is_admin?
end
