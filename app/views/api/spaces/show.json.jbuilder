# frozen_string_literal: true

json.partial! 'api/spaces/space', space: @space
json.extract! @space, :characteristics, :machine_ids, :child_ids, :created_at, :updated_at
json.space_files_attributes @space.space_files do |f|
  json.id f.id
  json.attachment_name f.attachment_identifier
  json.attachment_url f.attachment_url
end

if @space.parent
  json.parent do
    json.name @space.parent.name
  end
end
json.children @space.children do |child|
  json.name child.name
end
