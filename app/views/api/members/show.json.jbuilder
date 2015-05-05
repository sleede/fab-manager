json.extract! @member, :id, :username, :email, :group_id, :slug
json.role @member.roles.first.name
json.name @member.profile.full_name
json.profile do
  json.id @member.profile.id
  json.user_avatar do
    json.id @member.profile.user_avatar.id
    json.attachment_url @member.profile.user_avatar.attachment_url
  end if @member.profile.user_avatar
  json.first_name @member.profile.first_name
  json.last_name @member.profile.last_name
  json.gender @member.profile.gender.to_s
  json.birthday @member.profile.birthday.to_date.iso8601 if @member.profile.birthday
  json.interest @member.profile.interest
  json.software_mastered @member.profile.software_mastered
  json.address do
    json.id @member.profile.address.id
    json.address @member.profile.address.address
  end if @member.profile.address
  json.phone @member.profile.phone
end
json.last_sign_in_at @member.last_sign_in_at.iso8601 if @member.last_sign_in_at
json.all_projects @member.all_projects do |project|
  json.extract! project, :id, :name, :description, :author_id, :licence_id, :slug
  json.url project_url(project, format: :json)
  json.project_image project.project_image.attachment.large.url if project.project_image
  json.machine_ids project.machine_ids
  json.machines project.machines do |m|
    json.id m.id
    json.name m.name
  end
  json.author_id project.author_id
  json.user_ids project.user_ids
  json.component_ids project.component_ids
  json.components project.components do |c|
    json.id c.id
    json.name c.name
  end
  json.project_users project.project_users do |pu|
    json.id pu.user.id
    json.first_name pu.user.profile.first_name
    json.last_name pu.user.profile.last_name
    json.full_name pu.user.profile.full_name
    json.user_avatar do
      json.id pu.user.profile.user_avatar.id
      json.attachment_url pu.user.profile.user_avatar.attachment_url
    end if pu.user.profile.user_avatar
    json.username pu.user.username
    json.is_valid pu.is_valid
    json.valid_token pu.valid_token if !pu.is_valid and @member == pu.user
  end
end
