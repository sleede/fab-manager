# frozen_string_literal: true

json.array!(@users) do |user|
  json.extract! user, :id, :email
  json.name user.profile.full_name
  json.profile_attributes do
    json.extract! user.profile, :first_name, :last_name, :phone
  end
  json.resource user.roles.last.resource
end
