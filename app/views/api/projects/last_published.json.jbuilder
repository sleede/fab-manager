# frozen_string_literal: true

json.array!(@projects) do |project|
  json.extract! project, :id, :name, :description, :slug
  
  json.project_image project.project_image.attachment.large.url if project.project_image
end
