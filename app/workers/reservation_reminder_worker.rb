# frozen_string_literal: true

# Send a reminder email to the user who has made a reservation
class ReservationReminderWorker
  include Sidekiq::Worker

  ## In case the reminder is enabled but no delay were configured, we use this default value
  DEFAULT_REMINDER_DELAY = 24.hours

  def perform
    return unless Setting.get('reminder_enable')

    delay = Setting.find_by(name: 'reminder_delay').try(:value).try(:to_i).try(:hours) || DEFAULT_REMINDER_DELAY

    starting = Time.current.beginning_of_hour + delay
    ending = starting + 1.hour

    Reservation.joins(slots_reservations: :slot)
               .where('slots.start_at >= ? AND slots.start_at <= ? AND slots_reservations.canceled_at IS NULL', starting, ending)
               .each do |r|
      already_sent = Notification.where(
        attached_object_type: Reservation.name,
        attached_object_id: r.id,
        notification_type_id: NotificationType.find_by_name('notify_member_reservation_reminder')
      ).count
      next if already_sent.positive?

      NotificationCenter.call type: 'notify_member_reservation_reminder',
                              receiver: r.user,
                              attached_object: r
    end
  end
end
