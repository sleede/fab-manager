# frozen_string_literal: true

# We migrate existing notifications to be attached to a SlotsReservation instead of a Slot,
# because these notifications are now expecting a SlotsReservation
class MigrateSlotsNotifications < ActiveRecord::Migration[5.2]
  def up
    Notification.where(attached_object_type: 'Slot').each do |notification|
      slot = notification.attached_object
      slots_reservation = slot&.slots_reservations
                              &.includes(:reservation)
                              &.where('reservations.statistic_profile_id': notification.receiver.statistic_profile.id)
                              &.first
      notification.update(attached_object: slots_reservation)
    end
  end

  def down
    Notification.where(attached_object_type: 'SlotsReservation').each do |notification|
      notification.update(attached_object: notification.attached_object&.slot)
    end
  end
end
