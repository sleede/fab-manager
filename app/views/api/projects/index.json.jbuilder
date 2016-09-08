json.projects @projects do |project|
  json.extract! project, :id, :name, :description, :author_id, :licence_id, :slug, :state
  json.url project_url(project, format: :json)
  json.project_image project.project_image.attachment.medium.url if project.project_image
  json.author_id project.author_id
  json.user_ids project.user_ids
end

json.meta do
  json.total @total if @total
end
