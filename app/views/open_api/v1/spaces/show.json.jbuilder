# frozen_string_literal: true

json.partial! 'open_api/v1/spaces/space', space: @space
json.extract! @space, :description, :characteristics
json.image URI.join(root_url, @space.space_image.attachment.url) if @space.space_image
