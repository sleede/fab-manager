# frozen_string_literal: true

# Notification is an in-system alert that is shown to a specific user until it is marked as read.
class Notification < ApplicationRecord
  belongs_to :notification_type
  belongs_to :receiver, polymorphic: true
  belongs_to :attached_object, polymorphic: true

  # This scope filter a user's in system (push) notifications :
  # It fetch his notifications where no notification preference is made,
  # or if this preference specify that the user accepts in system notification
  scope :delivered_in_system, lambda { |user|
    joins(:notification_type)
      .joins(%(LEFT OUTER JOIN "notification_preferences" ON
                               "notification_preferences"."notification_type_id" = "notification_types"."id"
                               AND "notification_preferences"."user_id" = #{user.id}).squish)
      .where(<<-SQL.squish, user.id)
      notification_preferences.in_system IS TRUE OR notification_preferences.id IS NULL
      SQL
  }

  scope :with_valid_notification_type, -> { joins(:notification_type).where(notification_types: { name: NOTIFICATIONS_TYPES.map { |nt| nt[:name] } }) }

  validates :receiver_id,
            :receiver_type,
            :attached_object_id,
            :attached_object_type,
            :notification_type_id,
            presence: true

  def notification_type
    NotificationType.find(notification_type_id).name
  end

  def mark_as_read
    update(is_read: true)
  end

  def mark_as_send
    update(is_send: true)
  end

  def deliver_now
    NotificationsMailer.send_mail_by(self).deliver_now if save
  end

  def deliver_later
    NotificationsMailer.send_mail_by(self).deliver_later if save
  end

  def deliver_with_preferences(user, notification_type)
    preference = NotificationPreference.find_by(notification_type: notification_type, user: user)

    # Set as read if user do not want push notifications
    self.is_read = true if preference && preference.in_system == false

    # Save notification if user do not want email notifications ; else, deliver.
    preference && preference.email == false ? save : deliver_later
  end

  def get_meta_data(key)
    meta_data.try(:[], key.to_s)
  end
end
