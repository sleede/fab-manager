# frozen_string_literal: true

json.id project.id
json.state project.state
json.author_id project.author.user_id
json.user_ids project.user_ids
json.machine_ids project.machine_ids
json.theme_ids project.theme_ids
json.component_ids project.component_ids
json.tags project.tags
json.name project.name
json.description project.description
json.project_steps project.project_steps do |project_step|
  json.title project_step.title
  json.description project_step.description
end
json.created_at project.created_at
json.updated_at project.updated_at
