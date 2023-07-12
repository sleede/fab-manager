# frozen_string_literal: true

# Services around slots
module Slots; end

# Check the reservation status of a slot
class Slots::ReservationsService
  class << self
    # @param slots_reservations [ActiveRecord::Relation<SlotsReservation>]
    # @param reservables [Array<Machine, Space, Training, Event, NilClass>]
    # @return [Hash{Symbol=>ActiveRecord::Relation<SlotsReservation>,Array<Integer>}]
    def reservations(slots_reservations, reservables)
      reservable_types = reservables.map(&:class).map(&:name).uniq
      if reservable_types.size > 1
        raise TypeError("[Availabilities::ReservationsService#reservations] reservables have differents types: #{reservable_types}")
      end

      reservations = slots_reservations.includes(:reservation)
                                       .where('reservations.reservable_type': reservable_types)
                                       .where('reservations.reservable_id': reservables.map { |r| r.try(:id) })
                                       .where('slots_reservations.canceled_at': nil)
      reservations = reservations.where('slots_reservations.is_valid': true) if reservables.first&.pre_registration?

      user_ids = reservations.includes(reservation: :statistic_profile)
                             .map(&:reservation)
                             .map(&:statistic_profile)
                             .map(&:user_id)
                             .filter { |id| !id.nil? }

      {
        reservations: reservations,
        user_ids: user_ids
      }
    end

    # @param cart_item_reservation_slot_ids [Array<number>]
    # @param reservables [Array<Machine, Space, Training, Event, NilClass>]
    # @return [Hash{Symbol=>ActiveRecord::Relation<CartItem::ReservationSlot>,Array<Integer>}]
    def pending_reservations(cart_item_reservation_slot_ids, reservables)
      reservable_types = reservables.map(&:class).map(&:name).uniq
      if reservable_types.size > 1
        raise TypeError("[Slots::StatusService#pending_reservations] reservables have differents types: #{reservable_types}")
      end

      relation = "cart_item_#{reservable_types.first&.downcase}_reservation".to_sym
      pending_reservations = case reservable_types.first
                             when 'Event'
                               CartItem::ReservationSlot.where(id: cart_item_reservation_slot_ids)
                                                        .includes(relation)
                                                        .where(cart_item_event_reservations: { event_id: reservables.map(&:id) })
                             when 'NilClass'
                               []
                             else
                               CartItem::ReservationSlot.where(id: cart_item_reservation_slot_ids)
                                                        .includes(relation)
                                                        .where(cart_item_reservations: { reservable_type: reservable_types })
                                                        .where(cart_item_reservations: { reservable_id: reservables.map { |r| r.try(:id) } })
                             end

      user_ids = if reservable_types.first == 'NilClass'
                   []
                 else
                   pending_reservations.includes(relation => :customer_profile)
                                       .map(&:cart_item)
                                       .map(&:customer_profile)
                                       .map(&:user_id)
                                       .filter { |id| !id.nil? }
                 end

      {
        reservations: pending_reservations,
        user_ids: user_ids
      }
    end

    # @param slot [Slot]
    # @param user [User]
    # @param reservable [Machine,Space,Training,Event']
    # @return [Hash{Symbol=>ActiveRecord::Relation<SlotsReservation>,ActiveRecord::Relation<CartItem::ReservationSlot>,Array}]
    def user_reservations(slot, user, reservable)
      return { reservations: [], pending: [] } if user.nil? || !slot.reserved_by?(user.id, [reservable])

      reservable_type = reservable&.class&.name
      reservable_id = reservable&.id

      reservations = SlotsReservation.includes(:reservation)
                                     .where(slot_id: slot.id, reservations: {
                                              statistic_profile_id: user.statistic_profile.id,
                                              reservable_type: reservable_type,
                                              reservable_id: reservable_id
                                            })
      relation = "cart_item_#{reservable_type&.downcase}_reservation".to_sym
      table = (reservable_type == 'Event' ? 'cart_item_event_reservations' : 'cart_item_reservations').to_sym
      id_key = (reservable_type == 'Event' ? 'event_id' : 'reservable_id').to_sym
      type_key = (reservable_type == 'Event' ? {} : { reservable_type: reservable_type })
      pending = CartItem::ReservationSlot.includes(relation)
                                         .where(slot_id: slot.id, table => {
                                           customer_profile_id: user.invoicing_profile.id,
                                           id_key => reservable_id
                                         }.merge!(type_key))

      {
        reservations: reservations,
        pending: pending
      }
    end
  end
end
