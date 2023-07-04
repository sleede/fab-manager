# frozen_string_literal: true

json.extract! @project, :id, :name, :tags, :created_at, :updated_at, :licence_id, :status_id, :slug
json.description sanitize(@project.description)
json.author_id @project.author.user_id
json.project_image @project.project_image.attachment.large.url if @project.project_image
json.project_full_image @project.project_image.attachment.url if @project.project_image
json.author do
  json.id @project.author.user_id
  json.first_name @project.author&.user&.profile&.first_name
  json.last_name @project.author&.user&.profile&.last_name
  json.full_name @project.author&.user&.profile&.full_name
  if @project.author&.user&.profile&.user_avatar
    json.user_avatar do
      json.id @project.author&.user&.profile&.user_avatar&.id
      json.attachment_url @project.author&.user&.profile&.user_avatar&.attachment_url
    end
  end
  json.username @project.author&.user&.username
  json.slug @project.author&.user&.slug
end
json.project_caos_attributes @project.project_caos do |f|
  json.id f.id
  json.attachment f.attachment_identifier
  json.attachment_url f.attachment_url
end
json.machine_ids @project.machine_ids
json.machines @project.machines do |m|
  json.id m.id
  json.name m.name
end
json.component_ids @project.component_ids
json.components @project.components do |c|
  json.id c.id
  json.name c.name
end
json.theme_ids @project.theme_ids
json.themes @project.themes do |t|
  json.id t.id
  json.name t.name
end
json.project_category_ids @project.project_category_ids
json.project_categories @project.project_categories do |t|
  json.id t.id
  json.name t.name
end
json.user_ids @project.user_ids
json.project_users @project.project_users do |pu|
  json.id pu.user.id
  json.first_name pu.user.profile.first_name
  json.last_name pu.user.profile.last_name
  json.full_name pu.user.profile.full_name
  if pu.user.profile.user_avatar
    json.user_avatar do
      json.id pu.user.profile.user_avatar.id
      json.attachment_url pu.user.profile.user_avatar.attachment_url
    end
  end
  json.username pu.user.username
  json.slug pu.user.slug
  json.is_valid pu.is_valid
end
json.project_steps_attributes @project.project_steps.order('project_steps.step_nb ASC') do |s|
  json.id s.id
  json.description sanitize(s.description)
  json.title s.title
  json.project_step_images_attributes s.project_step_images.order('created_at ASC') do |si|
    json.id si.id
    json.attachment si.attachment_identifier
    json.attachment_url si.attachment.medium.url
    json.attachment_full_url si.attachment.url
  end
  json.step_nb s.step_nb
end
json.state @project.state
if @project.licence.present?
  json.licence do
    json.name @project.licence.name
  end
end
json.status @project.status
