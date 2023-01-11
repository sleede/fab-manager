# frozen_string_literal: true

# Provides helper methods checking reservation status of any availabilities
class Availabilities::StatusService
  def initialize(current_user_role)
    @current_user_role = current_user_role
    @show_name = (%w[admin manager].include?(@current_user_role) || (current_user_role && Setting.get('display_name_enable')))
  end

  # check that the provided slot is reserved for the given reservable (machine, training or space).
  # Mark it accordingly for display in the calendar
  # @param slot [Slot]
  # @param user [User]
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @return [Slot]
  def slot_reserved_status(slot, user, reservables)
    if reservables.map(&:class).map(&:name).uniq.size > 1
      raise TypeError('[Availabilities::StatusService#slot_reserved_status] reservables have differents types: ' \
                      "#{reservables.map(&:class).map(&:name).uniq} , with slot #{slot.id}")
    end

    slots_reservations, user_slots_reservations = slots_reservations(slot.slots_reservations, reservables, user)

    pending_reserv_slot_ids = slot.cart_item_reservation_slots.select('id').map(&:id)
    pending_reservations, user_pending_reservations = pending_reservations(pending_reserv_slot_ids, reservables, user)

    is_reserved = slots_reservations.count.positive? || pending_reservations.count.positive?
    slot.is_reserved = is_reserved
    slot.title = slot_title(slots_reservations, user_slots_reservations, user_pending_reservations, reservables)
    slot.can_modify = true if %w[admin manager].include?(@current_user_role) || is_reserved
    slot.current_user_slots_reservations_ids = user_slots_reservations.select('id').map(&:id)
    slot.current_user_pending_reservations_ids = user_pending_reservations.select('id').map(&:id)

    slot
  end

  # check that the provided ability is reserved by the given user
  # @param availability [Availability]
  # @param user [User]
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @return [Availability]
  def availability_reserved_status(availability, user, reservables)
    if reservables.map(&:class).map(&:name).uniq.size > 1
      raise TypeError('[Availabilities::StatusService#availability_reserved_status] reservables have differents types: ' \
                      "#{reservables.map(&:class).map(&:name).uniq}, with availability #{availability.id}")
    end

    slots_reservations, user_slots_reservations = slots_reservations(availability.slots_reservations, reservables, user)

    pending_reserv_slot_ids = availability.joins(slots: :cart_item_reservation_slots)
                                          .select('cart_item_reservation_slots.id as cirs_id')
    pending_reservations, user_pending_reservations = pending_reservations(pending_reserv_slot_ids, reservables, user)

    availability.is_reserved = slots_reservations.count.positive? || pending_reservations.count.positive?
    availability.current_user_slots_reservations_ids = user_slots_reservations.select('id').map(&:id)
    availability.current_user_pending_reservations_ids = user_pending_reservations.select('id').map(&:id)
    availability
  end

  private

  # @param slots_reservations [ActiveRecord::Relation<SlotsReservation>]
  # @param user_slots_reservations [ActiveRecord::Relation<SlotsReservation>] same as slots_reservations but filtered by the current user
  # @param user_pending_reservations [ActiveRecord::Relation<CartItem::ReservationSlot>]
  # @param reservables [Array<Machine, Space, Training, Event>]
  def slot_title(slots_reservations, user_slots_reservations, user_pending_reservations, reservables)
    name = reservables.map(&:name).join(', ')
    if user_slots_reservations.count.zero? && slots_reservations.count.zero?
      name
    elsif user_slots_reservations.count.zero? && slots_reservations.count.positive?
      "#{name} #{@show_name ? "- #{slot_users_names(slots_reservations)}" : ''}"
    elsif user_pending_reservations.count.positive?
      "#{name} - #{I18n.t('availabilities.reserving')}"
    else
      "#{name} - #{I18n.t('availabilities.i_ve_reserved')}"
    end
  end

  # @param slots_reservations [ActiveRecord::Relation<SlotsReservation>]
  # @return [String]
  def slot_users_names(slots_reservations)
    slots_reservations.map(&:reservation)
                      .map(&:user)
                      .map { |u| u&.profile&.full_name || I18n.t('availabilities.deleted_user') }
                      .join(', ')
  end

  # @param slot_ids [Array<number>]
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @param user [User]
  # @return [Array<ActiveRecord::Relation<CartItem::ReservationSlot>>]
  def pending_reservations(slot_ids, reservables, user)
    reservable_types = reservables.map(&:class).map(&:name).uniq
    if reservable_types.size > 1
      raise TypeError("[Availabilities::StatusService#pending_reservations] reservables have differents types: #{reservable_types}")
    end

    relation = "cart_item_#{reservable_types.first&.downcase}_reservation"
    table = reservable_types.first == 'Event' ? 'cart_item_event_reservations' : 'cart_item_reservations'
    pending_reservations = CartItem::ReservationSlot.where(id: slot_ids)
                                                    .includes(relation.to_sym)
                                                    .where(table => { reservable_type: reservable_types })
                                                    .where(table => { reservable_id: reservables.map(&:id) })

    user_pending_reservations = pending_reservations.where(table => { customer_profile_id: user&.invoicing_profile&.id })

    [pending_reservations, user_pending_reservations]
  end

  # @param slots_reservations [ActiveRecord::Relation<SlotsReservation>]
  # @param reservables [Array<Machine, Space, Training, Event>]
  # @param user [User]
  # @return [Array<ActiveRecord::Relation<SlotsReservation>>]
  def slots_reservations(slots_reservations, reservables, user)
    reservable_types = reservables.map(&:class).map(&:name).uniq
    if reservable_types.size > 1
      raise TypeError("[Availabilities::StatusService#slot_reservations] reservables have differents types: #{reservable_types}")
    end

    reservations = slots_reservations.includes(:reservation)
                                     .where('reservations.reservable_type': reservable_types)
                                     .where('reservations.reservable_id': reservables.map(&:id))
                                     .where('slots_reservations.canceled_at': nil)

    user_slots_reservations = reservations.where('reservations.statistic_profile_id': user&.statistic_profile&.id)

    [reservations, user_slots_reservations]
  end
end
