json.array!(@members) do |member|
  json.id member.id
  json.username member.username
  json.slug member.slug
  json.name member.profile.full_name
  json.email member.email if current_user
  json.first_name member.profile.first_name
  json.last_name member.profile.last_name
  json.profile do
    json.user_avatar do
      json.id member.profile.user_avatar.id
      json.attachment_url member.profile.user_avatar.attachment_url
    end if member.profile.user_avatar
    json.first_name member.profile.first_name
    json.last_name member.profile.last_name
    json.gender member.profile.gender.to_s
    if current_user and current_user.is_admin?
      json.phone member.profile.phone
      json.birthday member.profile.birthday.iso8601 if member.profile.birthday
    end
  end
  json.group_id member.group_id
  json.group do
    json.id member.group.id
    json.name member.group.name
  end
end
