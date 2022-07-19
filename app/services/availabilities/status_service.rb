# frozen_string_literal: true

# Provides helper methods checking reservation status of any availabilities
class Availabilities::StatusService
  def initialize(current_user_role)
    @current_user_role = current_user_role
    @show_name = (%w[admin manager].include?(@current_user_role) || (current_user_role && Setting.get('display_name_enable')))
  end

  # check that the provided slot is reserved for the given reservable (machine, training or space).
  # Mark it accordingly for display in the calendar
  def slot_reserved_status(slot, user, reservables)
    if reservables.map(&:class).map(&:name).uniq.size > 1
      raise TypeError('[Availabilities::StatusService#slot_reserved_status] reservables have differents types')
    end

    statistic_profile_id = user&.statistic_profile&.id

    slots_reservations = slot.slots_reservations
                             .includes(:reservation)
                             .where('reservations.reservable_type': reservables.map(&:class).map(&:name))
                             .where('reservations.reservable_id': reservables.map(&:id))
                             .where('slots_reservations.canceled_at': nil)

    user_slots_reservations = slots_reservations.where('reservations.statistic_profile_id': statistic_profile_id)

    slot.is_reserved = !user_slots_reservations.empty?
    slot.title = slot_title(slots_reservations, user_slots_reservations, reservables)
    slot.can_modify = true if %w[admin manager].include?(@current_user_role) || !user_slots_reservations.empty?
    slot.current_user_slots_reservations_ids = user_slots_reservations.map(&:id)

    slot
  end

  # check that the provided ability is reserved by the given user
  def availability_reserved_status(availability, user, reservables)
    if reservables.map(&:class).map(&:name).uniq.size > 1
      raise TypeError('[Availabilities::StatusService#availability_reserved_status] reservables have differents types')
    end

    slots_reservations = availability.slots_reservations
                                     .includes(:reservation)
                                     .where('reservations.reservable_type': reservables.map(&:class).map(&:name))
                                     .where('reservations.reservable_id': reservables.map(&:id))
                                     .where('slots_reservations.canceled_at': nil)

    user_slots_reservations = slots_reservations.where('reservations.statistic_profile_id': user&.statistic_profile&.id)

    availability.is_reserved = !user_slots_reservations.empty?
    availability.current_user_slots_reservations_ids = user_slots_reservations.map(&:id)
    availability
  end

  private

  def slot_title(slots_reservations, user_slots_reservations, reservables)
    name = reservables.map(&:name).join(', ')
    if user_slots_reservations.empty? && slots_reservations.empty?
      name
    elsif user_slots_reservations.empty? && !slots_reservations.empty?
      user_names = slots_reservations.map(&:reservation)
                                     .map(&:user)
                                     .map { |u| u&.profile&.full_name || I18n.t('availabilities.deleted_user') }
                                     .join(', ')
      "#{name} - #{@show_name ? user_names : I18n.t('availabilities.not_available')}"
    else
      "#{name} - #{I18n.t('availabilities.i_ve_reserved')}"
    end
  end
end
