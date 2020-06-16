# frozen_string_literal: true

requested_current = (current_user and current_user.id == @member.id)

json.partial! 'api/members/member', member: @member
json.extract! @member, :uid, :slug, :is_allow_contact, :is_allow_newsletter

json.training_ids @member.statistic_profile.training_ids
json.trainings @member.trainings do |t|
  json.id t.id
  json.name t.name
end
json.training_reservations @member.reservations.where(reservable_type: 'Training') do |r|
  json.id r.id
  json.start_at r.slots.first.start_at
  json.end_at r.slots.first.end_at
  json.reservable r.reservable
  json.reservable_type 'Training'
  json.is_valid @member.statistic_profile.training_ids.include?(r.reservable_id)
  json.canceled_at r.slots.first.canceled_at
end
json.machine_reservations @member.reservations.where(reservable_type: 'Machine') do |r|
  json.id r.id
  json.start_at r.slots.first.start_at
  json.end_at r.slots.first.end_at
  json.reservable r.reservable
  json.reservable_type 'Machine'
  json.canceled_at r.slots.first.canceled_at
end
json.space_reservations @member.reservations.where(reservable_type: 'Space') do |r|
  json.id r.id
  json.start_at r.slots.first.start_at
  json.end_at r.slots.first.end_at
  json.reservable r.reservable
  json.reservable_type 'Space'
  json.canceled_at r.slots.first.canceled_at
end

json.all_projects @member.all_projects do |project|
  if requested_current || project.state == 'published'
    json.extract! project, :id, :name, :description, :licence_id, :slug, :state
    json.author_id project.author.user_id
    
    json.project_image project.project_image.attachment.large.url if project.project_image
    json.machine_ids project.machine_ids
    json.machines project.machines do |m|
      json.id m.id
      json.name m.name
    end
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
      if pu.user.profile.user_avatar
        json.user_avatar do
          json.id pu.user.profile.user_avatar.id
          json.attachment_url pu.user.profile.user_avatar.attachment_url
        end
      end
      json.username pu.user.username
      json.is_valid pu.is_valid
      json.valid_token pu.valid_token if !pu.is_valid && @member == pu.user
    end
  end
end
json.events_reservations @member.reservations.where(reservable_type: 'Event').joins(:slots).order('slots.start_at asc') do |r|
  json.id r.id
  json.start_at r.slots.first.start_at
  json.end_at r.slots.first.end_at
  json.nb_reserve_places r.nb_reserve_places
  json.tickets r.tickets do |t|
    json.booked t.booked
    json.price_category do
      json.name t.event_price_category.price_category.name
    end
  end
  json.reservable r.reservable
  json.reservable_type 'Event'
end
json.invoices @member.invoices.order('reference DESC') do |i|
  json.id i.id
  json.reference i.reference
  json.type i.invoiced_type
  json.invoiced_id i.invoiced_id
  json.total i.total / 100.00
  json.is_avoir i.is_a?(Avoir)
  json.date i.is_a?(Avoir) ? i.avoir_date : i.created_at
end
json.tag_ids @member.tag_ids
json.tags @member.tags do |t|
  json.id t.id
  json.name t.name
end
json.merged_at @member.merged_at
