# frozen_string_literal: true

# NotificationType defines the different types of Notification.
class NotificationType < ApplicationRecord
  has_many :notifications, dependent: :destroy
  validates :name, uniqueness: true, presence: true
end
