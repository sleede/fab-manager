# frozen_string_literal: true

json.extract! member, :id, :username, :email, :group_id
json.role member.roles.first.name
json.name member.profile.full_name
json.need_completion member.need_completion?
json.ip_address member.current_sign_in_ip.to_s
json.mapped_from_sso member.mapped_from_sso&.split(',')

json.profile_attributes do
  json.extract! member.profile, :id, :first_name, :last_name, :interest, :software_mastered, :phone, :website, :job
  if member.profile.user_avatar
    json.user_avatar_attributes do
      json.id member.profile.user_avatar.id
      json.attachment_url "#{member.profile.user_avatar.attachment_url}?#{member.profile.user_avatar.updated_at.to_i}"
    end
  end
  json.extract! member.profile, :facebook, :twitter, :viadeo, :linkedin, :instagram, :youtube, :vimeo, :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr
  json.tours member.profile.tours&.split || []
end

json.invoicing_profile_attributes do
  json.id member.invoicing_profile.id
  if member.invoicing_profile.address
    json.address_attributes do
      json.id member.invoicing_profile.address.id
      json.address member.invoicing_profile.address.address
    end
  end

  if member.invoicing_profile.organization
    json.organization_attributes do
      json.extract! member.invoicing_profile.organization, :id, :name
      if member.invoicing_profile.organization.address
        json.address_attributes do
          json.id member.invoicing_profile.organization.address.id
          json.address member.invoicing_profile.organization.address.address
        end
      end
    end
  end
end

json.statistic_profile_attributes do
  json.id member.statistic_profile.id
  json.gender member.statistic_profile.gender.to_s
  json.birthday member.statistic_profile&.birthday&.to_date&.iso8601
  json.training_ids member.statistic_profile&.training_ids
end

if member.subscribed_plan
  json.subscribed_plan do
    json.partial! 'api/shared/plan', plan: member.subscribed_plan
  end
end

if member.subscription
  json.subscription do
    json.id member.subscription.id
    json.expired_at member.subscription.expired_at.iso8601
    json.canceled_at member.subscription.canceled_at.iso8601 if member.subscription.canceled_at
    json.plan do # TODO, refactor: duplicates subscribed_plan
      json.id member.subscription.plan.id
      json.base_name member.subscription.plan.base_name
      json.name member.subscription.plan.name
      json.interval member.subscription.plan.interval
      json.interval_count member.subscription.plan.interval_count
      json.amount member.subscription.plan.amount ? (member.subscription.plan.amount / 100.0) : 0
      json.monthly_payment member.subscription.plan.monthly_payment
    end
  end
end
json.training_credits member.training_credits do |tc|
  json.training_id tc.creditable_id
end
json.machine_credits member.machine_credits do |mc|
  json.machine_id mc.creditable_id
  json.hours_used mc.users_credits.find_by(user_id: member.id).hours_used
end
# TODO, missing space_credits?
json.last_sign_in_at member.last_sign_in_at.iso8601 if member.last_sign_in_at

json.validated_at member.validated_at
