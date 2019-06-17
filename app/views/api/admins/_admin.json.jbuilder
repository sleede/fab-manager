json.extract! admin, :id, :username, :email, :group_id, :slug
json.profile_attributes do
  json.id admin.profile.id
  json.first_name admin.profile.first_name
  json.last_name admin.profile.last_name
  json.gender admin.statistic_profile.gender
  json.birthday admin.statistic_profile.birthday if admin.statistic_profile.birthday
  json.phone admin.profile.phone
  if admin.profile.user_avatar
    json.user_avatar do
      json.id admin.profile.user_avatar.id
      json.attachment_url admin.profile.user_avatar.attachment_url
    end
  end
end
