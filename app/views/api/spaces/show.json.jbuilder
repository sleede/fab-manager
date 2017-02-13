json.extract! @space, :id, :name, :description, :characteristics, :created_at, :updated_at
json.space_image @space.space_image.attachment.large.url if @space.space_image
json.space_files_attributes @space.space_files do |f|
  json.id f.id
  json.attachment f.attachment_identifier
  json.attachment_url f.attachment_url
end