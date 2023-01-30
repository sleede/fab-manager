# frozen_string_literal: true

# NotificationType defines the different types of Notification.
class NotificationType < ApplicationRecord
  has_many :notifications, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy

  validates :name, uniqueness: true, presence: true
  validates :category, presence: true
  validates :is_configurable, inclusion: { in: [true, false] }
end
