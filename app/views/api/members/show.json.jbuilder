# frozen_string_literal: true

requested_current = (current_user and current_user.id == @member.id)

json.partial! 'api/members/member', member: @member
json.extract! @member, :uid, :slug, :is_allow_contact, :is_allow_newsletter

json.training_ids @member.statistic_profile.training_ids
json.trainings @member.trainings do |t|
  json.id t.id
  json.name t.name
end
reservations = @member.reservations.where(reservable_type: 'Training').preload(slots_reservations: [:slot, reservation: :reservable])
json.training_reservations reservations.select { |r| r.reservable_type == "Training" }.map(&:slots_reservations).flatten do |sr|
  json.id sr.id
  json.start_at sr.slot.start_at
  json.end_at sr.slot.end_at
  json.reservable sr.reservation.reservable
  json.reservable_type 'Training'
  json.is_valid @member.statistic_profile.training_ids.include?(sr.reservation.reservable_id)
  json.canceled_at sr.canceled_at
end
json.machine_reservations reservations.select { |r| r.reservable_type == "Machine" }.map(&:slots_reservations).flatten do |sr|
  json.id sr.id
  json.start_at sr.slot.start_at
  json.end_at sr.slot.end_at
  json.reservable sr.reservation.reservable
  json.reservable_type 'Machine'
  json.canceled_at sr.canceled_at
end
json.space_reservations reservations.select { |r| r.reservable_type == "Space" }.map(&:slots_reservations).flatten do |sr|
  json.id sr.id
  json.start_at sr.slot.start_at
  json.end_at sr.slot.end_at
  json.reservable sr.reservation.reservable
  json.reservable_type 'Space'
  json.canceled_at sr.canceled_at
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
json.events_reservations @member.reservations.where(reservable_type: 'Event').joins(:slots).order('slots.start_at asc').map(&:slots_reservations).flatten do |sr|
  json.id sr.id
  json.start_at sr.slot.start_at
  json.end_at sr.slot.end_at
  json.nb_reserve_places sr.reservation.nb_reserve_places
  json.tickets sr.reservation.tickets do |t|
    json.booked t.booked
    json.event_price_category_id t.event_price_category_id
    json.price_category do
      json.name t.event_price_category.price_category.name
    end
  end
  json.reservable sr.reservation.reservable
  json.reservable_type 'Event'
  json.event_type sr.reservation.reservable.event_type
  json.event_title sr.reservation.reservable.title
  json.event_pre_registration sr.reservation.reservable.pre_registration
  json.is_valid sr.is_valid
  json.is_paid sr.is_confirm
  json.amount sr.reservation.invoice_items.sum(:amount)
  json.canceled_at sr.canceled_at
  json.booking_users_attributes sr.reservation.booking_users.order(booked_type: :desc) do |bu|
    json.id bu.id
    json.name bu.name
    json.event_price_category_id bu.event_price_category_id
    json.booked_id bu.booked_id
    json.booked_type bu.booked_type
  end
end
json.invoices @member.invoices.order('reference DESC') do |i|
  json.id i.id
  json.reference i.reference
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
if @operator.privileged?
  json.profile_attributes do
    json.note @member.profile.note
  end
end
