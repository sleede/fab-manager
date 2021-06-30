# frozen_string_literal: true

json.extract! @machine, :id, :name, :description, :spec, :disabled, :slug
json.machine_image @machine.machine_image.attachment.large.url if @machine.machine_image
json.machine_files_attributes @machine.machine_files do |f|
  json.id f.id
  json.attachment f.attachment_identifier
  json.attachment_url f.attachment_url
end
json.trainings @machine.trainings.each, :id, :name, :disabled
if current_user
  json.current_user_is_trained current_user.training_machine?(@machine)
  if !current_user.training_machine?(@machine) && current_user.next_training_reservation_by_machine(@machine)
    json.current_user_next_training_reservation do
      json.partial! 'api/reservations/reservation', reservation: current_user.next_training_reservation_by_machine(@machine)
    end
  end
  json.current_user_has_packs current_user.packs?(@machine)
  json.has_prepaid_packs_for_current_user @machine.packs?(current_user)
end

json.machine_projects @machine.projects.published.last(10) do |p|
  json.id p.id
  json.name p.name
  json.slug p.slug
end
