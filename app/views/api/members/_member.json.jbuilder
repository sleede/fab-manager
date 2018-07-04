json.extract! member, :id, :username, :email, :group_id
json.role member.roles.first.name
json.name member.profile.full_name
json.need_completion member.need_completion?
json.profile do
  json.id member.profile.id
  json.user_avatar do
    json.id member.profile.user_avatar.id
    json.attachment_url member.profile.user_avatar.attachment_url
  end if member.profile.user_avatar
  json.first_name member.profile.first_name
  json.last_name member.profile.last_name
  json.gender member.profile.gender.to_s
  json.birthday member.profile.birthday.to_date.iso8601 if member.profile.birthday
  json.interest member.profile.interest
  json.software_mastered member.profile.software_mastered
  json.address do
    json.id member.profile.address.id
    json.address member.profile.address.address
  end if member.profile.address
  json.phone member.profile.phone
  json.website member.profile.website
  json.job member.profile.job
  json.extract! member.profile, :facebook, :twitter, :google_plus, :viadeo, :linkedin, :instagram, :youtube, :vimeo, :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr
  json.organization do
    json.id member.profile.organization.id
    json.name member.profile.organization.name
    json.address do
      json.id member.profile.organization.address.id
      json.address member.profile.organization.address.address
    end if member.profile.organization.address
  end if member.profile.organization

end
json.subscribed_plan do
  json.partial! 'api/shared/plan', plan: member.subscribed_plan
end if member.subscribed_plan
json.subscription do
  json.id member.subscription.id
  json.expired_at member.subscription.expired_at.iso8601
  json.canceled_at member.subscription.canceled_at.iso8601 if member.subscription.canceled_at
  json.stripe member.subscription.stp_subscription_id.present?
  json.plan do
    json.id member.subscription.plan.id
    json.base_name member.subscription.plan.base_name
    json.name member.subscription.plan.name
    json.interval member.subscription.plan.interval
    json.interval_count member.subscription.plan.interval_count
    json.amount member.subscription.plan.amount ? (member.subscription.plan.amount / 100.0) : 0
  end
end if member.subscription
json.training_credits member.training_credits do |tc|
  json.training_id tc.creditable_id
end
json.machine_credits member.machine_credits do |mc|
  json.machine_id mc.creditable_id
  json.hours_used mc.users_credits.find_by(user_id: member.id).hours_used
end
json.last_sign_in_at member.last_sign_in_at.iso8601 if member.last_sign_in_at
