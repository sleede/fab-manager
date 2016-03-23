user_is_admin = (current_user and current_user.is_admin?)

json.array!(@machines) do |machine|
  json.extract! machine, :id, :name, :description, :spec, :slug
  json.url machine_url(machine, format: :json)
  json.machine_image machine.machine_image.attachment.medium.url if machine.machine_image
  json.current_user_is_training current_user.is_training_machine?(machine) if current_user
  json.current_user_training_reservation do
    json.partial! 'api/reservations/reservation', reservation: current_user.training_reservation_by_machine(machine)
  end if current_user and !current_user.is_training_machine?(machine) and current_user.training_reservation_by_machine(machine)

  json.plan_ids machine.plan_ids if user_is_admin
end
