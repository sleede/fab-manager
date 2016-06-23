user_is_admin = (current_user and current_user.is_admin?)

json.array!(@trainings) do |training|
  json.extract! training, :id, :name, :description, :machine_ids, :nb_total_places
  json.training_image training.training_image.attachment.large.url if training.training_image
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

  json.plan_ids training.plan_ids if user_is_admin
end
