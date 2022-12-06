# frozen_string_literal: true

json.extract! user, :id, :email, :created_at, :external_id

json.full_name user.profile.full_name if user.association(:profile).loaded?

if user.association(:group).loaded?
  json.group do
    if user.group_id?
      json.extract! user.group, :id, :name, :slug
    else
      json.nil!
    end
  end
end
