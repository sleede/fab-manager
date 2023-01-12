# frozen_string_literal: true

# Provides helper methods checking reservation status of any availabilities
class Availabilities::StatusService
  # @param current_user_role [String]
  def initialize(current_user_role)
    @current_user_role = current_user_role
    @show_name = (%w[admin manager].include?(@current_user_role) || (current_user_role && Setting.get('display_name_enable')))
  end

  # check that the provided slot is reserved for the given reservable (machine, training or space).
  # Mark it accordingly for display in the calendar
  # @param slot [Slot]
  # @param user [User] the customer
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @return [Slot]
  def slot_reserved_status(slot, user, reservables)
    if reservables.map(&:class).map(&:name).uniq.size > 1
      raise TypeError('[Availabilities::StatusService#slot_reserved_status] reservables have differents types: ' \
                      "#{reservables.map(&:class).map(&:name).uniq} , with slot #{slot.id}")
    end

    places = places(slot, reservables)
    is_reserved = places.any? { |p| p['reserved_places'].positive? }
    is_reserved_by_user = is_reserved && places.select { |p| p['user_ids'].include?(user.id) }.length.positive?
    slot.is_reserved = is_reserved
    slot.title = slot_title(slot, is_reserved, is_reserved_by_user, reservables)
    slot.can_modify = true if %w[admin manager].include?(@current_user_role) || is_reserved
    if is_reserved_by_user
      user_reservations = Slots::ReservationsService.user_reservations(slot, user, reservables.first.class.name)

      slot.current_user_slots_reservations_ids = user_reservations[:reservations].select('id').map(&:id)
      slot.current_user_pending_reservations_ids = user_reservations[:pending].select('id').map(&:id)
    end
    slot
  end

  # check that the provided ability is reserved by the given user
  # @param availability [Availability]
  # @param user [User] the customer
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @return [Availability]
  def availability_reserved_status(availability, user, reservables)
    if reservables.map(&:class).map(&:name).uniq.size > 1
      raise TypeError('[Availabilities::StatusService#availability_reserved_status] reservables have differents types: ' \
                      "#{reservables.map(&:class).map(&:name).uniq}, with availability #{availability.id}")
    end

    slots = availability.slots.map do |slot|
      slot_reserved_status(slot, user, reservables)
    end

    availability.is_reserved = slots.any?(&:is_reserved)
    availability.current_user_slots_reservations_ids = slots.map(&:current_user_slots_reservations_ids).flatten
    availability.current_user_pending_reservations_ids = slots.map(&:current_user_pending_reservations_ids).flatten
    availability
  end

  private

  # @param slot [Slot]
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @return [Array<Hash>]
  def places(slot, reservables)
    places = []
    reservables.each do |reservable|
      places.push(slot.places.detect { |p| p['reservable_type'] == reservable.class.name && p['reservable_id'] == reservable.id })
    end
    places
  end

  # @param slot [Slot]
  # @param is_reserved [Boolean]
  # @param is_reserved_by_user [Boolean]
  # @param reservables [Array<Machine, Space, Training, Event>]
  def slot_title(slot, is_reserved, is_reserved_by_user, reservables)
    name = reservables.map(&:name).join(', ')
    if !is_reserved && !is_reserved_by_user
      name
    elsif is_reserved && !is_reserved_by_user
      "#{name} #{@show_name ? "- #{slot_users_names(slot, reservables)}" : ''}"
    else
      "#{name} - #{I18n.t('availabilities.i_ve_reserved')}"
    end
  end

  # @param slot [Slot]
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @return [String]
  def slot_users_names(slot, reservables)
    user_ids = slot.places
                   .select { |p| p['reservable_type'] == reservables.first.class.name && reservables.map(&:id).includes?(p['reservable_id']) }
                   .pluck('user_ids')
                   .flatten
    User.where(id: user_ids).includes(:profile)
        .map { |u| u&.profile&.full_name || I18n.t('availabilities.deleted_user') }
        .join(', ')
  end
end
