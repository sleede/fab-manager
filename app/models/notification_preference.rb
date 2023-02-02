# frozen_string_literal: true

# Allow user to set their preferences for notifications (push and email)
class NotificationPreference < ApplicationRecord
  belongs_to :user
  belongs_to :notification_type

  validates :notification_type_id, uniqueness: { scope: :user }

  def notification_type
    NotificationType.find(notification_type_id).name
  end
end
