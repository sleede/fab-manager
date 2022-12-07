# frozen_string_literal: true

json.extract! user, :id, :email, :created_at, :external_id
json.full_name user.profile.full_name if user.association(:profile).loaded?
json.gender user.statistic_profile.gender ? 'man' : 'woman'
json.organization !user.invoicing_profile.organization.nil?
json.address user.invoicing_profile.invoicing_address

if user.association(:group).loaded?
  json.group do
    if user.group_id?
      json.extract! user.group, :id, :name, :slug
    else
      json.nil!
    end
  end
end
