module AvailabilityHelper
  MACHINE_COLOR = '#e4cd78'
  TRAINING_COLOR = '#bd7ae9'
  EVENT_COLOR = '#dd7e6b'
  IS_RESERVED_BY_CURRENT_USER = '#b2e774'
  MACHINE_IS_RESERVED_BY_USER = '#1d98ec'
  IS_COMPLETED = '#eeeeee'

  def availability_border_color(availability)
    if availability.available_type == 'machines'
      MACHINE_COLOR
    elsif availability.available_type == 'training'
      TRAINING_COLOR
    else
      EVENT_COLOR
    end
  end

  def machines_slot_border_color(slot)
    slot.is_reserved ? (slot.is_reserved_by_current_user ? IS_RESERVED_BY_CURRENT_USER : IS_COMPLETED) : MACHINE_COLOR
  end

  def trainings_events_border_color(availability)
    if availability.is_reserved
      IS_RESERVED_BY_CURRENT_USER
    elsif availability.is_completed
      IS_COMPLETED
    else
      if availability.available_type == 'training'
        TRAINING_COLOR
      else
        EVENT_COLOR
      end
    end
  end
end
