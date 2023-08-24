# frozen_string_literal: true

# Helpers methods about calendar availabilities
module AvailabilityHelper
  MACHINE_COLOR = '#e4cd78'
  TRAINING_COLOR = '#bd7ae9'
  SPACE_COLOR = '#3fc7ff'
  EVENT_COLOR = '#dd7e6b'
  IS_RESERVED_BY_CURRENT_USER = '#b2e774'
  IS_FULL = '#eeeeee'
  IS_BLOCKED = '#b2e774' # same color as IS_RESERVED_BY_CURRENT_USER for simplicity

  def availability_border_color(availability)
    case availability.available_type
    when 'machines'
      MACHINE_COLOR
    when 'training'
      TRAINING_COLOR
    when 'space'
      SPACE_COLOR
    else
      EVENT_COLOR
    end
  end

  # @param slot [Slot]
  # @param reservable [Machine]
  # @param customer [User]
  def machines_slot_border_color(slot, reservable = nil, customer = nil)
    if slot.reserved?(reservable)
      slot.reserved_by?(customer&.id, [reservable]) ? IS_RESERVED_BY_CURRENT_USER : IS_FULL
    else
      MACHINE_COLOR
    end
  end

  def space_slot_border_color(slot)
    if slot.reserved?
      IS_RESERVED_BY_CURRENT_USER
    elsif slot.full?
      IS_FULL
    elsif slot.is_blocked
      IS_BLOCKED
    else
      SPACE_COLOR
    end
  end

  def trainings_events_border_color(availability)
    if availability.reserved?
      IS_RESERVED_BY_CURRENT_USER
    elsif availability.full?
      IS_FULL
    else
      case availability.available_type
      when 'training'
        TRAINING_COLOR
      when 'event'
        EVENT_COLOR
      when 'space'
        SPACE_COLOR
      else
        '#000'
      end
    end
  end
end
