json.array!(@availabilities) do |availability|
  json.id availability.id
  json.start availability.start_at.iso8601
  json.end availability.end_at.iso8601
  json.textColor 'black'
  json.backgroundColor 'white'
  # availability object
  if availability.instance_of? Availability
    json.title availability.title(@title_filter)
    if availability.available_type == 'event'
      json.event_id availability.event.id
    end
    if availability.available_type == 'training'
      json.training_id availability.trainings.first.id
    end
    json.available_type availability.available_type
    json.tag_ids availability.tag_ids
    json.tags availability.tags do |t|
      json.id t.id
      json.name t.name
    end

    if availability.available_type == 'training' or availability.available_type == 'event'
      json.borderColor trainings_events_border_color(availability)
      if availability.is_reserved
        json.is_reserved true
        json.title "#{availability.title}' - #{t('trainings.i_ve_reserved')}"
      elsif availability.is_completed
        json.is_completed true
        json.title "#{availability.title} - #{t('trainings.completed')}"
      end
    elsif availability.available_type == 'space'
      complete = availability.slots.length >= availability.available_space_places
      json.is_completed complete
      json.borderColor availability_border_color(availability)
      if complete
        json.title "#{availability.title} - #{t('trainings.completed')}"
        json.borderColor AvailabilityHelper::IS_COMPLETED
      end
      if availability.is_reserved
        json.is_reserved true
        json.title "#{availability.title} - #{t('trainings.i_ve_reserved')}"
      end
    else
      json.borderColor availability_border_color(availability)
    end

  # slot object ( here => availability = slot )
  # -> machines / spaces
  elsif availability.instance_of? Slot
    json.title availability.title
    json.tag_ids availability.availability.tag_ids
    json.tags availability.availability.tags do |t|
      json.id t.id
      json.name t.name
    end
    if availability.try(:machine)
      json.machine_id availability.machine.id
      json.borderColor machines_slot_border_color(availability)
      json.is_reserved availability.is_reserved
    elsif availability.try(:space)
      json.space_id availability.space.id
      json.borderColor space_slot_border_color(availability)
      json.is_completed availability.is_complete?
    else
      json.title 'Unknown slot'
    end
  else
    json.title 'Unknown object'
  end
end
