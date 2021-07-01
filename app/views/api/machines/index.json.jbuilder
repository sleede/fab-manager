# frozen_string_literal: true

json.array!(@machines) do |machine|
  json.extract! machine, :id, :name, :slug, :disabled

  json.machine_image machine.machine_image.attachment.medium.url if machine.machine_image
end
