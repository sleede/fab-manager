json.extract! @machine, :id, :name, :description, :spec, :created_at, :updated_at
json.machine_image @machine.machine_image.attachment.large.url if @machine.machine_image
json.machine_files_attributes @machine.machine_files do |f|
  json.id f.id
  json.attachment f.attachment_identifier
  json.attachment_url f.attachment_url
end

json.machine_projects @machine.projects.published.last(10) do |p|
  json.id p.id
  json.name p.name
  json.slug p.slug
end
