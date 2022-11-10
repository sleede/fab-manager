# frozen_string_literal: true

json.extract! space, :id, :name, :description, :slug, :default_places, :disabled
if space.space_image
  json.space_image_attributes do
    json.id space.space_image.id
    json.attachment_name space.space_image.attachment_identifier
    json.attachment_url space.space_image.attachment.url
  end
end

if space.advanced_accounting
  json.advanced_accounting_attributes do
    json.partial! 'api/advanced_accounting/advanced_accounting', advanced_accounting: space.advanced_accounting
  end
end
