json.extract! @project, :id, :name, :description, :tags, :created_at, :updated_at, :author_id, :licence_id, :slug
json.project_image @project.project_image.attachment.large.url if @project.project_image
json.author do
  json.id @project.author_id
  json.first_name @project.author.profile.first_name
  json.last_name @project.author.profile.last_name
  json.full_name @project.author.profile.full_name
  json.user_avatar do
    json.id @project.author.profile.user_avatar.id
    json.attachment_url @project.author.profile.user_avatar.attachment_url
  end if @project.author.profile.user_avatar
  json.username @project.author.username
  json.slug @project.author.slug
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
json.user_ids @project.user_ids
json.project_users @project.project_users do |pu|
  json.id pu.user.id
  json.first_name pu.user.profile.first_name
  json.last_name pu.user.profile.last_name
  json.full_name pu.user.profile.full_name
  json.user_avatar do
    json.id pu.user.profile.user_avatar.id
    json.attachment_url pu.user.profile.user_avatar.attachment_url
  end if pu.user.profile.user_avatar
  json.username pu.user.username
  json.slug pu.user.slug
  json.is_valid pu.is_valid
end
json.project_steps_attributes @project.project_steps.order('project_steps.created_at ASC') do |s|
  json.id s.id
  json.description s.description
  json.title s.title
  json.project_step_image s.project_step_image.attachment_identifier if s.project_step_image
  json.project_step_image_url s.project_step_image.attachment_url if s.project_step_image
end
json.state @project.state
