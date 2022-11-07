# frozen_string_literal: true

json.extract! machine, :id, :name, :slug, :disabled

if machine.machine_image
  json.machine_image_attributes do
    json.id machine.machine_image.id
    json.attachment_name machine.machine_image.attachment_identifier
    json.attachment_url machine.machine_image.attachment.url
  end
end
