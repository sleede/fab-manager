json.extract! user, :id, :email, :created_at

if user.association(:profile).loaded?
  json.full_name user.profile.full_name
end

if user.association(:group).loaded?
  json.group do
    if user.group_id?
      json.extract! user.group, :id, :name, :slug
    else
      json.nil!
    end
  end
end
