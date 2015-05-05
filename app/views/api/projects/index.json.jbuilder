json.array!(@projects) do |project|
  json.extract! project, :id, :name, :description, :author_id, :licence_id, :slug
  json.url project_url(project, format: :json)
  json.project_image project.project_image.attachment.medium.url if project.project_image
  json.machine_ids project.machine_ids
  json.author_id project.author_id
  json.user_ids project.user_ids
  json.theme_ids project.theme_ids
  json.component_ids project.component_ids
end
