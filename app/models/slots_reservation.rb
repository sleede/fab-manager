# frozen_string_literal: true

# SlotsReservation is the relation table between a Slot and a Reservation.
# It holds detailed data about a Reservation for the attached Slot.
class SlotsReservation < ApplicationRecord
  belongs_to :slot
  belongs_to :reservation
  has_one :cart_item_reservation_slot, class_name: 'CartItem::ReservationSlot', dependent: :nullify

  after_update :set_ex_start_end_dates_attrs, if: :slot_changed?
  after_update :notify_member_and_admin_slot_is_modified, if: :slot_changed?

  after_update :notify_member_and_admin_slot_is_canceled, if: :canceled?
  after_update :update_event_nb_free_places, if: :canceled?

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
