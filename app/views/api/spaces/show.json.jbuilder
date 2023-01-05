# frozen_string_literal: true

json.partial! 'api/spaces/space', space: @space
json.extract! @space, :characteristics, :created_at, :updated_at
json.space_files_attributes @space.space_files do |f|
  json.id f.id
  json.attachment_name f.attachment_identifier
  json.attachment_url f.attachment_url
end
