# frozen_string_literal: true

json.partial! 'open_api/v1/machines/machine', machine: @machine
json.extract! @machine, :description, :spec
json.image URI.join(root_url, @machine.machine_image.attachment.url) if @machine.machine_image
