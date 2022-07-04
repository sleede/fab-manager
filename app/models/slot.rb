# frozen_string_literal: true

# A Time range.
# Slots have two functions:
# - slicing an Availability
#   > Slots duration are defined globally by Setting.get('slot_duration') but can be overridden per availability.
#   > These slots are not persisted in database and instantiated on the fly, if needed.
# - hold detailed data about a Reservation.
#   > Persisted slots (in DB) represents booked slots and stores data about a time range that have been reserved.
class Slot < ApplicationRecord
  include NotifyWith::NotificationAttachedObject

  has_many :slots_reservations, dependent: :destroy
  has_many :reservations, through: :slots_reservations
  belongs_to :availability

  attr_accessor :is_reserved, :machine, :space, :title, :can_modify, :is_reserved_by_current_user

  after_update :set_ex_start_end_dates_attrs, if: :dates_were_modified?
  after_update :notify_member_and_admin_slot_is_modified, if: :dates_were_modified?

  after_update :notify_member_and_admin_slot_is_canceled, if: :canceled?
  after_update :update_event_nb_free_places, if: :canceled?

  # for backward compatibility
  def reservation
    reservations.first
  end

  def destroy
    update_column(:destroying, true)
    super
  end

  def complete?
    reservations.length >= availability.nb_total_places
  end

  private

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

  def dates_were_modified?
    saved_change_to_start_at? || saved_change_to_end_at?
  end

  def canceled?
    saved_change_to_canceled_at?
  end

  def set_ex_start_end_dates_attrs
    update_columns(ex_start_at: start_at_before_last_save, ex_end_at: end_at_before_last_save)
  end

  def update_event_nb_free_places
    return unless reservation.reservable_type == 'Event'
    raise NotImplementedError if reservations.count > 1

    reservation.update_event_nb_free_places
  end
end
