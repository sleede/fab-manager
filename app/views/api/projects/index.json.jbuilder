# frozen_string_literal: true

json.projects @projects do |project|
  json.extract! project, :id, :name, :licence_id, :slug, :state
  json.description sanitize(project.description)
  json.author_id project.author.user_id

  json.project_image project.project_image.attachment.medium.url if project.project_image
  json.user_ids project.user_ids
end

json.meta do
  json.total @total if @total
end
