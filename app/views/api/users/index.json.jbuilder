# frozen_string_literal: true

json.users @users do |user|
  json.extract! user, :id, :email, :first_name, :last_name
  json.phone user.profile.phone
  json.name user.profile.full_name
  json.resource user.roles.last.resource
end
