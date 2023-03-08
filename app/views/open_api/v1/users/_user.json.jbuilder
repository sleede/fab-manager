# frozen_string_literal: true

json.extract! user, :id, :email, :created_at
json.extract! user.profile, :full_name, :first_name, :last_name if user.association(:profile).loaded?
json.gender user.statistic_profile.gender ? 'man' : 'woman'

if user.association(:invoicing_profile).loaded?
  json.invoicing_profile_id user.invoicing_profile.id
  json.external_id user.invoicing_profile.external_id
  json.organization !user.invoicing_profile.organization.nil?
  json.address user.invoicing_profile.invoicing_address
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
