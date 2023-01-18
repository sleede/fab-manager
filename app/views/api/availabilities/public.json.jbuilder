# frozen_string_literal: true

json.array!(@availabilities) do |availability|
  json.id availability.id
  json.start availability.start_at.iso8601
  json.end availability.end_at.iso8601
  json.textColor 'black'
  json.backgroundColor 'white'
  # availability object (for weeks/months views)
  if availability.instance_of? Availability
    json.title availability.title(@title_filter)
    json.event_id availability.event.id if availability.available_type == 'event'
    json.training_id availability.trainings.first.id if availability.available_type == 'training'
    json.space_id availability.spaces.first.id if availability.available_type == 'space'
    json.machines_ids availability.machines.map(&:id) if availability.available_type == 'machines'
    json.available_type availability.available_type
    json.tag_ids availability.tag_ids
    json.tags availability.tags do |t|
      json.id t.id
      json.name t.name
    end

    json.is_completed availability.full?
    json.is_reserved availability.reserved?
    json.borderColor availability_border_color(availability)
    if availability.reserved? && !@user.nil? && availability.reserved_users.include?(@user.id)
      json.title "#{availability.title}' - #{t('trainings.i_ve_reserved')}"
    elsif availability.full?
      json.title "#{availability.title} - #{t('trainings.completed')}"
      json.borderColor AvailabilityHelper::IS_FULL
    end

  # slot object ( here => availability = slot ), for daily view
  elsif availability.instance_of? Slot
    json.title availability.title
    json.tag_ids availability.availability.tag_ids
    json.tags availability.availability.tags do |t|
      json.id t.id
      json.name t.name
    end
    json.is_reserved availability.reserved?
    json.is_completed availability.full?
    case availability.availability.available_type
    when 'machines'
      json.machine_ids availability.availability.machines.map(&:id)
      json.borderColor machines_slot_border_color(availability)
    when 'space'
      json.space_id availability.availability.spaces.first.id
      json.borderColor space_slot_border_color(availability)
    when 'training'
      json.training_id availability.availability.trainings.first.id
      json.borderColor trainings_events_border_color(availability.availability)
    when 'event'
      json.event_id availability.availability.event.id
      json.borderColor trainings_events_border_color(availability.availability)
    else
      json.title 'Unknown slot'
    end
  else
    json.title 'Unknown object'
  end
end
