# frozen_string_literal: true

# SlotsReservation is the relation table between a Slot and a Reservation.
# It holds detailed data about a Reservation for the attached Slot.
class SlotsReservation < ApplicationRecord
  belongs_to :slot
  belongs_to :reservation
  has_one :cart_item_reservation_slot, class_name: 'CartItem::ReservationSlot', dependent: :nullify

  after_create :add_to_places_cache
  after_update :set_ex_start_end_dates_attrs, if: :slot_changed?
  after_update :notify_member_and_admin_slot_is_modified, if: :slot_changed?
  after_update :switch_places_cache, if: :slot_changed?

  after_update :notify_member_and_admin_slot_is_canceled, if: :canceled?
  after_update :update_event_nb_free_places, if: :canceled?
  after_update :remove_from_places_cache, if: :canceled?

  before_destroy :remove_from_places_cache

  def set_ex_start_end_dates_attrs
    update_columns(ex_start_at: previous_slot.start_at, ex_end_at: previous_slot.end_at) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def slot_changed?
    saved_change_to_slot_id?
  end

  def previous_slot
    Slot.find(slot_id_before_last_save)
  end

  def canceled?
    saved_change_to_canceled_at?
  end

  def update_event_nb_free_places
    return unless reservation.reservable_type == 'Event'

    reservation.update_event_nb_free_places
  end

  def switch_places_cache
    old_slot_id = saved_change_to_slot_id[0]
    remove_from_places_cache(Slot.find(old_slot_id))
    add_to_places_cache
  end

  def add_to_places_cache
    update_places_cache(:+)
    Slots::PlacesCacheService.add_users(slot, reservation.reservable_type, reservation.reservable_id, [reservation.statistic_profile.user_id])
  end

  # @param target_slot [Slot]
  def remove_from_places_cache(target_slot = slot)
    update_places_cache(:-, target_slot)
    Slots::PlacesCacheService.remove_users(target_slot,
                                           reservation.reservable_type,
                                           reservation.reservable_id,
                                           [reservation.statistic_profile.user_id])
  end

  # @param operation [Symbol] :+ or :-
  # @param target_slot [Slot]
  def update_places_cache(operation, target_slot = slot)
    if reservation.reservable_type == 'Event'
      total_booked_seats = reservation.nb_reserve_places
      total_booked_seats += reservation.tickets.map(&:booked).map(&:to_i).reduce(:+) if reservation.tickets.count.positive?
      total_booked_seats = 0 if reservation.reservable.pre_registration
      Slots::PlacesCacheService.change_places(target_slot,
                                              reservation.reservable_type,
                                              reservation.reservable_id,
                                              total_booked_seats,
                                              operation)
    else
      Slots::PlacesCacheService.change_places(target_slot, reservation.reservable_type, reservation.reservable_id, 1, operation)
    end
  end

  def notify_member_and_admin_slot_is_modified
    NotificationCenter.call type: 'notify_member_slot_is_modified',
                            receiver: reservation.user,
                            attached_object: self
    NotificationCenter.call type: 'notify_admin_slot_is_modified',
                            receiver: User.admins_and_managers,
                            attached_object: self
  end

  def notify_member_and_admin_slot_is_canceled
    NotificationCenter.call type: 'notify_member_slot_is_canceled',
                            receiver: reservation.user,
                            attached_object: self
    NotificationCenter.call type: 'notify_admin_slot_is_canceled',
                            receiver: User.admins_and_managers,
                            attached_object: self
  end
end
