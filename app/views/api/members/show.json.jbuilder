json.extract! @member, :id, :username, :email, :group_id, :slug, :invoicing_disabled, :is_allow_contact
json.role @member.roles.first.name
json.name @member.profile.full_name
json.need_completion @member.need_completion?
json.profile do
  json.id @member.profile.id
  json.user_avatar do
    json.id @member.profile.user_avatar.id
    json.attachment_url @member.profile.user_avatar.attachment_url
  end if @member.profile.user_avatar
  json.first_name @member.profile.first_name
  json.last_name @member.profile.last_name
  json.gender @member.profile.gender.to_s
  json.birthday @member.profile.birthday.to_date.iso8601 if @member.profile.birthday
  json.interest @member.profile.interest
  json.software_mastered @member.profile.software_mastered
  json.address do
    json.id @member.profile.address.id
    json.address @member.profile.address.address
  end if @member.profile.address
  json.phone @member.profile.phone
  json.website @member.profile.website
  json.extract! @member.profile, :facebook, :twitter, :google_plus, :viadeo, :linkedin, :instagram, :youtube, :vimeo, :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr
end
json.subscribed_plan do
  json.partial! 'api/shared/plan', plan: @member.subscribed_plan
end if @member.subscribed_plan
json.subscription do
  json.id @member.subscription.id
  json.expired_at @member.subscription.expired_at.iso8601
  json.canceled_at @member.subscription.canceled_at.iso8601 if @member.subscription.canceled_at
  json.stripe @member.subscription.stp_subscription_id.present?
  json.plan do
    json.id @member.subscription.plan.id
    json.base_name @member.subscription.plan.base_name
    json.name @member.subscription.plan.name
    json.interval @member.subscription.plan.interval
    json.interval_count @member.subscription.plan.interval_count
    json.amount @member.subscription.plan.amount ? (@member.subscription.plan.amount / 100.0) : 0
  end
end if @member.subscription
json.training_ids @member.training_ids
json.trainings @member.trainings do |t|
  json.id t.id
  json.name t.name
end
json.training_reservations @member.reservations.where(reservable_type: 'Training') do |r|
  json.id r.id
  json.start_at r.slots.first.start_at
  json.end_at r.slots.first.end_at
  json.reservable r.reservable
  json.is_valid @member.training_ids.include?(r.reservable.id)
  json.canceled_at r.slots.first.canceled_at
end
json.training_credits @member.training_credits do |tc|
  json.training_id tc.creditable_id
end
json.machine_credits @member.machine_credits do |mc|
  json.machine_id mc.creditable_id
  json.hours_used mc.users_credits.find_by_user_id(@member.id).hours_used
end
json.last_sign_in_at @member.last_sign_in_at.iso8601 if @member.last_sign_in_at
json.all_projects @member.all_projects do |project|
  json.extract! project, :id, :name, :description, :author_id, :licence_id, :slug
  json.url project_url(project, format: :json)
  json.project_image project.project_image.attachment.large.url if project.project_image
  json.machine_ids project.machine_ids
  json.machines project.machines do |m|
    json.id m.id
    json.name m.name
  end
  json.author_id project.author_id
  json.user_ids project.user_ids
  json.component_ids project.component_ids
  json.components project.components do |c|
    json.id c.id
    json.name c.name
  end
  json.project_users project.project_users do |pu|
    json.id pu.user.id
    json.first_name pu.user.profile.first_name
    json.last_name pu.user.profile.last_name
    json.full_name pu.user.profile.full_name
    json.user_avatar do
      json.id pu.user.profile.user_avatar.id
      json.attachment_url pu.user.profile.user_avatar.attachment_url
    end if pu.user.profile.user_avatar
    json.username pu.user.username
    json.is_valid pu.is_valid
    json.valid_token pu.valid_token if !pu.is_valid and @member == pu.user
  end
end
json.events_reservations @member.reservations.where(reservable_type: 'Event').joins(:slots).order('slots.start_at asc') do |r|
  json.id r.id
  json.start_at r.slots.first.start_at
  json.end_at r.slots.first.end_at
  json.nb_reserve_places r.nb_reserve_places
  json.nb_reserve_reduced_places r.nb_reserve_reduced_places
  json.reservable r.reservable
end
json.invoices @member.invoices.order('reference DESC') do |i|
  json.id i.id
  json.reference i.reference
  json.type i.invoiced_type
  json.invoiced_id i.invoiced_id
  json.total (i.total / 100.00)
  json.is_avoir i.is_a?(Avoir)
  json.date i.is_a?(Avoir) ? i.avoir_date : i.created_at
end
json.tag_ids @member.tag_ids
json.tags @member.tags do |t|
  json.id t.id
  json.name t.name
end
json.merged_at @member.merged_at
