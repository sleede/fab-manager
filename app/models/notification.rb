# frozen_string_literal: true

# Notification is an in-system alert that is shown to a specific user until it is marked as read.
class Notification < ApplicationRecord
  belongs_to :notification_type
  belongs_to :receiver, polymorphic: true
  belongs_to :attached_object, polymorphic: true

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

  def get_meta_data(key)
    meta_data.try(:[], key.to_s)
  end
end
