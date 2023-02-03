# frozen_string_literal: true

# NotificationType defines the different types of Notification.
# When recording a new notification type in db, you might also want to add it in:
# test/fixtures/notification_types.yml
# app/frontend/src/javascript/models/notification-type.ts
# config/locales/app.logged.en.yml
# If you change the name of a category, or create a new one, please add it in:
# app/frontend/src/javascript/models/notification-preference.ts
class NotificationType < ApplicationRecord
  has_many :notifications, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy

  validates :name, uniqueness: true, presence: true
  validates :category, presence: true
  validates :is_configurable, inclusion: { in: [true, false] }
end
