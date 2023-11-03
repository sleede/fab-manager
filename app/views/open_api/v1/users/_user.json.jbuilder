# frozen_string_literal: true

json.id user.user_id || user.id
json.extract! user, :email, :full_name, :first_name, :last_name, :created_at
if user.user
  json.gender user.user.statistic_profile.gender ? 'man' : 'woman'
else
  json.gender 'man'
end

json.invoicing_profile_id user.id
json.external_id user.external_id
json.organization !user.organization.nil?
json.address user.invoicing_address

if user&.user&.group
  json.group do
    if user.user.group_id?
      json.extract! user.user.group, :id, :name, :slug
    else
      json.nil!
    end
  end
end
